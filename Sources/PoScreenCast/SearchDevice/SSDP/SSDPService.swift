//
//  SSDPService.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import Foundation

public struct SSDPSearchService {
    public let cacheControl: String?
    public let location: String?
    public let server: String?
    public let st: String? // searchTarget
    public let usn: String? // uniqueServiceName
    
    init(_ dictionary: [String: String]) {
        cacheControl = dictionary["CACHE-CONTROL"]
        location = dictionary["LOCATION"]
        server = dictionary["SERVER"]
        st = dictionary["ST"]
        usn = dictionary["USN"]
    }
}

public struct SSDPNotifyService {
    
    public enum NTS: String {
        /// 加入网络
        case alive = "ssdp:alive"
        /// 更新
//        case update = "ssdp:update"
        /// 退出网络
        case byebye = "ssdp:byebye"
    }
    
    public let host: String?
    public let cacheControl: String?
    public let location: String?
    public let server: String?
    public let nt: String? // equal searchTarget
    public let nts: NTS?
    public let usn: String? // uniqueServiceName
    
    init(_ dictionary: [String: String]) {
        host = dictionary["HOST"]
        cacheControl = dictionary["CACHE-CONTROL"]
        location = dictionary["LOCATION"]
        server = dictionary["SERVER"]
        nt = dictionary["NT"]
        if let ntsRawValue = dictionary["NTS"] {
            nts = NTS(rawValue: ntsRawValue)
        } else {
            nts = nil
        }
        usn = dictionary["USN"]
    }
}
