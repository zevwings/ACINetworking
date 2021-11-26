//
//  Plugin.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/12.
//

import Foundation

public typealias RetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

public protocol PluginType {

    /// 拦截请求参数，可以在生成`URLRequest`之前，对参数进行修改
    func intercept<API>(api: API, paramters: [String: Any]?) throws -> [String: Any]?  where API: ApiManager

    /// 拦截网络请求，可以在发起网络请求之前，对`URLRequest`进行修改
    func intercept<API>(api: API, urlRequest: URLRequest) throws -> URLRequest where API: ApiManager

    /// 拦截网络请求结果，可以在反序列化结果之前对返回结果`Response`进行修改
    func intercept<API>(api: API, response: Response) throws -> Response where API: ApiManager

    /// 网络请求收到结果
    func didReceive<API>(api: API, result: Result<Response, HTTPError>) where API: ApiManager

    /// 经过 `Plugin`, `Transformer` 处理之后最终获取的结果
    func didComplete<API>(api: API, result: Result<Response, HTTPError>) where API: ApiManager

    /// 网络请求需要自动重试
    func retry<API>(api: API, urlRequest: URLRequest) -> Retrier? where API: ApiManager
}

public extension PluginType {

    /// 拦截请求参数，可以在生成`URLRequest`之前，对参数进行修改
    func intercept<API>(api: API, paramters: [String: Any]?) throws -> [String: Any]?  where API: ApiManager {
        return paramters
    }

    /// 拦截网络请求，可以在发起网络请求之前，对`URLRequest`进行修改
    func intercept<API>(api: API, urlRequest: URLRequest) throws -> URLRequest where API: ApiManager {
        return urlRequest
    }

    /// 拦截网络请求结果，可以在反序列化结果之前对返回结果`Response`进行修改
    func intercept<API>(api: API, response: Response) throws -> Response where API: ApiManager {
        return response
    }

    /// 网络请求收到结果
    func didReceive<API>(api: API, result: Result<Response, HTTPError>) where API: ApiManager {

    }

    /// 经过 `Plugin`, `Transformer` 处理之后最终获取的结果
    func didComplete<API>(api: API, result: Result<Response, HTTPError>) where API: ApiManager {

    }

    /// 网络请求需要自动重试
    func retry<API>(api: API, urlRequest: URLRequest) -> Retrier? where API: ApiManager {
        return nil
    }
}
