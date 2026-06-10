//
//  CastError.swift
//  PoScreenCastDemo
//
//  Created by HzS on 2023/12/26.
//

import Foundation

public enum CastError {
    
    public enum SearchDeviceError: Error {
        case socketBindFailed(String)
        case socketConnectFailed(String)
        case socketSendFailed(String)
        case socketCloseFailed(String)
    }
    
    public enum RemoteControlError: Error {
        case failedBeforeSend(String)
        case serverFault(ServerFault)
        case missingControlURL(CastAction.CastServiceType)
        case invalidResponse
    }
    
    public enum ParserError: Error {
        case emptyData
        case parseFailed(String)
    }
    
    // https://www.cnblogs.com/mojies/p/13395237.html
    public struct ServerFault {
        public let faultCode: String?
        public let faultString: String?
        public let detailErrorCode: String?
        public let detailErrorDescription: String?
    }

}

extension CastError.SearchDeviceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .socketBindFailed(let message):
            return "Socket bind failed: \(message)"
        case .socketConnectFailed(let message):
            return "Socket connect failed: \(message)"
        case .socketSendFailed(let message):
            return "Socket send failed: \(message)"
        case .socketCloseFailed(let message):
            return "Socket close failed: \(message)"
        }
    }
}

extension CastError.RemoteControlError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failedBeforeSend(let message):
            return message
        case .serverFault(let fault):
            let error = [fault.detailErrorCode, fault.detailErrorDescription]
                .compactMap { $0 }
                .joined(separator: ": ")
            if !error.isEmpty {
                return error
            }
            let faultMessage = [fault.faultCode, fault.faultString]
                .compactMap { $0 }
                .joined(separator: ": ")
            return faultMessage.isEmpty ? "Server fault" : faultMessage
        case .missingControlURL(let serviceType):
            return "Missing controlURL for \(serviceType.rawValue)"
        case .invalidResponse:
            return "Invalid HTTP response"
        }
    }
}

extension CastError.ParserError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyData:
            return "Response data is empty or action type does not match parser"
        case .parseFailed(let message):
            return message
        }
    }
}
