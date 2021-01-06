//
//  Service.swift
//  HTTPKit
//
//  Created by zevwings on 2021/1/6.
//  Copyright © 2021 zevwings. All rights reserved.
//

import Foundation

public protocol Serviceable {

    /// 服务器基础路径
    var baseURL: String { get }

    /// 公共请求头设置，默认为空
    var headerFields: [String: String]? { get }
}

public extension Serviceable {

    var url: URL {
        guard let url = URL(string: baseURL) else {
            fatalError("无法转化为正确的URL")
        }
        return url
    }

    /// 请求头设置，默认为空
    var headerFields: [String: String]? {
        return nil
    }
}
