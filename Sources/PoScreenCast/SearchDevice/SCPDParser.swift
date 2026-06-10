//
//  SCPDParser.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/14.
//

import Foundation
import AEXML

struct SCPDParser {
    
    static func parse(_ data: Data) throws -> [String: String] {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let element = xmlDoc.root.po_firstChild(localName: "serviceStateTable") else {
            throw CastError.ParserError.parseFailed("SCPDParser can't find serviceStateTable node")
        }
        
        for variableElem in element.children {
            if variableElem.children.contains(where: { $0.po_localName == "name" && $0.value == "Volume" }) {
                if let allowedValueRangeElem = variableElem.po_firstChild(localName: "allowedValueRange") {
                    var res = [String: String]()
                    allowedValueRangeElem.children.forEach({ res[$0.po_localName] = $0.value })
                    return res
                } else {
                    throw CastError.ParserError.parseFailed("SCPDParser can't find allowedValueRange node")
                }
            }
        }
        throw CastError.ParserError.parseFailed("SCPDParser can't find volume node")
    }
    
}
