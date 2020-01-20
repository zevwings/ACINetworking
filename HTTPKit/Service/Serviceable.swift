//
//  Serviceable.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public protocol Serviceable {

    /// 服务器基础路径
    var baseURL: String { get }
}

extension Serviceable {

    var url: URL {
        guard let url = URL(string: baseURL) else {
            fatalError("无法转化为正确的URL")
        }
        return url
    }
}
