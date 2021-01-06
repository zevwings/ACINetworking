//
//  Transformer.swift
//  HTTPKit
//
//  Created by zevwings on 2021/1/6.
//  Copyright © 2021 zevwings. All rights reserved.
//

import Foundation

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
