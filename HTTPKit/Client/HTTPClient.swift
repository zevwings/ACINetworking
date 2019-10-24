//
//  HTTPClient.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public final class HTTPClient<R: Request> : Client {

    let session: Session
    let plugins: [PluginType]

    /// 初始化方法
    public init(
        session: Session = HTTPClient.defaultSession(),
        plugins: [PluginType] = []
    ) {
        self.session = session
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

        var alamofireRequest: Requestable
        do {
            let constructor = try Constructor(request: request)
            alamofireRequest = try constructor.process(with: session, plugins: plugins)
        } catch {
            completionHandler(.failure(HTTPError.underlying(error, request: nil, response: nil)))
            return nil
        }

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

        alamofireRequest = alamofireRequest.progress(queue: callbackQueue,
                                                     progressHandler: internalProgressHandler)

        let internalCompletionHandler: ((Result<Response, HTTPError>) -> Void) = { result in

            self.plugins.forEach { $0.didReceive(result, request: request) }
            if let interceptor = request.interceptor {
                interceptor.didReceive(result, request: request)
            }

            if let progressHandler = progressHandler {
                let value = try? result.get()
                progressHandler(ProgressResponse(progress: alamofireRequest.executeProgress, response: value))
            }

            switch result {
            case .success(let response):
                do {
                    var response = response
                    /// 通过插件和拦截器处理返回结果
                    response = try self.plugins.reduce(response) { try $1.intercept(response: $0) }
                    if let interceptor = request.interceptor {
                        response = try interceptor.intercept(response: response)
                    }
                    var data = response.data
                    /// 通过`Transformer`对返回数据进行数据处理
                    if let transformer = request.transformer {
                        data = try transformer.transform(data)
                    }
                    /// 当`Request`实现`RequestPaginator`协议时，进行分页相关操作并对数据进行转换
                    if var paginator = request.paginator {
                        data = try paginator.transform(data)
                    }

                    response.update(data)

                    completionHandler(.success(response))
                } catch let error {
                    let err = HTTPError.underlying(error, request: response.request, response: response.response)
                    completionHandler(.failure(err))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }

        alamofireRequest = alamofireRequest.response(queue: callbackQueue,
                                                     completionHandler: internalCompletionHandler)

        let task = HTTPTask(request: alamofireRequest)
        task.resume()
        return task
    }
}
