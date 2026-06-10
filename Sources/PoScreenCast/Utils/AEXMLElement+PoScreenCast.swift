//
//  AEXMLElement+PoScreenCast.swift
//  PoScreenCastDemo
//
//  Created by Codex on 2026/6/10.
//

import AEXML
import Foundation

extension AEXMLElement {
    var po_localName: String {
        guard let separatorIndex = name.lastIndex(of: ":") else {
            return name
        }
        return String(name[name.index(after: separatorIndex)...])
    }

    func po_firstChild(localName: String) -> AEXMLElement? {
        children.first { $0.po_localName == localName }
    }

    func po_children(localName: String) -> [AEXMLElement] {
        children.filter { $0.po_localName == localName }
    }
}
