//
//  Client.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public protocol Client : AnyObject {

    // swiftlint:disable:next type_name
    associatedtype R: Request

    /// 发送一个网络请求
    ///
    /// - Parameters:
    ///   - request: Requestable
    ///   - callbackQueue: 回调线程
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 进度回调
    /// - Returns: 请求任务
    // swiftlint:disable:next line_length
    func request(request: R, callbackQueue: DispatchQueue, progressHandler: ((ProgressResponse) -> Void)?, completionHandler: @escaping (Result<Response, HTTPError>) -> Void) -> Task?
}
