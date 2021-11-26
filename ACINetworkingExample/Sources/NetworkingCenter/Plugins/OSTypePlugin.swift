//
//  OSTypePlugin.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking

public struct OSTypePlugin: PluginType {

    public init() {}

    /// 拦截数据
    /// - Parameters:
    ///   - urlRequest: 将要发送的 URLRequest
    ///   - request: 请求
    /// - Throws: 异常
    /// - Returns: 将要发送的 URLRequest
    public func intercept<API>(api: API, urlRequest: URLRequest) throws -> URLRequest where API : ApiManager {

        var urlRequest = urlRequest
        urlRequest.addValue("ios", forHTTPHeaderField: "os_type")
        return urlRequest
    }
}
