//
//  SSDPServiceParser.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/13.
//

import Foundation

struct SSDPServiceParser {
    
    enum ServiceType {
        case search
        case notify
    }
    
    struct Result {
        let type: ServiceType
        let elements: [String: String]
    }
    
    static func parse(_ data: Data) -> SSDPServiceParser.Result? {
        guard let content = String(data: data, encoding: .utf8) else { return nil }
        
        PoCastLog("socket 收到数据: \(content)")
        let type: ServiceType
        if content.hasPrefix("HTTP") {
            type = .search
        } else if content.hasPrefix("NOTIFY") {
            type = .notify
        } else {
            return nil
        }
        
        var elements = [String: String]()
        for element in content.split(separator: "\r\n") {
            let keyValuepair = element.split(separator: ":", maxSplits: 1)
            guard keyValuepair.count == 2 else { continue }
            
            let key = String(keyValuepair[0]).trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let value = String(keyValuepair[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            elements[key] = value
        }
        return SSDPServiceParser.Result(type: type, elements: elements)
    }
    
}
