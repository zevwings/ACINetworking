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
public typealias RequestState = Alamofire.Request.State
public typealias Request = Alamofire.Request
public typealias DataRequest = Alamofire.DataRequest
public typealias UploadRequest = Alamofire.UploadRequest
public typealias DownloadRequest = Alamofire.DownloadRequest
public typealias RequestMultipartFormData = Alamofire.MultipartFormData
public typealias URLRequestConvertible = Alamofire.URLRequestConvertible

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

// Requestable
public typealias Requestable = RequestConvertible & TaskConvertible
public typealias InternalProgressHandler = (Progress) -> Void

// MARK: - RequestConvertible

public protocol RequestConvertible {

    var executeProgress: Progress { get }

    /// 格式化网络请求进度回调
    func progress(queue: DispatchQueue, progressHandler: @escaping InternalProgressHandler) -> Self

    /// 格式化网络请求回调内容
    func response(queue: DispatchQueue, completionHandler: @escaping (Result<Response, HTTPError>) -> Void) -> Self

    /// 格式化网络请求返回Code验证
    func validate<S>(statusCode acceptableStatusCodes: S) -> Self where S : Sequence, S.Element == Int

}

extension RequestConvertible where Self : DataRequest {

    public var executeProgress: Progress {
        switch self {
        case let uploadRequest as UploadRequest:
            return uploadRequest.uploadProgress
        default:
            return downloadProgress
        }
    }

    public func progress(
        queue: DispatchQueue = .main,
        progressHandler: @escaping InternalProgressHandler
    ) -> Self {
        switch self {
        case _ as UploadRequest:
            return uploadProgress(queue: queue) {  progress in
                progressHandler(progress)
            }
        default:
            return downloadProgress(queue: queue) { progress in
                progressHandler(progress)
            }
        }
    }

    public func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Self {
        let internalCompletionHandler: (DataResponse<Response, AFError>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err = self.afErrorMapping(error, request: response.request, response: response.response)
                completionHandler(.failure(err))
            }
        }

        return response(
            queue: queue,
            responseSerializer: ResponseSerializer(),
            completionHandler: internalCompletionHandler
        )
    }
}

extension RequestConvertible where Self : DownloadRequest {

    public var executeProgress: Progress {
        return self.downloadProgress
    }

    public func progress(
        queue: DispatchQueue = .main,
        progressHandler: @escaping InternalProgressHandler
    ) -> Self {
        return downloadProgress(queue: queue) { progress in
            progressHandler(progress)
        }
    }

    public func response(
        queue: DispatchQueue = .main,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Self {
        let internalCompletionHandler: (DownloadResponse<Response, AFError>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err = self.afErrorMapping(error, request: response.request, response: response.response)
                completionHandler(.failure(err))
            }
        }

        let responseSerializer = ResponseSerializer()
        return response(
            queue: queue,
            responseSerializer: responseSerializer,
            completionHandler: internalCompletionHandler
        )
    }
}

extension RequestConvertible {

    /// 处理 Alamofire 错误消息为 HTTPError
    /// - Parameters:
    ///   - error: Alamofire Error
    ///   - request: 请求内容
    ///   - response: 请求结果
    /// - Returns: HTTPError
    func afErrorMapping(_ error: AFError, request: URLRequest?, response: HTTPURLResponse?) -> HTTPError {
        switch error {
        case let .sessionTaskFailed(sError):
            switch sError._code {
            case NSURLErrorTimedOut:
                return HTTPError.timeout(request: request, response: response)
            case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                return HTTPError.connectionLost(request: request, response: response)
            default:
                return HTTPError.external(error, request: request, response: response)
            }
        default:
            return HTTPError.external(error, request: request, response: response)
        }
    }
}

extension DataRequest : RequestConvertible {}
extension DownloadRequest : RequestConvertible {}

// MARK: - TaskConvertible

public protocol TaskConvertible {

    var id: UUID { get }
    /// 格式化当前网络请求
    var request: URLRequest? { get }
    /// 格式化取消网络请求状态
    var state: RequestState { get }
    /// 格式化取消网络请求状态 `.initialized`.
    var isInitialized: Bool { get }
    /// Returns whether `state is `.resumed`.
    var isResumed: Bool { get }
    /// 格式化取消网络请求状态 `.suspended`.
    var isSuspended: Bool { get }
    /// 格式化取消网络请求状态 `.cancelled`.
    var isCancelled: Bool { get }
    /// 格式化取消网络请求状态 `.finished`.
    var isFinished: Bool { get }

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

        guard error == nil else { throw error! }

        guard let data = data, !data.isEmpty else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        return Response(request: request, response: response, data: data)
    }

    func serializeDownload(
        request: URLRequest?,
        response: HTTPURLResponse?,
        fileURL: URL?,
        error: Error?
    ) throws -> Self.SerializedObject {

        guard error == nil else { throw error! }

        guard let fileURL = fileURL else {
            throw AFError.responseSerializationFailed(reason: .inputFileNil)
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw AFError.responseSerializationFailed(reason: .inputFileReadFailed(at: fileURL))
        }

        return try serialize(request: request, response: response, data: data, error: error)
    }
}
