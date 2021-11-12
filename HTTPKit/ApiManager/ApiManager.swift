//
//  ApiManager.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

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
