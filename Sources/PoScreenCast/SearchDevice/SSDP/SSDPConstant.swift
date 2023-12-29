//
//  SSDPConstant.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import Foundation

public enum SSDPConstant {
    public static let host = "239.255.255.250"
    public static let port: UInt16 = 1900
}

public enum SSDPSearchTarget: String {
    // 搜索所有类型的设备和服务
    case all = "ssdp:all"
    // 搜索根设备
    case root = "upnp:rootdevice"
    // 搜索具有媒体渲染能力的设备
    case mediaRender = "urn:schemas-upnp-org:device:MediaRenderer:1"
    // 搜索具有AVTransport能力的服务
    case avTransport = "urn:schemas-upnp-org:service:AVTransport:1"
    case renderingControl = "urn:schemas-upnp-org:service:RenderingControl:1"
}

public enum SSDPServiceIdType: String {
    case avTransport = "urn:upnp-org:serviceId:AVTransport"
    case renderingControl = "urn:upnp-org:serviceId:RenderingControl"
}
