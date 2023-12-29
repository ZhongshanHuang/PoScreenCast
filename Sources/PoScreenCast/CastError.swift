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
