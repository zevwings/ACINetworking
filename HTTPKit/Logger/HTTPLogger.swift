//
//  HTTPLogger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/2.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

public struct HttpLogger {

    public enum LogLevel : Int {
        case verbose
        case info
        case error
        case none
    }

    public static var logLevel: HttpLogger.LogLevel = .none

    public static func error(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.error, items: items, separator: separator, terminator: terminator)
    }

    public static func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.info, items: items, separator: separator, terminator: terminator)
    }

    public static func verbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.verbose, items: items, separator: separator, terminator: terminator)
    }

    public static func log(_ logLevel: LogLevel, items: Any..., separator: String = " ", terminator: String = "\n") {
        if HttpLogger.logLevel.rawValue <= logLevel.rawValue {
            let description = items.map { String(describing: $0) }.joined(separator: separator)
            print(description, separator: separator, terminator: terminator)
        }
    }
}

extension HttpLogger {

    public enum LogType {
        case request
        case response
        case cast
    }

    /// 打印网络请求日志
    /// - Parameters:
    ///   - logLevel: @see HttpLogger.LogLevel
    ///   - logType: @see
    ///   - urlRequest: 网络请求 如果传入空，执行错误信息
    ///   - error: 网络错误信息
    ///   - response: 网络请求返回数据信息
    public static func log(
        _ logLevel: LogLevel,
        logType: LogType,
        urlRequest: URLRequest? = nil,
        error: HttpError? = nil,
        value: Any? = nil
    ) {
        var description: String = ""
        if let urlRequest = urlRequest {
            description.append("-------------------------- Log Start --------------------------\n")
            description.append("\(logType.successTitle)\n")
            description.append("url: \(urlRequest.url?.absoluteString ?? "")\n")
            description.append("method: \(urlRequest.httpMethod ?? "")\n")
            description.append("headerFields: \(urlRequest.allHTTPHeaderFields ?? [:])\n")
            if let httpBody = urlRequest.httpBody, let parameters = String(data: httpBody, encoding: .utf8) {
                description.append("parameters: \(parameters)\n")
            } else {
                description.append("parameters: \n")
            }
        } else if let error = error {
            description.append("-------------------------- Log Start --------------------------\n")
            description.append("\(logType.failureTitle)\n")
            description.append("\(error.description)\n")

            if let url = error.url {
                description.append("url: \(url)\n")
            } else {
                description.append("url: \n")
            }
            if let headerFields = error.request?.allHTTPHeaderFields {
                description.append("headerFields: \(headerFields)\n")
            } else {
                description.append("headerFields: \n")
            }
            if let httpBody = error.request?.httpBody, let parameters = String(data: httpBody, encoding: .utf8) {
                description.append("parameters: \(parameters)\n")
            } else {
                description.append("parameters: \n")
            }
        }

        if logType == .response, let response = value as? Response {
            description.append("------------------------------------------------------------\n")
            if let response = String(data: response.data, encoding: .utf8) {
                description.append("response: \(response)\n")
            } else {
                description.append("response: \n")
            }
        }

        if logType == .cast, let value = value {
            description.append("------------------------------------------------------------\n")
            description.append("content: \(value)\n")
        }

        description.append("--------------------------- Log End ---------------------------\n")

        log(logLevel, items: description)
    }
}

extension HttpLogger.LogType {

    var successTitle: String {
        switch self {
        case .request:
            return "🚀🚀发送网络请求成功🚀🚀"
        case .response:
            return "✅✅网络请求成功✅✅"
        case .cast:
            return "💯💯数据转化成功💯💯"
        }
    }

    var failureTitle: String {
        switch self {
        case .request:
            return "❓❓发送网络请求失败❓❓"
        case .response:
            return "💢💢网络请求失败💢💢"
        case .cast:
            return "❗️❗️数据转化失败❗️❗️"
        }
    }
}

private extension Result {

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }

    var error: Error? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}
