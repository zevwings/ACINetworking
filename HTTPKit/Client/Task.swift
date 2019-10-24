//
//  Task.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public protocol Task {

    var isCancelled: Bool { get }

    /// 开始/恢复网络请求
    func resume()

    /// 暂停网络请求
    func suspend()

    /// 取消网络请求
    func cancel()
}

public final class HTTPTask : Task {

    public typealias CancelAction = () -> Void

    public private(set) var isCancelled: Bool = false

    private let request: Requestable
    private let cancelAction: CancelAction
    private var lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    convenience init(request alamofireRequest: Requestable) {
        self.init(alamofireRequest) {
            alamofireRequest.cancel()
        }
    }

    init(_ alamofireRequest: Requestable, cancelAction action: @escaping CancelAction) {
        request = alamofireRequest
        cancelAction = action
    }

    public func resume() {
        request.resume()
    }

    public func suspend() {
        request.suspend()
    }

    public func cancel() {
        _ = lock.wait(timeout: DispatchTime.distantFuture)
        defer { lock.signal() }
        guard !isCancelled else {
            return
        }
        isCancelled = true
        cancelAction()
    }
}

extension HTTPTask : CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        return String(describing: request.request)
    }

    public var debugDescription: String {
        return String(describing: request.request)
    }
}
