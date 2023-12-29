//
//  CastActionResponse.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/27.
//

import Foundation

extension CastActionResponse {
    public enum AVTransportState: String {
        case playing = "PLAYING"
        case pause = "PAUSED_PLAYBACK"
        case stopped = "STOPPED"
        case noMediaPresent = "NO_MEDIA_PRESENT" // 与stop类似
        case transitioning = "TRANSITIONING"
    }
    
    public enum AVTransportStatus: String {
        case ok = "OK"
        case error = "ERROR_OCCURRED"
    }
    
    public struct PositionInfo {
        public let trackDuration: String? // 播放视频总时长
        public let relTime: String? // 播放时长
    }
    
    public struct TransportInfo {
        public let currentTransportState: AVTransportState?
        public let currentTransportStatus: AVTransportStatus?
        public let currentSpeed: String?
    }
    
    public struct Volume {
        public let value: Int
    }
}

public struct CastActionResponse {
    public let action: CastAction
    public let rawData: Data?
    public let failure: CastError.RemoteControlError?
    
    public func parseToPositionInfo() throws -> CastActionResponse.PositionInfo {
        guard let rawData, case .getPositionInfo = action.type else {
            throw CastError.ParserError.emptyData
        }
        return try CastRemoteControlParser.parsePositionInfo(rawData)
    }
        
    public func parseToTransportInfo() throws -> CastActionResponse.TransportInfo {
        guard let rawData, case .getTransportInfo = action.type else {
            throw CastError.ParserError.emptyData
        }
        return try CastRemoteControlParser.parseTransportInfo(rawData)
    }
    
    public func parseToVolume() throws -> CastActionResponse.Volume {
        guard let rawData, case .getVolume = action.type else {
            throw CastError.ParserError.emptyData
        }
        return try CastRemoteControlParser.parseVolumn(rawData)
    }

    
}

