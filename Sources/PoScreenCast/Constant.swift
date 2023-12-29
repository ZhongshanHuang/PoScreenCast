//
//  Constant.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/8.
//

import UIKit

func PoCastLog(_ content: String) {
    #if DEBUG
    print(content)
    #endif
}

public enum Constant {
    public static let version = "1.0.0"
    public static let userAgent = "\(UIDevice.current.systemName)/\(UIDevice.current.systemVersion) UPnP/1.1 PoScreenCast/\(Constant.version)"
    
    // 搜索次数
    public static let searchTimes = 2
    // 搜索间隔
    public static let searchInterval: TimeInterval = 2
}
