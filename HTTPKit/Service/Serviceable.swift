//
//  Serviceable.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public protocol Serviceable {

    /// 服务器基础路径
    var baseUrl: String { get }
}

extension Serviceable {

    var url: URL {
        return URL(string: baseUrl)!
    }
}
