//
//  CastDeviceParser.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/13.
//

import Foundation
import AEXML

struct CastDeviceParser {
    
    static func parse(_ data: Data) throws -> [String: Any] {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let element = xmlDoc.root.children.first(where: { $0.name == "device" }) else {
            throw CastError.ParserError.parseFailed("CastDeviceParser can't find device node")
        }
        
        var res = [String: Any]()
        for child in element.children {
            if child.name == "serviceList" {
                for serviceEle in child.children where serviceEle.name == "service" {
                    guard let serviceTypeEle = serviceEle.children.first(where: { $0.name == "serviceType" }) else { continue }
                    if serviceTypeEle.value == SSDPSearchTarget.avTransport.rawValue {
                        var AVTransportDic = [String: String]()
                        serviceEle.children.forEach({ AVTransportDic[$0.name] = $0.value })
                        if !AVTransportDic.isEmpty {
                            res["avTransport"] = AVTransportDic
                        }
                    } else if serviceTypeEle.value == SSDPSearchTarget.renderingControl.rawValue {
                        var renderingControlDic = [String: String]()
                        serviceEle.children.forEach({ renderingControlDic[$0.name] = $0.value })
                        if !renderingControlDic.isEmpty {
                            res["renderingControl"] = renderingControlDic
                        }
                    }
                }
            } else {
                res[child.name] = child.value
            }
        }
        return res
    }
    
}
