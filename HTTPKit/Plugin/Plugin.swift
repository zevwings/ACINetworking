//
//  Plugin.swift
//
//  Created by zevwings on 2019/1/17.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

public typealias RetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

public protocol PluginType {

    /// 拦截请求参数，可以在生成`URLRequest`之前，对参数进行修改
    func intercept(paramters: Parameters?) throws -> Parameters?

    /// 拦截网络请求，可以在发起网络请求之前，对`URLRequest`进行修改
    func intercept(urlRequest: URLRequest) throws -> URLRequest

    /// 拦截网络请求结果，可以在反序列化结果之前对返回结果`Response`进行修改
    func intercept(response: Response) throws -> Response

    /// 网络请求将要发送
    func willSend<R>(_ urlRequest: URLRequest, request: R) where R: Request

    /// 网络请求进度回调
    func process<R>(_ progress: Progress, request: R) where R: Request

    /// 网络请求收到结果
    func didReceive<R>(_ result: Result<Response, HTTPError>, request: R) where R: Request

    /// 网络请求需要自动重试
    func retry(_ error: Error, completion: @escaping (RetryResult) -> Void)
}

// MARK: - Defaults

extension PluginType {

    public func intercept(paramters: Parameters?) throws -> Parameters? { return paramters }

    public func intercept(urlRequest: URLRequest) throws -> URLRequest { return urlRequest }

    public func intercept(response: Response) throws -> Response { return response }

    public func willSend<R>(_ urlRequest: URLRequest, request: R) where R: Request { }

    public func process<R>(_ progress: Progress, request: R) where R: Request { }

    public func didReceive<R>(_ result: Result<Response, HTTPError>, request: R) where R: Request { }

    public func retry(_ error: Error, completion: @escaping (RetryResult) -> Void) {}

}
