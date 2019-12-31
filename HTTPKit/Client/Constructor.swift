//
//  Constructor.swift
//
//  Created by zevwings on 2019/1/28.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Constructor

class Constructor<R: Request> {

    let request: R
    let url: URL
    let method: HTTPMethod
    let headerFields: [String: String]?
    let content: Content
    let validateStatusCode: [Int]

    var parameters: Parameters?
    var encoding: ParameterEncoding?

    init(request: R) throws {

        self.request = request

        guard let url = URL(string: request.route.path, relativeTo: request.service.url) else {
            throw HTTPError.invalidUrl(url: request.service.url, path: request.route.path)
        }

        self.url = url
        self.method = request.route.method
        self.headerFields = request.headerFields
        self.content = request.content
        self.parameters = request.content.parameters
        self.encoding = request.content.encoding
        self.validateStatusCode = request.validationType.statusCodes
    }

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    func process(
        with manager: SessionManager,
        plugins: [PluginType]
    ) throws -> Requestable {

        /// 通过插件和拦截器处理请求参数
        /// 错误类型：自定义错误
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
        var urlRequest = try buildUrlRequest()

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

        return try buildAlamoRequest(urlRequest, manager: manager, plugins: plugins)
    }

    /// 构建一个`UrlRequest`
    private func buildUrlRequest() throws -> URLRequest {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        headerFields?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        HTTPKit.logDebug(
            """
            ============================================================
            发起网络请求
            url : \(url)
            parameters: \(parameters ?? [:])
            headerFields: \(headerFields ?? [:])
            ============================================================
            """
        )

        if let encoding = encoding {
            do {
                urlRequest = try encoding.encode(urlRequest, with: parameters)
            } catch {
                throw HTTPError.encode(parameters: parameters, encoding: encoding, error: error)
            }
        }

        return urlRequest
    }

    /// 从`URLRequest`构建对应的`Alamofire.Request`
    private func buildAlamoRequest(
        _ urlRequest: URLRequest,
        manager: SessionManager,
        plugins: [PluginType]
    ) throws -> Requestable {

        /// 生成Alamofire拦截器
        var plugins: [PluginType] = plugins
        if let interceptor = request.interceptor {
            plugins.append(interceptor)
        }

        /// 生成请求
        var alamoRequest: Requestable?
        var error: Error?
        switch content {
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
            return validateStatusCode.isEmpty ?
                alamoRequest :
                alamoRequest.validate(statusCode: validateStatusCode)
        } else {

            HTTPKit.logVerbose(
                """
                ============================================================
                构建网络请求失败
                url : \(url)
                parameters: \(parameters ?? [:])
                headerFields: \(headerFields ?? [:])
                ============================================================
                """
            )

            throw HTTPError.external(error!, request: urlRequest, response: nil)
        }
    }
}
