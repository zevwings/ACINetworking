///
//  ApiManager.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/12.
//

import Foundation

// MARK: - ApiManager

/// 构建一组 API，提供给 `Client` 调用, 可以将 API 进行归类，方便 API 维护及查找
///     示例
///     ```
///     enum AccountAPI {
///         case login(username: String, password: String)
///     }
///
///     extension AccountAPI : ApiManager {
///
///         var node: NetworkingNode {
///             return .default
///         }
///
///         var route: Route {
///             switch self {
///             case .login:
///                 return .get("example-api/login/")
///             }
///         }
///
///         var content: Content {
///             switch self {
///             case let .login(username, password):
///                 let parameters: [String: Any] = [
///                     "username": username,
///                     "password": password
///                 ]
///                 return .requestParameters(parameters: JSONEncoding() => parameters)
///             }
///         }
///
///         var transformer: Transformer? {
///             return StandardTransformer.standard
///         }
///     }
///     ```
public protocol ApiManager {

    /// 服务器
    associatedtype Node: ACINetworking.Node

    /// 基础路径
    var node: Node { get }

    /// 请求路径
    var route: Route { get }

    /// 请求内容
    var content: Content { get }

    /// 请求头设置，默认为空
    var headerFields: [String: String] { get }

    /// 校验类型，校验返回的 status code 是否为正确的值，默认校验正确和重定向code
    var validationType: ACINetworking.ValidationType { get }

    /// 分页参数
    var paginator: ACINetworking.Paginator? { get }

    /// 数据转换器，默认为`nil`
    var transformer: ACINetworking.Transformer? { get }

}

extension ApiManager {

    public var headerFields: [String: String] { return [:] }

    public var validationType: ACINetworking.ValidationType { return .none }

    public var paginator: ACINetworking.Paginator? { return nil }

    public var transformer: ACINetworking.Transformer? { return nil }

}

extension Equatable where Self : ApiManager {

    /// 判断两个请求是否相等，只需要在Request的实现中添加Equatable即可，
    /// 默认`node`, `route` 相同时，判定为同一个请求，
    /// 如果需要自定义条件，可以自行实现该方法
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.node == rhs.node && lhs.route == rhs.route
    }
}
