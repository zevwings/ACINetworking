//
//  HTTPClient.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public final class HTTPClient<R: Request> : Client {

    let manager: SessionManager
    let plugins: [PluginType]

    /// 初始化方法
    public init(
        manager: SessionManager = HTTPClient.defaultSessionManager(),
        plugins: [PluginType] = []
    ) {
        self.manager = manager
        self.plugins = plugins
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
        request: R,
        callbackQueue: DispatchQueue = .main,
        progressHandler: ((ProgressResponse) -> Void)? = nil,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Task? {

        /// 设置重试
        manager.retrier = request.retrier

        /// 构建Alamofire请求
        var alamoRequest: Requestable
        let constructor: Constructor<R>
        do {
            constructor = try Constructor(request: request)
            alamoRequest = try constructor.process(with: manager, plugins: plugins)
            HTTPLogger.success(
                .debug,
                title: "🚀🚀准备发起网络请求🚀🚀",
                urlRequest: constructor.urlRequest
            )
        } catch let error as HTTPError {
            HTTPLogger.failure(.verbose, error: error)
            completionHandler(.failure(error))
            return nil
        } catch let error {
            let err = HTTPError.underlying(error, request: nil, response: nil)
            HTTPLogger.failure(.verbose, error: err)
            completionHandler(.failure(err))
            return nil
        }

        /// 处理进度

        let internalProgressHandler: InternalProgressHandler = { progress in
            /// 通过插件和拦截器处理请求进度
            self.plugins.forEach { $0.process(progress, request: request) }
            if let interceptor = request.interceptor {
                interceptor.process(progress, request: request)
            }

            callbackQueue.async {
                progressHandler?(ProgressResponse(progress: progress))
            }
        }

        alamoRequest = alamoRequest.progress(
            queue: callbackQueue,
            progressHandler: internalProgressHandler
        )

        /// 处理返回结果

        let internalCompletionHandler: ((Result<Response, HTTPError>) -> Void) = { result in
            HTTPLogger.success(
                .debug,
                title: "✅✅网络请求成功✅✅",
                urlRequest: constructor.urlRequest,
                extra: result
            )
            self.plugins.forEach { $0.didReceive(result, request: request) }
            if let interceptor = request.interceptor {
                interceptor.didReceive(result, request: request)
            }

            if let progressHandler = progressHandler {
                let value = try? result.get()
                progressHandler(ProgressResponse(progress: alamoRequest.executeProgress, response: value))
            }

            switch result {
            case .success(let response):
                do {
                    var response = response
                    // 通过插件和拦截器处理返回结果
                    response = try self.plugins.reduce(response) { try $1.intercept(response: $0) }
                    if let interceptor = request.interceptor {
                        // 错误类型：自定义错误
                        response = try interceptor.intercept(response: response)
                    }
                    var data = response.data
                    // 通过`Transformer`对返回数据进行数据处理
                    if let transformer = request.transformer {
                        // 错误类型：自定义错误
                        data = try transformer.transform(data)
                    }
                    // 当`Request`实现`RequestPaginator`协议时，进行分页相关操作并对数据进行转换
                    if let paginator = request.paginator {
                        // 错误类型：HTTP.external
                        data = try paginator.updateIndex(data)
                    }

                    response.update(data)

                    self.plugins.forEach { $0.didComplete(.success(response), request: request) }
                    if let interceptor = request.interceptor {
                        interceptor.didComplete(.success(response), request: request)
                    }

                    completionHandler(.success(response))
                } catch let error as HTTPError {
                    HTTPLogger.failure(.debug, error: error)
                    completionHandler(.failure(error))
                } catch let error {
                    let err = HTTPError.underlying(error, request: response.request, response: response.response)
                    HTTPLogger.failure(.debug, error: err)
                    completionHandler(.failure(err))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }

        alamoRequest = alamoRequest.response(
            queue: callbackQueue,
            completionHandler: internalCompletionHandler
        )

        /// 生成 Tasks

        let task = HTTPTask(request: alamoRequest)
        task.resume()
        return task
    }
}
