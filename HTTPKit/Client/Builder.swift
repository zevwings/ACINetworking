//
//  Constructor.swift
//
//  Created by zevwings on 2019/1/28.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Builder

public protocol Builder {

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    func process<R>(request: R, manager: SessionManager, plugins: [PluginType]) throws -> Requestable where R: Request
}

// MARK: - RequestBuilder

public class RequestBuilder : Builder {

    public init() {}

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    public func process<R>(
        request: R,
        manager: SessionManager,
        plugins: [PluginType]
    ) throws -> Requestable where R : Request {

        /// 通过插件和拦截器处理请求参数
        /// 错误类型：自定义错误
        var parameters = request.content.parameters
        parameters = try plugins.reduce(parameters) { try $1.intercept(paramters: $0) }
        if let interceptor = request.interceptor {
            parameters = try interceptor.intercept(paramters: parameters)
        }

        /// 处理分页参数
        if let paginator = request.paginator {
            parameters = parameters ?? [:]  /// 防止请求参数为空
            parameters?[paginator.countKey] = paginator.count
            parameters?[paginator.indexKey] = paginator.index
        }

        /// 错误类型：HTTPError.encode
        var urlRequest = try buildUrlRequest(request: request, parameters: parameters)
        /// 通过插件和拦截器处理网络请求
        /// 错误类型：自定义错误
        urlRequest = try plugins.reduce(urlRequest) { try $1.intercept(urlRequest: $0) }
        if let interceptor = request.interceptor {
            urlRequest = try interceptor.intercept(urlRequest: urlRequest)
        }

        /// 将要发送网络请求
        plugins.forEach { $0.willSend(urlRequest, request: request) }
        if let interceptor = request.interceptor {
            interceptor.willSend(urlRequest, request: request)
        }

        return try buildAlamoRequest(request, urlRequest: urlRequest, manager: manager, plugins: plugins)
    }

    /// 构建一个`UrlRequest`
    private func buildUrlRequest<R>(request: R, parameters: Parameters?) throws -> URLRequest where R: Request {

        guard let url = URL(string: request.route.path, relativeTo: request.service.url) else {
            throw HTTPError.invalidUrl(url: request.service.url, path: request.route.path)
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = request.route.method.rawValue

        request.headerFields.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        if let encoding = request.content.encoding {
            do {
                urlRequest = try encoding.encode(urlRequest, with: parameters)
            } catch {
                throw HTTPError.encode(parameters: parameters, encoding: encoding, error: error)
            }
        }

        return urlRequest
    }

    /// 从`URLRequest`构建对应的`Alamofire.Request`
    private func buildAlamoRequest<R>(
        _ request: R,
        urlRequest: URLRequest,
        manager: SessionManager,
        plugins: [PluginType]
    ) throws -> Requestable where R: Request {

//        /// 生成Alamofire拦截器
//        var plugins: [PluginType] = plugins
//        if let interceptor = request.interceptor {
//            plugins.append(interceptor)
//        }

        /// 生成请求
        var alamoRequest: Requestable?
        var error: Error?

        switch request.content {
        case .requestPlain, .requestParameters:
            alamoRequest = manager.request(urlRequest)
        case .download(let destination), .downloadParameters(_, _, let destination):
            alamoRequest = manager.download(urlRequest, to: destination)
        case .uploadFile(let fileURL):
            alamoRequest = manager.upload(fileURL, with: urlRequest)
        case .uploadFormData(let mutipartFormData), .uploadFormDataParameters(_, _, let mutipartFormData):
            let multipartFormData: (RequestMultipartFormData) -> Void = { formData in
                formData.applyMoyaMultipartFormData(mutipartFormData)
            }
            manager.upload(multipartFormData: multipartFormData, with: urlRequest, encodingCompletion: { result in
                switch result {
                case .success(let request, _, _):
                    alamoRequest = request
                case .failure(let err):
                    alamoRequest = nil
                    error = err
                }
            })
        }

        if let alamoRequest = alamoRequest {
            let validateStatusCode = request.validationType.statusCodes
            return validateStatusCode.isEmpty ?
                alamoRequest :
                alamoRequest.validate(statusCode: validateStatusCode)
        } else {
            throw HTTPError.multipart(error: error, reqeuest: urlRequest)
        }
    }
}
