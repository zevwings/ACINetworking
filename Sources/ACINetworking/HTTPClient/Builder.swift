//
//  Builder.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation
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

// MARK: - Builder

public struct Builder : BuilderType {

    public init() {}

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    public func process<API>(
        api: API,
        session: Session,
        plugins: [PluginType]
    ) throws -> (urlRequest: URLRequest, alamo: Requestable) where API: ApiManager {

        let url = api.node.baseURL.asURL()
        let path = api.route.path
        guard let url = URL(string: path, relativeTo: url) else {
            throw HTTPError.invalidURL(baseURL: url, path: path)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = api.route.method.rawValue
        api.headerFields.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) }

        switch api.content {
        case let .requestData(data):
            urlRequest.httpBody = data
        default:
            var parameters = api.content.parameters?.values
            /// 处理分页参数
            if let paginator = api.paginator {
                parameters = parameters ?? [:]  /// 防止请求参数为空
                parameters?[paginator.countKey] = paginator.count
                parameters?[paginator.indexKey] = paginator.index
            }

            /// 通过插件和拦截器处理请求参数
            /// 错误类型：自定义错误
            parameters = try plugins.reduce(parameters) { try $1.intercept(api: api, paramters: $0)}

            let encoding = api.content.parameters?.encoding
            if let encoding = encoding {
                do {
                    urlRequest = try encoding.encode(urlRequest, with: parameters)
                } catch {
                    /// 错误类型：HTTPError.encode
                    throw HTTPError.encode(
                        urlRequest: urlRequest,
                        parameters: parameters,
                        encoding: encoding,
                        error: error
                    )
                }
            }
        }

        /// 通过插件拦截处理网络请求
        /// 错误类型：自定义错误
        urlRequest = try plugins.reduce(urlRequest) { try $1.intercept(api: api, urlRequest: $0) }

        /// 通过插件处理网络请求重试
        let retriers = plugins.compactMap { $0.retry(api: api, urlRequest: urlRequest) }
        let interceptor: Alamofire.Interceptor? = plugins.isEmpty ?
            nil :
            Alamofire.Interceptor(adapters: [], retriers: retriers)

        /// 生成请求 AlamofireRequest
        var alamofireRequest: Requestable
        switch api.content {
        case .requestPlain, .requestParameters, .requestData:
            alamofireRequest = session.request(urlRequest, interceptor: interceptor)
        case let .download(destination), let .downloadParameters(destination, _):
            alamofireRequest =  session.download(urlRequest, interceptor: interceptor, to: destination)
        case let .uploadFile(fileURL):
            alamofireRequest =  session.upload(fileURL, with: urlRequest, interceptor: interceptor)
        case let .uploadFormData(mutipartFormData), let .uploadFormDataParameters(mutipartFormData, _):
            let multipartFormData: (RequestMultipartFormData) -> Void = { formData in
                formData.applyMultipartFormData(mutipartFormData)
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

}
