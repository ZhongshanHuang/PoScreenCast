//
//  SSDPSession.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import Foundation
import CocoaAsyncSocket

public protocol SSDPSessionDelegate: AnyObject {
    func ssdpSession(_ session: SSDPSession, didSearchService searchService: SSDPSearchService)
    func ssdpSession(_ session: SSDPSession, didReceiveNotifyService notifyService: SSDPNotifyService)
    func ssdpSession(_ session: SSDPSession, errorOccured error: CastError.SearchDeviceError)
}

extension SSDPSession {
    public struct SearchConfiguration {
        public let searchTarget: SSDPSearchTarget
        public let maximumWaitResponseTime: TimeInterval // [1, 5]
        public let userAgent: String
    }
}

public final class SSDPSession: NSObject {
    public weak var delegate: (any SSDPSessionDelegate)?
    private var searchSocket: GCDAsyncUdpSocket!
    private var notifySocket: GCDAsyncUdpSocket!
    private lazy var socketQueue: DispatchQueue = DispatchQueue(label: "PoScreenCastSocketQueue", autoreleaseFrequency: .workItem)
    
    deinit {
        searchSocket?.close()
        notifySocket?.close()
    }
        
    public func search(with config: SSDPSession.SearchConfiguration) {
        if (searchSocket == nil) {
            searchSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: socketQueue)
            do {
                try searchSocket.bind(toPort: 0)
                try searchSocket.beginReceiving()
            } catch {
                delegate?.ssdpSession(self, errorOccured: .socketBindFailed(error.localizedDescription))
            }
            
            notifySocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: socketQueue)
            do {
                try notifySocket.bind(toPort: SSDPConstant.port)
                try notifySocket.joinMulticastGroup(SSDPConstant.host)
                try notifySocket.beginReceiving()
            } catch {
                delegate?.ssdpSession(self, errorOccured: .socketBindFailed(error.localizedDescription))
            }
        }
        
        let content = "M-SEARCH * HTTP/1.1\r\n" +
        "MAN: \"ssdp:discover\"\r\n" +
        "ST: \(config.searchTarget.rawValue)\r\n" +
        "MX: \(Int(config.maximumWaitResponseTime))\r\n" +
        "User-Agent: \(config.userAgent)\r\n" +
        "Connection: close\r\n" +
        "Host: \(SSDPConstant.host):\(SSDPConstant.port)\r\n" +
        "\r\n"
        
        searchSocket.send(content.data(using: .utf8)!, toHost: SSDPConstant.host, port: SSDPConstant.port, withTimeout: -1, tag: 1)
    }
    
    public func stop() {
        searchSocket?.close()
        searchSocket = nil
        
        notifySocket?.close()
        notifySocket = nil
    }
}

extension SSDPSession: GCDAsyncUdpSocketDelegate {
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        if let error {
            delegate?.ssdpSession(self, errorOccured: .socketConnectFailed(error.localizedDescription))
        }
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        PoCastLog("socket connect to: \(String(data: address, encoding: .utf8) ?? "")")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        PoCastLog("socket send data success")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        if let error {
            delegate?.ssdpSession(self, errorOccured: .socketSendFailed(error.localizedDescription))
        }
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        if let error {
            delegate?.ssdpSession(self, errorOccured: .socketCloseFailed(error.localizedDescription))
        } else {
            PoCastLog("socket close")
        }
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        if let res = SSDPServiceParser.parse(data) {
            switch res.type {
            case .search:
                delegate?.ssdpSession(self, didSearchService: SSDPSearchService(res.elements))
            case .notify:
                delegate?.ssdpSession(self, didReceiveNotifyService: SSDPNotifyService(res.elements))
            }
        }
    }
}
