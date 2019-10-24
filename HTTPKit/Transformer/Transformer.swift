//
//  Transformer.swift
//
//  Created by zevwings on 2019/1/3.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

public protocol Transformer {

    /// 将数据转换为
    ///
    /// - Parameters:
    ///   - data: 转换前的数据
    ///   - request: 请求
    /// - Returns: 转换后的数据
    /// - Throws: 转换异常
    func transform(_ data: Data) throws -> Data

}
