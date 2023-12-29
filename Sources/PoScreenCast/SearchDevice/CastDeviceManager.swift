//
//  CastDeviceManager.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import Foundation

public protocol CastDeviceManagerDelegate: AnyObject {
    func deviceManager(_ manager: CastDeviceManager, searchedDeviceListChange deviceList: [CastDevice])
    func deviceManager(_ manager: CastDeviceManager, searchErrorOccured error: CastError.SearchDeviceError)
}

extension CastDeviceManager {
    struct MutableState {
        /// udn: device
        var deviceMap = [String: CastDevice]()
        /// location: count/
        var requestedLocationCount = [String: Int]()
        /// location
        var requestingLocations = Set<String>()
        
        mutating func reset() {
            deviceMap = [:]
            requestedLocationCount = [:]
            requestingLocations = []
        }
    }

}

public final class CastDeviceManager {
    public weak var delegate: (any CastDeviceManagerDelegate)?
    public var deviceList: [CastDevice] {
        return mutableState.read({ $0.deviceMap.map({ $1 }) })
    }
    private var mutableState = Protected(MutableState())
    private let ssdpSession = SSDPSession()

    private var timer: Timer?
    private var searchedTimes = 0
    
    public static let shared = CastDeviceManager()
    
    private init() {
        ssdpSession.delegate = self
    }
    
    /// 开始搜索
    public func startSearch(searchTargets: [SSDPSearchTarget] = [.root],
                            searchTimes: Int = Constant.searchTimes,
                            searchInterval: TimeInterval = Constant.searchInterval) {
        self.searchedTimes = searchTimes - 1
        search(searchTargets)
        if searchTimes > 1 {
            timer = Timer.scheduledTimer(withTimeInterval: searchInterval, repeats: true, block: { [weak self] timer in
                guard let self else { return }
                self.search(searchTargets)
                self.searchedTimes -= 1
                if searchedTimes <= 0 {
                    timer.invalidate()
                    self.timer = nil
                }
            })
            RunLoop.current.add(timer!, forMode: .default)
        }
    }
    
    /// 停止搜索
    public func stopSearch() {
        ssdpSession.stop()
        timer?.invalidate()
        timer = nil
        mutableState.write( { $0.reset() })
    }
    
    private func search(_ searchTargets: [SSDPSearchTarget]) {
        for searchTarget in searchTargets {
            let config = SSDPSession.SearchConfiguration(searchTarget: searchTarget, maximumWaitResponseTime: 1, userAgent: Constant.userAgent)
            ssdpSession.search(with: config)
        }
    }
}

extension CastDeviceManager: SSDPSessionDelegate {
    
    public func ssdpSession(_ session: SSDPSession, didSearchService searchService: SSDPSearchService) {
        fetchDeviceInfo(with: searchService.usn, location: searchService.location)
    }
    
    public func ssdpSession(_ session: SSDPSession, didReceiveNotifyService notifyService: SSDPNotifyService) {
        guard let nts = notifyService.nts else { return }
        switch nts {
        case .alive:
            fetchDeviceInfo(with: notifyService.usn, location: notifyService.location)
        case .byebye:
            if let usn = notifyService.usn?.toUDN {
                mutableState.write({ $0.deviceMap.removeValue(forKey: usn) })
            }
        }
    }
    
    public func ssdpSession(_ session: SSDPSession, errorOccured error: CastError.SearchDeviceError) {
        DispatchQueue.main.async {
            self.delegate?.deviceManager(self, searchErrorOccured: error)
        }
    }
    
}

extension CastDeviceManager {
    
    fileprivate func fetchDeviceInfo(with usn: String?, location: String?) {
        guard let usn, let location, let url = URL(string: location) else { return }
        let udn = usn.toUDN
        
        var shouldReturn = false
        mutableState.write { state in
            let containsDevice = state.deviceMap.contains(where: { $0.key == udn })
            if containsDevice {
                shouldReturn = true
                return
            }
            
            let containsLocation = state.requestingLocations.contains(location)
            if containsLocation {
                shouldReturn = true
                return
            }
            let count = state.requestedLocationCount[location, default: 0]
            if count >= 2 {
                shouldReturn = true
                return
            } else {
                state.requestedLocationCount[location] = count + 1
            }
        }

        if shouldReturn { return }
        mutableState.write { state in
            state.requestingLocations.insert(location)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            mutableState.write { state in
                state.requestingLocations.remove(location)
            }
            if let error {
                PoCastLog("fetchDeviceInfo error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode != 200) {
                    PoCastLog("fetchDeviceInfo errorCode: \(httpResponse.statusCode)")
                } else if let data {
                    do {
                        let res = try CastDeviceParser.parse(data)
                        let device = CastDevice(usn: usn, location: url, dictionary: res)
                        if device.avTransport != nil {
                            PoCastLog("搜到设备:\(device.friendlyName ?? ""), location: \(device.location.absoluteString)")
                            self.mutableState.write { state in
                                state.deviceMap[udn] = device
                            }
                            DispatchQueue.main.async {
                                self.delegate?.deviceManager(self, searchedDeviceListChange: self.deviceList)
                            }
                        }
                    } catch {
                        PoCastLog("CastDeviceParser error: \(error.localizedDescription)")
                    }
                    
                }
            }
        }
        task.resume()
    }
    
}

extension String {
    
    fileprivate var toUDN: String {
        let components = self.components(separatedBy: "::")
        if let udn = components.first {
            return udn
        } else {
            return self
        }
    }
    
}
