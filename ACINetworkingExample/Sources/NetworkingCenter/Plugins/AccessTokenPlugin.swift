//
//  AccessTokenPlugin.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking

public protocol AccessTokenAuthorizable {
    var authorizable : Bool { get }
}

public extension AccessTokenAuthorizable {
    var authorizable : Bool {
        return true
    }
}

public struct AccessTokenPlugin: PluginType {

    public init() {}

    /// 拦截数据
    /// - Parameters:
    ///   - urlRequest: 将要发送的 URLRequest
    ///   - request: 请求
    /// - Throws: 异常
    /// - Returns: 将要发送的 URLRequest
    public func intercept<API>(api: API, urlRequest: URLRequest) throws -> URLRequest where API : ApiManager {

        guard let authorizable = api as? AccessTokenAuthorizable, authorizable.authorizable else { return urlRequest }

        var urlRequest = urlRequest
        let token = ApplicationContext.shared.token
        if !token.isEmpty {
            urlRequest.addValue(token, forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
}

