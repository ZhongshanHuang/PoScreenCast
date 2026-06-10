//
//  CastAction.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/15.
//

import Foundation
import AEXML

extension CastAction {
    public enum CastServiceType: String {
        case avTransport = "urn:schemas-upnp-org:service:AVTransport:1"
        case renderingControl = "urn:schemas-upnp-org:service:RenderingControl:1"
    }
    
    public enum CastActionType {
        /* AVTransport */
        case setAVTransportURI(uri: String, videoName: String)
//        case setNextAVTransportURI(uri: String)
        case play
        case pause
        case stop
        case seek(position: Double)
//        case previous
//        case next
        case getPositionInfo
        case getTransportInfo
        
        /* RenderingControl */
        case getVolume
        case setVolume(volume: Int)
        
        var name: String {
            switch self {
            case .setAVTransportURI:
                "SetAVTransportURI"
            case .play:
                "Play"
            case .pause:
                "Pause"
            case .stop:
                "Stop"
            case .seek:
                "Seek"
            case .getPositionInfo:
                "GetPositionInfo"
            case .getTransportInfo:
                "GetTransportInfo"
            case .getVolume:
                "GetVolume"
            case .setVolume:
                "SetVolume"
            }
        }
    }
    
}

public struct CastAction {
    public let type: CastActionType
    public var serviceType: CastServiceType {
        switch type {
        case .getVolume, .setVolume:
            return .renderingControl
        default:
            return .avTransport
        }
    }
    public var SOAP: String {
        "\"\(serviceType.rawValue)#\(type.name)\""
    }
    public var xmlString: String {
        xmlDoc.xml
    }
    
    private let xmlDoc: AEXMLDocument
    
    public init(type: CastActionType) {
        self.type = type
        self.xmlDoc = AEXMLDocument()

        let attributes = ["s:encodingStyle": "http://schemas.xmlsoap.org/soap/encoding/",
                          "xmlns:s": "http://schemas.xmlsoap.org/soap/envelope/",
                          "xmlns:u": serviceType.rawValue]
        let envelopeEle = AEXMLElement(name: "s:Envelope", attributes: attributes)
        xmlDoc.addChild(envelopeEle)
        let bodyEle = AEXMLElement(name: "s:Body")
        envelopeEle.addChild(bodyEle)
        
        let xmlEle = AEXMLElement(name: "u:\(type.name)", attributes: ["xmlns:u": serviceType.rawValue])
        xmlEle.addChild(name: "InstanceID", value: "0")
        switch type {
        case let .setAVTransportURI(uri, videoName):
            xmlEle.addChild(name: "CurrentURI", value: uri)
            xmlEle.addChild(name: "CurrentURIMetaData", value: CastAction.currentURIMetaData(uri: uri, videoName: videoName))
        case .play:
            xmlEle.addChild(name: "Speed", value: "1")
        case .seek(let position):
            xmlEle.addChild(name: "Target", value: position.toTimeString)
            xmlEle.addChild(name: "Unit", value: "REL_TIME")
        case .getVolume:
            xmlEle.addChild(name: "Channel", value: "Master")
        case .setVolume(let volume):
            xmlEle.addChild(name: "Channel", value: "Master")
            xmlEle.addChild(name: "DesiredVolume", value: "\(volume)")
        default:
            break
        }
        
        bodyEle.addChild(xmlEle)
    }

    private static func currentURIMetaData(uri: String, videoName: String) -> String {
        let title = videoName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Video" : videoName
        let mimeType = mimeType(for: uri)
        return "<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\"><item id=\"0\" parentID=\"-1\" restricted=\"1\"><dc:title>\(title.xmlEscaped)</dc:title><upnp:class>object.item.videoItem</upnp:class><res protocolInfo=\"http-get:*:\(mimeType):DLNA.ORG_OP=01;DLNA.ORG_CI=0;DLNA.ORG_FLAGS=01700000000000000000000000000000\">\(uri.xmlEscaped)</res></item></DIDL-Lite>"
    }

    private static func mimeType(for uri: String) -> String {
        guard let pathExtension = URL(string: uri)?.pathExtension.lowercased(), !pathExtension.isEmpty else {
            return "*"
        }
        switch pathExtension {
        case "mp4", "m4v":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "m3u8":
            return "application/vnd.apple.mpegurl"
        case "ts":
            return "video/mp2t"
        case "mkv":
            return "video/x-matroska"
        case "avi":
            return "video/x-msvideo"
        case "mpeg", "mpg":
            return "video/mpeg"
        case "webm":
            return "video/webm"
        default:
            return "*"
        }
    }
    
}

extension Double {
    var toTimeString: String {
        String(format: "%02d:%02d:%02d", Int(self / 3600.0), Int(self.truncatingRemainder(dividingBy: 3600) / 60), Int(self.truncatingRemainder(dividingBy: 60)))
    }
}
