//
//  Node.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

/// 将服务器路径封装到对象中，维护一个或者多个服务器结点，提供给 `ApiManager`
/// 当服务器提采用微服务或者需要多服务器节点访问时，可以将服务器地址维护到一起，更为简单易读
///     示例：
///     ```
///     public enum NetworkingNode {
///         case `default`
///         case payment
///     }
///
///     extension NetworkingNode: Node {
///
///         public var baseURL: URLConvertible {
///             switch self {
///             case .default:
///                 return "https://example.com.cn/base-api"
///             case .payment:
///                 return "https://example.com.cn/payment-api"
///             }
///         }
///     }
///     ```
public protocol Node {

    /// 服务器基础路径
    var baseURL: URLConvertible { get }

    /// 公共请求头设置，默认为空
    var headerFields: [String: String]? { get }
}

public extension Node {

    /// 请求头设置，默认为空
    var headerFields: [String: String]? {
        return nil
    }
}

extension Equatable where Self: Node {}

public func == (lhs: Node, rhs: Node) -> Bool {
    return lhs.baseURL.asURL() == rhs.baseURL.asURL()
}

// MARK: - URLConvertible

/// 实现 `URLConvertible` 协议，构建一个可用的 `Optional URL`
public protocol URLConvertible {

    /// 返回一个 `URL` 实例
    ///
    /// - Returns: 返回一个 `URL` 实例
    func asURL() -> URL?
}

extension String: URLConvertible {

    /// 返回一个 `URL` 实例
    ///
    /// - Returns: 返回一个 `URL` 实例
    public func asURL() -> URL? {
        return URL(string: self)
    }
}

extension URL: URLConvertible {

    /// 返回 `self`.
    public func asURL() -> URL? {
        return self
    }
}

extension URLComponents: URLConvertible {

    /// 返回实例中的 `url` 实例
    ///
    /// - Returns: 返回实例中的 `url` 属性
    public func asURL() -> URL? {
        return url
    }
}
