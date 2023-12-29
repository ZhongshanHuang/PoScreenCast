//
//  CastRemoteControl.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/15.
//

import Foundation

public protocol CastRemoteControlDelegate: AnyObject {
    func remoteControl(_ remoteControl: CastRemoteControl, sendAction action: CastAction, response: CastActionResponse)
}

public final class CastRemoteControl {
    public weak var delegate: (any CastRemoteControlDelegate)?
    public let device: CastDevice
    
    private var timer: Timer?
    private var timerInterval: UInt = 0
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    public init(_ device: CastDevice) {
        self.device = device
    }
    
    /// 设置播放媒体资源，设置成功后默认调用play播放
    public func setAVTransportURI(_ uri: String, videoName: String) {
        send(CastAction(type: .setAVTransportURI(uri: uri, videoName: videoName)))
    }
    
    /// 播放
    public func play() {
        send(CastAction(type: .play))
    }
    
    /// 暂停
    public func pause() {
        send(CastAction(type: .pause))
    }
    
    // 退出投屏
    public func stop() {
        send(CastAction(type: .stop))
        stopAsyncMediaInfo()
    }
    
    /// seek
    public func seek(_ position: Double) {
        send(CastAction(type: .seek(position: position)))
    }
    
    /// 设置音量
    public func setVolume(_ volume: Int) {
        send(CastAction(type: .setVolume(volume: volume)))
    }
    
    /// 获取音量
    public func getVolume() {
        send(CastAction(type: .getVolume))
    }
    
    /// 获取播放进度
    public func getPositionInfo() {
        send(CastAction(type: .getPositionInfo))
    }
    
    /// 获取播放状态
    public func getTransportInfo() {
        send(CastAction(type: .getTransportInfo))
    }
    
    /// 同步播放信息，这儿
    public func startAsyncMediaInfo(positionInfoInterval: UInt = 1,
                                    transportInfoInterval: UInt = 2,
                                    volumeInterval: UInt = 5) {
        if timer != nil {
            timer?.invalidate()
        }
        timerInterval = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.timerInterval += 1
            if timerInterval % positionInfoInterval == 0 {
                self.getPositionInfo()
            }
            if timerInterval % transportInfoInterval == 0 {
                self.getTransportInfo()
            }
            if timerInterval % volumeInterval == 0 {
                self.getVolume()
            }
        })
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    public func stopAsyncMediaInfo() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Help
    
    private func send(_ action: CastAction) {
        guard let urlStr = device.controlURL(for: action.serviceType), let url = URL(string: urlStr) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 5
        request.addValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.addValue(action.SOAP, forHTTPHeaderField: "SOAPAction")
        request.httpBody = action.xmlString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            let actionResponse: CastActionResponse
            if let error {
                actionResponse = CastActionResponse(action: action, rawData: data, failure: .failedBeforeSend(error.localizedDescription))
            } else {
                let httpResponse = response as! HTTPURLResponse
                if (httpResponse.statusCode == 200) {
                    actionResponse = CastActionResponse(action: action, rawData: data, failure: nil)
                } else if let data, let serverFault = try? CastRemoteControlParser.parseServerFault(data) {
                    actionResponse = CastActionResponse(action: action, rawData: data, failure: .serverFault(serverFault))
                } else {
                    actionResponse = CastActionResponse(action: action, rawData: data, failure: .failedBeforeSend("statusCode: \(httpResponse.statusCode), msg: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))"))
                }
            }
            DispatchQueue.main.async {
                self.delegate?.remoteControl(self, sendAction: action, response: actionResponse)
            }
        }
        task.resume()
    }
    
}
