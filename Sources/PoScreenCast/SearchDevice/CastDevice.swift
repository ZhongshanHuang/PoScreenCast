//
//  CastDevice.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import Foundation

extension CastDevice {
    
    public struct Service {
        public let serviceType: String?
        public let serviceId: String?
        public let controlURL: String?
        public let eventSubURL: String?
        public let SCPDURL: String?
        
        init(_ dictionary: [String: String]) {
            self.serviceType = dictionary["serviceType"]
            self.serviceId = dictionary["serviceId"]
            self.controlURL = dictionary["controlURL"]
            self.eventSubURL = dictionary["eventSubURL"]
            self.SCPDURL = dictionary["SCPDURL"]
        }
    }
    
    public struct AllowedValueRange {
        public let minimum: Int?
        public let maximum: Int?
        public let step: Int?
        
        init(_ dictionary: [String: String]) {
            if let minimumValue = dictionary["minimum"] {
                self.minimum = Int(minimumValue)
            } else {
                self.minimum = nil
            }
            if let maximumValue = dictionary["maximum"] {
                self.maximum = Int(maximumValue)
            } else {
                self.maximum = nil
            }
            if let stepValue = dictionary["step"] {
                self.step = Int(stepValue)
            } else {
                self.step = nil
            }
        }
    }
}

public final class CastDevice {
    public let usn: String
    public let udn: String
    public let location: URL
    
    public let friendlyName: String?
    public let modelName: String?
    public let deviceType: String?
    
    public let avTransport: CastDevice.Service?
    public let renderingControl: CastDevice.Service?
    public private(set) var volumeRange: CastDevice.AllowedValueRange?
    
    public init(usn: String, location: URL, dictionary: [String: Any]) {
        self.usn = usn
        self.location = location
        self.udn = (dictionary["UDN"] as? String) ?? ""
        self.friendlyName = dictionary["friendlyName"] as? String
        self.modelName = dictionary["modelName"] as? String
        self.deviceType = dictionary["deviceType"] as? String
        if let avTransport = dictionary["avTransport"] as? [String: String] {
            self.avTransport = CastDevice.Service(avTransport)
        } else {
            self.avTransport = nil
        }
        if let renderingControl = dictionary["renderingControl"] as? [String: String] {
            self.renderingControl = CastDevice.Service(renderingControl)
            if let scpd = self.renderingControl?.SCPDURL, !scpd.isEmpty {
                self .fetchSCPD(scpd)
            }
        } else {
            self.renderingControl = nil
        }
    }
    
    public func controlURL(for service: CastAction.CastServiceType) -> String? {
        guard let scheme = self.location.scheme,
                let host = self.location.host,
                let port = self.location.port else { return nil }
        var urlStr = "\(scheme)://\(host):\(port)"
        let path: String
        switch service {
        case .avTransport:
            guard let controlURL = avTransport?.controlURL else { return nil }
            path = controlURL
        case .renderingControl:
            guard let controlURL = renderingControl?.controlURL else { return nil }
            path = controlURL
        }
        urlStr += path.hasPrefix("/") ? path : "/\(path)"
        return urlStr
    }
    
    private func fetchSCPD(_ path: String) {
        guard let scheme = self.location.scheme,
                let host = self.location.host,
                let port = self.location.port else { return }
        var urlStr = "\(scheme)://\(host):\(port)"
        urlStr += path.hasPrefix("/") ? path : "/\(path)"
        guard let url = URL(string: urlStr) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            
            if let error {
                PoCastLog("fetchSCPD error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode != 200) {
                    PoCastLog("fetchSCPD errorCode: \(httpResponse.statusCode)")
                } else if let data {
                    do {
                        let res = try SCPDParser.parse(data)
                        DispatchQueue.main.async {
                            self.volumeRange = CastDevice.AllowedValueRange(res)
                        }
                    } catch {
                        PoCastLog("SCPDParser error: \(error.localizedDescription)")
                    }
                }
            }
        }
        task.resume()
    }
    
}
