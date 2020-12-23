//
//  ApiManager.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

// MARK: - Serviceable

public protocol Serviceable {

    /// 服务器基础路径
    var baseURL: String { get }

    /// 拦截请求参数，可以在生成`URLRequest`之前，对参数进行修改
    func intercept(paramters: [String: Any]?) throws -> [String: Any]?

    /// 拦截网络请求，可以在发起网络请求之前，对`URLRequest`进行修改
    func intercept(urlRequest: URLRequest) throws -> URLRequest

    /// 拦截网络请求结果，可以在反序列化结果之前对返回结果`Response`进行修改
    func intercept(response: Response) throws -> Response

}

extension Serviceable {

    var url: URL {
        guard let url = URL(string: baseURL) else {
            fatalError("无法转化为正确的URL")
        }
        return url
    }

    func intercept(paramters: [String: Any]?) throws -> [String: Any]? {
        return paramters
    }

    func intercept(urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    func intercept(response: Response) throws -> Response {
        return response
    }

}

// MARK: - Transformer

public protocol Transformer {

    /// 将服务器返回数据转换为业务数据
    ///
    /// - Parameters:
    ///   - data: 转换前的数据
    ///   - request: 请求
    /// - Returns: 转换后的数据
    /// - Throws: 转换异常
    func transform(_ data: Data) throws -> Data

}

// MARK: -

public protocol ApiManager {

    /// 服务器
    associatedtype Service: Serviceable

    /// 基础路径
    var service: Service { get }

    /// 请求路径
    var route: Route { get }

    /// 请求内容
    var content: Content { get }

    /// 请求头设置，默认为空
    var headerFields: [String: String] { get }

    /// 校验类型，校验返回的 status code 是否为正确的值，默认校验正确和重定向code
    var validationType: ValidationType { get }

    /// 分页参数
    var paginator: Paginator? { get }

    /// 数据转换器，默认为`nil`
    var transformer: Transformer? { get }

}

extension ApiManager {

    public var headerFields: [String: String] { return [:] }

    public var validationType: ValidationType { return .none }

    public var paginator: Paginator? { return nil }

    public var transformer: Transformer? { return nil }

}

// MARK: - Equatable

extension Equatable where Self : ApiManager {

    /**
     判断两个请求是否相等，只需要在Request的实现中添加Equatable即可，
     默认baseUrl, path, method 三者相同时，判定为同一个请求，
     如果需要自定义条件，可以自行实现该方法
     */
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.service.url == rhs.service.url &&
            lhs.route.path == rhs.route.path &&
            lhs.route.method.rawValue == rhs.route.method.rawValue
    }
}
