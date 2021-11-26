//
//  Defines.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/12.
//

import Foundation
import Alamofire

// MARK: - Defines

// Public
public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias Destination = Alamofire.DownloadRequest.Destination
public typealias HTTPHeaders = Alamofire.HTTPHeaders
public typealias HTTPHeader = Alamofire.HTTPHeader

// Session
public typealias Session = Alamofire.Session
public typealias SessionDelegate = Alamofire.SessionDelegate

// Request
public typealias RequestState = Alamofire.Request.State
public typealias Request = Alamofire.Request
public typealias DataRequest = Alamofire.DataRequest
public typealias UploadRequest = Alamofire.UploadRequest
public typealias DownloadRequest = Alamofire.DownloadRequest
public typealias RequestMultipartFormData = Alamofire.MultipartFormData

// Result
public typealias DataResponse = Alamofire.DataResponse
public typealias DownloadResponse = Alamofire.DownloadResponse
public typealias ResponseSerializerProtocol = Alamofire.ResponseSerializer
public typealias DataResponseSerializerProtocol = Alamofire.DataResponseSerializerProtocol
public typealias DownloadResponseSerializerProtocol = Alamofire.DownloadResponseSerializerProtocol
public typealias RequestError = Alamofire.AFError

// RequestInterceptor
public typealias Retrier = Alamofire.Retrier
public typealias RetryResult = Alamofire.RetryResult

// ParameterEncoding
public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding
public typealias URLEncoding = Alamofire.URLEncoding

// MARK: - Session

public extension Session {

    class var `default`: Session {

        let configuration = URLSessionConfiguration.default
        configuration.headers = HTTPHeaders.default
        configuration.timeoutIntervalForRequest = 15.0
        configuration.timeoutIntervalForResource = 15.0

        let delegate = SessionDelegate()
        let rootQueue = DispatchQueue(label: "com.zevwings.httpkit.rootQueue")
        let requestQueue = DispatchQueue(label: "com.zevwings.httpkit.requestQueue", target: rootQueue)
        let serializationQueue = DispatchQueue(label: "com.zevwings.httpkit.serializationQueue", target: rootQueue)
        let session = Session(
            configuration: configuration,
            delegate: delegate,
            rootQueue: rootQueue,
            startRequestsImmediately: false,
            requestQueue: requestQueue,
            serializationQueue: serializationQueue
        )
        return session
    }

    class var neverending: Session {

        let configuration = URLSessionConfiguration.default
        configuration.headers = HTTPHeaders.default

        let delegate = SessionDelegate()
        let rootQueue = DispatchQueue(label: "com.zevwings.httpkit.rootQueue")
        let requestQueue = DispatchQueue(label: "com.zevwings.httpkit.requestQueue", target: rootQueue)
        let serializationQueue = DispatchQueue(label: "com.zevwings.httpkit.serializationQueue", target: rootQueue)
        let session = Session(
            configuration: configuration,
            delegate: delegate,
            rootQueue: rootQueue,
            startRequestsImmediately: false,
            requestQueue: requestQueue,
            serializationQueue: serializationQueue
        )
        return session
    }
}
