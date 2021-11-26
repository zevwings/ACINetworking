//
//  Route.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

public enum Route {
    case get(String)
    case post(String)
    case put(String)
    case delete(String)
    case options(String)
    case head(String)
    case patch(String)
    case trace(String)
    case connect(String)
}

extension Route {

    /// 请求路径
    var path: String {
        switch self {
        case let .get(path): return path
        case let .post(path): return path
        case let .put(path): return path
        case let .delete(path): return path
        case let .options(path): return path
        case let .head(path): return path
        case let .patch(path): return path
        case let .trace(path): return path
        case let .connect(path): return path
        }
    }

    /// 请求方式 See https://tools.ietf.org/html/rfc7231#section-4.3
    var method: HTTPMethod {
        switch self {
        case .get: return .get
        case .post: return .post
        case .put: return .put
        case .delete: return .delete
        case .options: return .options
        case .head: return .head
        case .patch: return .patch
        case .trace: return .trace
        case .connect: return .connect
        }
    }
}

extension Route: Equatable {}

public func == (lhs: Route, rhs: Route) -> Bool {
    return lhs.path == rhs.path && lhs.method == rhs.method
}
