//
//  CastRemoteControlParser.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/17.
//

import Foundation
import AEXML

struct CastRemoteControlParser {
    
    static func parseVolume(_ data: Data) throws -> CastActionResponse.Volume {
        let body = try soapBody(from: data, parserName: "Volume")
        guard let response = body.po_firstChild(localName: "GetVolumeResponse") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume response node doesn't exist")
        }
        
        guard let volumeEle = response.po_firstChild(localName: "CurrentVolume") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume CurrentVolume node doesn't exist")
        }
        guard let value = volumeEle.int else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume CurrentVolume node value can't convert to Int, value: \(volumeEle.value ?? "")")
        }
        return CastActionResponse.Volume(value: value)
    }

    static func parseVolumn(_ data: Data) throws -> CastActionResponse.Volume {
        try parseVolume(data)
    }
    
    static func parsePositionInfo(_ data: Data) throws -> CastActionResponse.PositionInfo {
        let body = try soapBody(from: data, parserName: "PositionInfo")
        guard let response = body.po_firstChild(localName: "GetPositionInfoResponse") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo response node doesn't exist")
        }
        
        var trackDuration: String?
        if let ele = response.po_firstChild(localName: "TrackDuration") {
            trackDuration = ele.value
        }
        var relTime: String?
        if let ele = response.po_firstChild(localName: "RelTime") {
            relTime = ele.value
        }
        return CastActionResponse.PositionInfo(trackDuration: trackDuration, relTime: relTime)
    }
    
    static func parseTransportInfo(_ data: Data) throws -> CastActionResponse.TransportInfo {
        let body = try soapBody(from: data, parserName: "TransportInfo")
        guard let response = body.po_firstChild(localName: "GetTransportInfoResponse") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser TransportInfo response node doesn't exist")
        }
        
        var currentTransportState: CastActionResponse.AVTransportState?
        if let ele = response.po_firstChild(localName: "CurrentTransportState"), let value = ele.value {
            currentTransportState = CastActionResponse.AVTransportState(rawValue: value)
        }
        var currentTransportStatus: CastActionResponse.AVTransportStatus?
        if let ele = response.po_firstChild(localName: "CurrentTransportStatus"), let value = ele.value {
            currentTransportStatus = CastActionResponse.AVTransportStatus(rawValue: value)
        }
        var currentSpeed: String?
        if let ele = response.po_firstChild(localName: "CurrentSpeed") {
            currentSpeed = ele.value
        }
        
        return CastActionResponse.TransportInfo(currentTransportState: currentTransportState, currentTransportStatus: currentTransportStatus, currentSpeed: currentSpeed)
    }
    
    static func parseServerFault(_ data: Data) throws -> CastError.ServerFault {
        let body = try soapBody(from: data, parserName: "ServerFault")
        guard let fault = body.po_firstChild(localName: "Fault") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser ServerFault Fault node doesn't exist")
        }
        
        var faultCode: String?
        if let ele = fault.po_firstChild(localName: "faultcode"), let value = ele.value {
            faultCode = value
        }
        var faultString: String?
        if let ele = fault.po_firstChild(localName: "faultstring"), let value = ele.value {
            faultString = value
        }
        var errorCode: String?
        var errorDescription: String?
        if let detail = fault.po_firstChild(localName: "detail"),
           let upnpError = detail.po_firstChild(localName: "UPnPError") {
            if let ele = upnpError.po_firstChild(localName: "errorCode"), let value = ele.value {
                errorCode = value
            }
            if let ele = upnpError.po_firstChild(localName: "errorDescription"), let value = ele.value {
                errorDescription = value
            }
        }
        
        return CastError.ServerFault(faultCode: faultCode, faultString: faultString, detailErrorCode: errorCode, detailErrorDescription: errorDescription)
    }

    private static func soapBody(from data: Data, parserName: String) throws -> AEXMLElement {
        let xmlDoc = try AEXMLDocument(xml: data)
        let envelope = xmlDoc.root.po_localName == "Envelope" ? xmlDoc.root : xmlDoc.root.po_firstChild(localName: "Envelope")
        guard let envelope else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser \(parserName) Envelope node doesn't exist")
        }
        guard let body = envelope.po_firstChild(localName: "Body") else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser \(parserName) Body node doesn't exist")
        }
        return body
    }

}
