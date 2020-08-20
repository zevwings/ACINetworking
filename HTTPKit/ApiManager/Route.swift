//
//  Route.swift
//
//  Created by zevwings on 2019/9/3.
//  Copyright © 2019 zevwings. All rights reserved.
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
