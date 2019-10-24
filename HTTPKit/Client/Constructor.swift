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

    /// 构建一个`UrlRequest`
    func buildUrlRequest() throws -> URLRequest {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        headerFields?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

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
    func buildAlamofireRequest(
        _ urlRequest: URLRequest,
        session: Session,
        plugins: [PluginType]
    ) throws -> Requestable {

        /// 生成Alamofire拦截器
        var plugins: [PluginType] = plugins
        if let interceptor = request.interceptor {
            plugins.append(interceptor)
        }

        let retrier = Retrier(plugins)
        let interceptor: Alamofire.Interceptor? = plugins.isEmpty ?
            nil :
            Alamofire.Interceptor(adapters: [], retriers: [retrier])

        /// 生成请求
        var alamofireRequest: Requestable
        switch content {
        case .requestPlain, .requestParameters:
            alamofireRequest = session.request(urlRequest, interceptor: interceptor)
        case .download(let destination), .downloadParameters(_, _, let destination):
            alamofireRequest =  session.download(urlRequest, interceptor: interceptor, to: destination)
        case .uploadFile(let fileURL):
            alamofireRequest =  session.upload(fileURL, with: urlRequest, interceptor: interceptor)
        case .uploadFormData(let mutipartFormData), .uploadFormDataParameters(_, _, let mutipartFormData):
            let multipartFormData: (RequestMultipartFormData) -> Void = { formData in
                formData.applyMoyaMultipartFormData(mutipartFormData)
            }
            alamofireRequest = session.upload(multipartFormData: multipartFormData,
                                              with: urlRequest,
                                              interceptor: interceptor)
        }

        return validateStatusCode.isEmpty ?
            alamofireRequest :
            alamofireRequest.validate(statusCode: validateStatusCode)
    }

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    func process(
        with session: Session,
        plugins: [PluginType]
    ) throws -> Requestable {

        /// 通过插件和拦截器处理请求参数
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

        var urlRequest = try buildUrlRequest()

        /// 通过插件和拦截器处理网络请求
        urlRequest = try plugins.reduce(urlRequest) { try $1.intercept(urlRequest: $0) }
        if let interceptor = request.interceptor {
            urlRequest = try interceptor.intercept(urlRequest: urlRequest)
        }

        /// 将要发送网络请求
        plugins.forEach { $0.willSend(urlRequest, request: request) }
        if let interceptor = request.interceptor {
            interceptor.willSend(urlRequest, request: request)
        }

        return try buildAlamofireRequest(urlRequest, session: session, plugins: plugins)
    }
}

// MARK: -

public struct Retrier: RequestRetrier {

    let plugins: [PluginType]

    init (_ plugins: [PluginType]) {
        self.plugins = plugins
    }

    public func retry(
        _ request: Alamofire.Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        plugins.forEach { $0.retry(error, completion: completion) }
    }
}
