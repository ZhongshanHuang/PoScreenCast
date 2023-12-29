//
//  CastRemoteControlParser.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/17.
//

import Foundation
import AEXML

struct CastRemoteControlParser {
    
    static func parseVolumn(_ data: Data) throws -> CastActionResponse.Volume {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let envelope = xmlDoc.children.first(where: { $0.name == "s:Envelope" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo Envelope node doesn't exists")
        }
        guard let body = envelope.children.first(where: { $0.name == "s:Body" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume body node doesn't exists")
        }
        guard let response = body.children.first(where: { $0.name == "u:GetVolumeResponse" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume response node doesn't exists")
        }
        
        guard let volumeEle = response.children.first(where: { $0.name == "CurrentVolume" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volume CurrentVolume node doesn't exists")
        }
        guard let value = volumeEle.int else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser Volumn CurrentVolume node value can't convert to Int, value: \(volumeEle.value ?? "")")
        }
        return CastActionResponse.Volume(value: value)
    }
    
    static func parsePositionInfo(_ data: Data) throws -> CastActionResponse.PositionInfo {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let envelope = xmlDoc.children.first(where: { $0.name == "s:Envelope" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo Envelope node doesn't exists")
        }
        guard let body = envelope.children.first(where: { $0.name == "s:Body" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo body node doesn't exists")
        }
        guard let response = body.children.first(where: { $0.name == "u:GetPositionInfoResponse" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo response node doesn't exists")
        }
        
        var trackDuration: String?
        if let ele = response.children.first(where: { $0.name == "TrackDuration" }) {
            trackDuration = ele.value
        }
        var relTime: String?
        if let ele = response.children.first(where: { $0.name == "RelTime" }) {
            relTime = ele.value
        }
        return CastActionResponse.PositionInfo(trackDuration: trackDuration, relTime: relTime)
    }
    
    static func parseTransportInfo(_ data: Data) throws -> CastActionResponse.TransportInfo {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let envelope = xmlDoc.children.first(where: { $0.name == "s:Envelope" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser PositionInfo Envelope node doesn't exists")
        }
        guard let body = envelope.children.first(where: { $0.name == "s:Body" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser TransportInfo body node doesn't exists")
        }
        guard let response = body.children.first(where: { $0.name == "u:GetTransportInfoResponse" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser TransportInfo response node doesn't exists")
        }
        
        var currentTransportState: CastActionResponse.AVTransportState?
        if let ele = response.children.first(where: { $0.name == "CurrentTransportState" }), let value = ele.value {
            currentTransportState = CastActionResponse.AVTransportState(rawValue: value)
        }
        var currentTransportStatus: CastActionResponse.AVTransportStatus?
        if let ele = response.children.first(where: { $0.name == "CurrentTransportStatus" }), let value = ele.value {
            currentTransportStatus = CastActionResponse.AVTransportStatus(rawValue: value)
        }
        var currentSpeed: String?
        if let ele = response.children.first(where: { $0.name == "currentSpeed" }) {
            currentSpeed = ele.value
        }
        
        return CastActionResponse.TransportInfo(currentTransportState: currentTransportState, currentTransportStatus: currentTransportStatus, currentSpeed: currentSpeed)
    }
    
    static func parseServerFault(_ data: Data) throws -> CastError.ServerFault {
        let xmlDoc = try AEXMLDocument(xml: data)
        guard let envelope = xmlDoc.children.first(where: { $0.name == "s:Envelope" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser ServerFault Envelope node doesn't exists")
        }
        guard let body = envelope.children.first(where: { $0.name == "s:Body" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser ServerFault body node doesn't exists")
        }
        guard let fault = body.children.first(where: { $0.name == "s:Fault" }) else {
            throw CastError.ParserError.parseFailed("CastRemoteControlParser ServerFault Fault node doesn't exists")
        }
        
        var faultCode: String?
        if let ele = fault.children.first(where: { $0.name == "faultcode" }), let value = ele.value {
            faultCode = value
        }
        var faultString: String?
        if let ele = fault.children.first(where: { $0.name == "faultstring" }), let value = ele.value {
            faultString = value
        }
        var errorCode: String?
        var errorDescription: String?
        if let detail = fault.children.first(where: { $0.name == "detail" }),
            let upnpError = detail.children.first(where: { $0.name == "UPnPError" }) {
            if let ele = upnpError.children.first(where: { $0.name == "errorCode" }), let value = ele.value {
                errorCode = value
            }
            if let ele = upnpError.children.first(where: { $0.name == "errorDescription" }), let value = ele.value {
                errorDescription = value
            }
        }
        
        return CastError.ServerFault(faultCode: faultCode, faultString: faultString, detailErrorCode: errorCode, detailErrorDescription: errorDescription)
    }

}
