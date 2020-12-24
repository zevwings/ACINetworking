//
//  HttpClient.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

// MARK: - ProgressResponse

public enum ProgressValue {
    case progress(Double)
    case completed(Response)
}

public enum ProgressResponse {
    case progress(Progress)
    case completed(Response?)
}

public extension ProgressResponse {
    
    var isCompleted: Bool {
        switch self {
        case .progress:
            return false
        case .completed:
            return true
        }
    }
    
    var progress: Double {
        switch self {
        case let .progress(value):
            return value.fractionCompleted
        case .completed:
            return 1.0
        }
    }
    
    var response: Response? {
        switch self {
        case .progress:
            return nil
        case let .completed(response):
            return response
        }
    }
}

//public struct ProgressResponse {
//
//    public let response: Response?
//    public let progressObject: Progress?
//
//    public init(progress: Progress? = nil, response: Response? = nil) {
//        self.progressObject = progress
//        self.response = response
//    }
//
//    public var progress: Double {
//        if completed {
//            return 1.0
//        } else if let progressObject = progressObject, progressObject.totalUnitCount > 0 {
//            return progressObject.fractionCompleted
//        } else {
//            return 0.0
//        }
//    }
//
//    public var value: ProgressValue {
//        if completed {
//            return .completed(response!)
//        } else {
//            return .progress(progressObject?.fractionCompleted ?? 0)
//        }
//    }
//
//    public var completed: Bool {
//        return response != nil
//    }
//}

// MARK: - Client

public protocol Client : AnyObject {

    associatedtype API: ApiManager

    /// 发送一个网络请求
    ///
    /// - Parameters:
    ///   - api: 提供请求的 @see ApiManager
    ///   - callbackQueue: 回调线程
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 进度回调
    /// - Returns: 请求任务
    func request(
        api: API,
        callbackQueue: DispatchQueue,
        progressHandler: ((ProgressResponse) -> Void)?,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> TaskType?
}

// MARK: - HttpClient

public final class HTTPClient<API: ApiManager> : Client {

    let session: Session
    let plugins: [PluginType]
    let builder: BuilderType

    /// 初始化方法
    public init(
        session: Session = .default,
        plugins: [PluginType] = [],
        builder: BuilderType = Builder()
    ) {
        self.session = session
        self.plugins = plugins
        self.builder = builder
    }

    ///
    /// - Parameters:
    ///   - request: Requestable
    ///   - queue: 回调线程
    ///   - progressHandler: 进度回调
    ///   - completiogenHandler: 完成回调
    /// - Returns: 请求任务
    //swiftlint:disable:next function_body_length
    @discardableResult public func request(
        api: API,
        callbackQueue: DispatchQueue = .main,
        progressHandler: ((ProgressResponse) -> Void)? = nil,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> TaskType? {

        let service = api.service

        /// 构建Alamofire请求
        var alamoRequest: Requestable
        do {
            let result = try builder.process(api: api, session: session, plugins: plugins)
            alamoRequest = result.alamo
            HTTPLogger.log(.info, logType: .request, urlRequest: result.urlRequest)
        } catch let error as HTTPError {
            HTTPLogger.log(.error, logType: .request, error: error)
            completionHandler(.failure(error))
            return nil
        } catch let error {
            let err = HTTPError.underlying(error, request: nil, response: nil)
            HTTPLogger.log(.error, logType: .request, error: err)
            completionHandler(.failure(err))
            return nil
        }

        /// 处理进度
        let internalProgressHandler: InternalProgressHandler = { progress in
            /// 通过插件和拦截器处理请求进度
            self.plugins.forEach { $0.process(api: api, progress: progress) }
            callbackQueue.async {
                progressHandler?(.progress(progress))
//                progressHandler?(ProgressResponse(progress: progress))
            }
        }

        alamoRequest = alamoRequest.progress(
            queue: callbackQueue,
            progressHandler: internalProgressHandler
        )

        /// 处理返回结果
        let internalCompletionHandler: ((Result<Response, HTTPError>) -> Void) = { result in

            self.plugins.forEach { $0.didReceive(api: api, result: result) }

            if let progressHandler = progressHandler {
                let value = try? result.get()
                progressHandler(.completed(value))
//                progressHandler?(.complted(value))
//                progressHandler(ProgressResponse(progress: alamoRequest.executeProgress, response: value))
            }

            switch result {
            case .success(let response):
                do {
                    var response = response

                    // 服务统一拦截处理返回结果
                    // 错误类型：自定义错误
                    response = try service.intercept(response: response)

                    // 通过插件和拦截器处理返回结果
                    // 错误类型：自定义错误
                    response = try self.plugins.reduce(response) { try $1.intercept(api: api, response: $0) }
                    var data = response.data

                    // 当`Request`实现`RequestPaginator`协议时，进行分页相关操作并对数据进行转换
                    // 错误类型：自定义错误
                    if let paginator = api.paginator {
                        try paginator.updateIndex(data)
                    }
                    // 通过`Transformer`对返回数据进行数据处理
                    // 错误类型：自定义错误
                    if let transformer = api.transformer {
                        data = try transformer.transform(data)
                        response.update(data)
                    }

                    self.plugins.forEach { $0.didComplete(api: api, result: .success(response)) }
                    HTTPLogger.log(.info, logType: .response, urlRequest: response.request, value: response)
                    completionHandler(.success(response))
                } catch let error as HTTPError {
                    HTTPLogger.log(.error, logType: .response, error: error, value: response)
                    completionHandler(.failure(error))
                } catch let error {
                    let err = HTTPError.underlying(error, request: response.request, response: response.response)
                    HTTPLogger.log(.error, logType: .response, error: err, value: response)
                    completionHandler(.failure(err))
                }
            case .failure(let error):
                HTTPLogger.log(.error, logType: .response, error: error)
                completionHandler(.failure(error))
            }
        }

        alamoRequest = alamoRequest.response(
            queue: callbackQueue,
            completionHandler: internalCompletionHandler
        )

        /// 生成 Tasks
        let task = Task(request: alamoRequest)
        task.resume()
        return task
    }
}
