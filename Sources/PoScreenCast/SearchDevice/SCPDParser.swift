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
        guard let element = xmlDoc.root.children.first(where: { $0.name == "serviceStateTable" }) else {
            throw CastError.ParserError.parseFailed("SCPDParser can't find serviceStateTable node")
        }
        
        for variableElem in element.children {
            if variableElem.children.contains(where: { $0.name == "name" || $0.value == "Volume" }) {
                if let allowedValueRangeElem = variableElem.children.first(where: { $0.name == "allowedValueRange" }) {
                    var res = [String: String]()
                    allowedValueRangeElem.children.forEach({ res[$0.name] = $0.value })
                    return res
                } else {
                    throw CastError.ParserError.parseFailed("SCPDParser can't find allowedValueRange node")
                }
            }
        }
        throw CastError.ParserError.parseFailed("SCPDParser can't find volume node")
    }
    
}
