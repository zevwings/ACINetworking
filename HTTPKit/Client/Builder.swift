//
//  Constructor.swift
//
//  Created by zevwings on 2019/1/28.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Alamofire

// MARK: - Builder

public protocol BuilderType {

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    func process<API>(
        api: API,
        session: Session,
        plugins: [PluginType]
    ) throws -> (urlRequest: URLRequest, alamo: Requestable) where API: ApiManager
}

// MARK: - RequestBuilder

public class Builder : BuilderType {

    public init() {}

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    //swiftlint:disable function_body_length
    public func process<API>(
        api: API,
        session: Session,
        plugins: [PluginType]
    ) throws -> (urlRequest: URLRequest, alamo: Requestable) where API: ApiManager {

        guard let url = URL(string: api.route.path, relativeTo: api.service.url) else {
            throw HttpError.invalidUrl(url: api.service.url, path: api.route.path)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = api.route.method.rawValue
        api.headerFields.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        var parameters = api.content.parameters?.values
        /// 处理分页参数
        if let paginator = api.paginator {
            parameters = parameters ?? [:]  /// 防止请求参数为空
            parameters?[paginator.countKey] = paginator.count
            parameters?[paginator.indexKey] = paginator.index
        }

        /// 通过插件和拦截器处理请求参数
        /// 错误类型：自定义错误
        parameters = try plugins.reduce(parameters) { try $1.intercept(api: api, paramters: parameters)}

        let encoding = api.content.parameters?.encoding
        if let encoding = encoding {
            do {
                urlRequest = try encoding.encode(urlRequest, with: parameters)
            } catch {
                /// 错误类型：HTTPError.encode
                throw HttpError.encode(parameters: parameters, encoding: encoding, error: error)
            }
        }

        /// 通过插件和拦截器处理网络请求
        /// 错误类型：自定义错误
        urlRequest = try plugins.reduce(urlRequest) { try $1.intercept(api: api, urlRequest: urlRequest) }

        /// 将要发送网络请求
        plugins.forEach { $0.willSend(api: api, urlRequest: urlRequest) }

        let retrier = Retrier(api: api, plugins: plugins)
        let interceptor: Alamofire.Interceptor? = plugins.isEmpty ?
            nil :
            Alamofire.Interceptor(adapters: [], retriers: [retrier])

        /// 生成请求 AlamofireRequest
        var alamofireRequest: Requestable
        switch api.content {
        case .requestPlain, .requestParameters:
            alamofireRequest = session.request(urlRequest, interceptor: interceptor)
//        case let .requestJSONEncodable(encodable):
//            return try request.encoded(encodable: encodable)
//        case let .requestCustomJSONEncodable(encodable, encoder: encoder):
//            return try request.encoded(encodable: encodable, encoder: encoder)
        case let .download(destination), let .downloadParameters(destination, _):
            alamofireRequest =  session.download(urlRequest, interceptor: interceptor, to: destination)
        case let .uploadFile(fileURL):
            alamofireRequest =  session.upload(fileURL, with: urlRequest, interceptor: interceptor)
        case let .uploadFormData(mutipartFormData), let .uploadFormDataParameters(mutipartFormData, _):
            let multipartFormData: (RequestMultipartFormData) -> Void = { formData in
                formData.applyMoyaMultipartFormData(mutipartFormData)
            }
            alamofireRequest = session.upload(
                multipartFormData: multipartFormData,
                with: urlRequest,
                interceptor: interceptor
            )
        }

        let validateStatusCode = api.validationType.statusCodes
        let alamoRequest = validateStatusCode.isEmpty ?
            alamofireRequest :
            alamofireRequest.validate(statusCode: validateStatusCode)

        return (urlRequest, alamoRequest)
    }
    //swiftlint:enable function_body_length
}

// MARK: - Alamofire RequestRetrier

final class Retrier<API : ApiManager>: RequestRetrier {

    let api: API
    let plugins: [PluginType]
    init (api: API, plugins: [PluginType]) {
        self.api = api
        self.plugins = plugins
    }

    public func retry(
        _ request: Alamofire.Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        plugins.forEach { $0.retry(api: api, error: error, completion: completion) }
    }
}
