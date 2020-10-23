//
//  Task.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public protocol TaskType {

    var id: UUID { get }
    
    var state: RequestState { get }
    var isInitialized: Bool { get }
    var isResumed: Bool { get }
    var isSuspended: Bool { get }
    var isCancelled: Bool { get }
    var isFinished: Bool { get }
    
    /// 开始/恢复网络请求
    func resume()
    /// 暂停网络请求，仅`DownloadRequest`使用
    func suspend()
    /// 取消网络请求
    func cancel()
}

public final class Task : TaskType {

    public typealias CancelAction = () -> Void

    public var id: UUID { return request.id }
        
    public var state: RequestState { return request.state }
    public var isInitialized: Bool { return request.isInitialized }
    public var isResumed: Bool { return request.isResumed }
    public var isSuspended: Bool { return request.isSuspended }
    public var isCancelled: Bool { return request.isCancelled }
    public var isFinished: Bool { return request.isFinished }
    
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
        guard !isCancelled else { return }
        request.cancel()
        cancelAction()
    }
}

extension Task : CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        return String(describing: request.request)
    }

    public var debugDescription: String {
        return String(describing: request.request)
    }
}

extension Task : Equatable {}

public func == (lhs: Task, rhs: Task) -> Bool {
    return lhs.id == rhs.id
}
