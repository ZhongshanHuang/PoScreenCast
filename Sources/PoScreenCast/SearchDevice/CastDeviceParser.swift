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
        guard let element = xmlDoc.root.po_firstChild(localName: "device") else {
            throw CastError.ParserError.parseFailed("CastDeviceParser can't find device node")
        }
        
        var res = [String: Any]()
        if let urlBase = xmlDoc.root.po_firstChild(localName: "URLBase")?.value {
            res["URLBase"] = urlBase
        }
        for child in element.children {
            if child.po_localName == "serviceList" {
                for serviceEle in child.po_children(localName: "service") {
                    guard let serviceTypeEle = serviceEle.po_firstChild(localName: "serviceType") else { continue }
                    if serviceTypeEle.value == SSDPSearchTarget.avTransport.rawValue {
                        var AVTransportDic = [String: String]()
                        serviceEle.children.forEach({ AVTransportDic[$0.po_localName] = $0.value })
                        if !AVTransportDic.isEmpty {
                            res["avTransport"] = AVTransportDic
                        }
                    } else if serviceTypeEle.value == SSDPSearchTarget.renderingControl.rawValue {
                        var renderingControlDic = [String: String]()
                        serviceEle.children.forEach({ renderingControlDic[$0.po_localName] = $0.value })
                        if !renderingControlDic.isEmpty {
                            res["renderingControl"] = renderingControlDic
                        }
                    }
                }
            } else {
                res[child.po_localName] = child.value
            }
        }
        return res
    }
    
}
