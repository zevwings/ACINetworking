//
//  HTTPClient+Alamofire.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Definition

// Public
public typealias HTTPMethod = Alamofire.HTTPMethod
public typealias Destination = Alamofire.DownloadRequest.Destination
public typealias HTTPHeaders = Alamofire.HTTPHeaders
public typealias HTTPHeader = Alamofire.HTTPHeader

// Session
public typealias Session = Alamofire.Session
public typealias SessionDelegate = Alamofire.SessionDelegate

// Request
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

public typealias URLRequestConvertible = Alamofire.URLRequestConvertible

// RequestInterceptor
public typealias RetryResult = Alamofire.RetryResult

// ParameterEncoding
public typealias ParameterEncoding = Alamofire.ParameterEncoding
public typealias JSONEncoding = Alamofire.JSONEncoding
public typealias URLEncoding = Alamofire.URLEncoding

// Requestable
typealias Requestable = RequestConvertible & TaskConvertible
typealias InternalProgressHandler = (Progress) -> Void

// MARK: - RequestConvertible

protocol RequestConvertible {

    var executeProgress: Progress { get }

    /// 格式化网络请求进度回调
    func progress(queue: DispatchQueue, progressHandler: @escaping InternalProgressHandler) -> Self

    /// 格式化网络请求回调内容
    func response(queue: DispatchQueue, completionHandler: @escaping (Result<Response, HTTPError>) -> Void) -> Self

    /// 格式化网络请求返回Code验证
    func validate<S>(statusCode acceptableStatusCodes: S) -> Self where S : Sequence, S.Element == Int

}

extension RequestConvertible where Self : DataRequest {

    var executeProgress: Progress {
        return self.downloadProgress
    }

    func progress(
        queue: DispatchQueue = .main,
        progressHandler: @escaping InternalProgressHandler
    ) -> Self {
        return downloadProgress(closure: { progress in
            progressHandler(progress)
        })
    }

    func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Self {
        let internalCompletionHandler: (DataResponse<Response, AFError>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err = HTTPError.underlying(error, request: response.request, response: response.response)
                completionHandler(.failure(err))
            }
        }

        return response(queue: queue,
                        responseSerializer: ResponseSerializer(),
                        completionHandler: internalCompletionHandler)
    }
}

extension RequestConvertible where Self : UploadRequest {

    var executeProgress: Progress {
        return self.uploadProgress
    }

    @discardableResult
    func progress(
        queue: DispatchQueue = .main,
        progressHandler: @escaping ProgressHandler
    ) -> Self {
            return uploadProgress(queue: queue, closure: { progress in
                progressHandler(progress)
            })
    }
}

extension RequestConvertible where Self : DownloadRequest {

    var executeProgress: Progress {
        return self.downloadProgress
    }

    func progress(
        queue: DispatchQueue = .main,
        progressHandler: @escaping InternalProgressHandler
    ) -> Self {
        return downloadProgress(queue: queue) { progress in
            progressHandler(progress)
        }
    }

    func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Self {
        let internalCompletionHandler: (DownloadResponse<Response, AFError>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err = HTTPError.underlying(error, request: response.request, response: response.response)
                completionHandler(.failure(err))
            }
        }

        return response(queue: queue,
                        responseSerializer: ResponseSerializer(),
                        completionHandler: internalCompletionHandler)
    }
}

extension DataRequest : RequestConvertible {}
extension DownloadRequest : RequestConvertible {}

// MARK: - TaskConvertible

protocol TaskConvertible {

    /// 格式化当前网络请求
    var request: URLRequest? { get }

    /// 格式化取消网络请求
    @discardableResult func cancel() -> Self

    /// 格式化暂停网络请求
    @discardableResult func suspend() -> Self

    /// 格式化恢复网络请求
    @discardableResult func resume() -> Self
}

extension DataRequest : TaskConvertible {}
extension DownloadRequest : TaskConvertible {}

// MARK: - DataResponseSerializer

struct ResponseSerializer : ResponseSerializerProtocol {

    typealias SerializedObject = Response

    func serialize(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?
    ) throws -> Response {

        if let err = error {
            switch err._code {
            case NSURLErrorTimedOut:
                throw HTTPError.timeout(request: request, response: response)
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
                throw HTTPError.connectionLost(request: request, response: response)
            default:
                throw err
            }
        }

        guard let validData = data, !validData.isEmpty else {
            throw HTTPError.emptyResponse(request: request, response: response)
        }

        return Response(request: request, response: response, data: validData)
    }
}
