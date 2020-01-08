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
public typealias Destination = Alamofire.DownloadRequest.DownloadFileDestination
public typealias HTTPHeaders = Alamofire.HTTPHeaders

// Session
public typealias SessionManager = Alamofire.SessionManager
public typealias SessionDelegate = Alamofire.SessionDelegate

// Request
public typealias DataRequest = Alamofire.DataRequest
public typealias UploadRequest = Alamofire.UploadRequest
public typealias DownloadRequest = Alamofire.DownloadRequest
public typealias RequestMultipartFormData = Alamofire.MultipartFormData

// Result
public typealias DataResponse = Alamofire.DataResponse
public typealias DownloadResponse = Alamofire.DownloadResponse
public typealias DataResponseSerializerProtocol = Alamofire.DataResponseSerializerProtocol
public typealias DownloadResponseSerializerProtocol = Alamofire.DownloadResponseSerializerProtocol

public typealias URLRequestConvertible = Alamofire.URLRequestConvertible

// RequestInterceptor
public typealias RequestRetrier = Alamofire.RequestRetrier

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
    func progress(
        queue: DispatchQueue,
        progressHandler: @escaping InternalProgressHandler
    ) -> Self

    /// 格式化网络请求回调内容
    func response(
        queue: DispatchQueue,
        completionHandler: @escaping (Swift.Result<Response, HTTPError>) -> Void
    ) -> Self

    /// 格式化网络请求返回Code验证
    func validate<S>(statusCode acceptableStatusCodes: S) -> Self where S : Sequence, S.Element == Int

}

// MARK: - UploadRequest

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

// MARK: - DataRequest

extension RequestConvertible where Self : DataRequest {

    var executeProgress: Progress {
        return self.progress
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
        completionHandler: @escaping (Swift.Result<Response, HTTPError>) -> Void
    ) -> Self {

        let internalCompletionHandler: (DataResponse<Response>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err = HTTPError.external(error, request: response.request, response: response.response)
                completionHandler(.failure(err))
            }
        }

        //swiftlint:disable:next line_length
        let responseSerializer = DataResponseSerializer { (request, response, data, error) -> Alamofire.Result<Response> in

            if let err = error {
                switch err._code {
                case NSURLErrorTimedOut:
                    return .failure(HTTPError.timeout(request: request, response: response))
                case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
                    return .failure(HTTPError.connectionLost(request: request, response: response))
                default:
                    return .failure(HTTPError.external(err, request: request, response: response))
                }
            }

            guard let validData = data, !validData.isEmpty else {
                return .failure(HTTPError.emptyResponse(request: request, response: response))
            }

            let response = Response(request: request, response: response, data: validData)
            return .success(response)
        }

        return response(
            queue: queue,
            responseSerializer: responseSerializer,
            completionHandler: internalCompletionHandler
        )
    }
}

extension DataRequest : RequestConvertible {}

// MARK: - DownloadRequest

extension RequestConvertible where Self : DownloadRequest {

    var executeProgress: Progress {
        return self.progress
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
        completionHandler: @escaping (Swift.Result<Response, HTTPError>) -> Void
    ) -> Self {

        let internalCompletionHandler: (DownloadResponse<Response>) -> Void = { response in
            switch response.result {
            case .success(let value):
                completionHandler(.success(value))
            case .failure(let error):
                let err: HTTPError
                 switch error._code {
                 case NSURLErrorTimedOut:
                     err = HTTPError.timeout(request: response.request, response: response.response)
                 case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
                     err = HTTPError.connectionLost(request: response.request, response: response.response)
                 default:
                     err = HTTPError.external(error, request: response.request, response: response.response)
                 }
                completionHandler(.failure(err))
            }
        }

        let responseSerializer = DownloadResponseSerializer { (request, response, url, error) -> Result<Response> in

            guard let fileURL = url else {
                return .failure(HTTPError.emptyResponse(request: request, response: response))
            }

            let data: Data
            do {
                data = try Data(contentsOf: fileURL)
            } catch let err {
                return .failure(HTTPError.external(err, request: request, response: response))
            }

            if data.isEmpty {
                return .failure(HTTPError.emptyResponse(request: request, response: response))
            }

            let response = Response(request: request, response: response, data: data)
            return.success(response)
        }

        return response(
            queue: queue,
            responseSerializer: responseSerializer,
            completionHandler: internalCompletionHandler
        )
    }
}

extension DownloadRequest : RequestConvertible {}

// MARK: - TaskConvertible

protocol TaskConvertible {

    /// 格式化当前网络请求
    var request: URLRequest? { get }

    /// 格式化取消网络请求
    func cancel()

    /// 格式化暂停网络请求
    func suspend()

    /// 格式化恢复网络请求
    func resume()
}

extension DataRequest : TaskConvertible {}
extension DownloadRequest : TaskConvertible {}

// MARK: - DataResponseSerializer

struct DataResponseSerializer : DataResponseSerializerProtocol {

    typealias SerializedObject = Response
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Alamofire.Result<Response>

    //swiftlint:disable:next line_length
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Alamofire.Result<Response>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - DownloadResponseSerializer

struct DownloadResponseSerializer : DownloadResponseSerializerProtocol {

    typealias SerializedObject = Response

    var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Alamofire.Result<Response>

    //swiftlint:disable:next line_length
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Alamofire.Result<Response>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - Retrier

public struct Retrier: Alamofire.RequestRetrier {

    let plugins: [PluginType]

    init (_ plugins: [PluginType]) {
        self.plugins = plugins
    }

    public func should(
        _ manager: SessionManager,
        retry request: Alamofire.Request,
        with error: Error,
        completion: @escaping RequestRetryCompletion
    ) {
        plugins.forEach { $0.retry(error, completion: completion) }
    }
}
