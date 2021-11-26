//
//  HTTPLogger.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

public struct HTTPLogger {

    public enum LogLevel : Int {
        case verbose
        case debug
        case error
        case none
    }

    public static var logLevel: HTTPLogger.LogLevel = .verbose

    public static func logError(
        _ message: @autoclosure () -> Any,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        log(.error, message: message(), separator: separator, terminator: terminator)
    }

    public static func logDebug(
        _ message: @autoclosure () -> Any,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        log(.debug, message: message(), separator: separator, terminator: terminator)
    }

    public static func logVerbose(
        _ message: @autoclosure () -> Any,
        separator: String = " ",
        terminator: String = "\n"
    ) {
        log(.verbose, message: message(), separator: separator, terminator: terminator)
    }

    private static func log(
        _ logLevel: LogLevel,
        message: @autoclosure () -> Any,
        separator: String = " ",
        terminator: String = "\n"
    ) {

        let description = String(describing: message())

        if HTTPLogger.logLevel.rawValue <= logLevel.rawValue {
            print(description)
        }
    }
}

// MARK: -

extension HTTPLogger {

    public enum Stage {
        case request
        case response
        case transform
    }

    public static func logFailure(_ stage: Stage, error: HTTPError) {

        var description: String = ""

        description.append("-------------------------- Log Start --------------------------\n")
        switch stage {
        case .request:
            description.append("❓❓发送网络请求失败❓❓\n")
        case .response:
            description.append("💢💢网络请求失败💢💢\n")
        case .transform:
            description.append("❗️❗️数据转化失败❗️❗️\n")
        }
        description.append(error.debugDescription)
        description.append("URL: \(error.debugURL)\n")
        description.append("Method: \(error.debugHTTPMethod)\n")
        description.append("Headers: \(error.debugHeaderFields)\n")
        if !error.debugParameters.isEmpty {
            description.append("Paramters: \(error.debugParameters)\n")
        }
        description.append("------------------------------------------------------------\n")
        description.append("--------------------------- Log End ---------------------------\n")

        logError(description)
    }

    public static func logSuccess(
        _ stage: Stage,
        urlRequest: URLRequest?,
        data: Any? = nil
    ) {
        var description: String = ""

        description.append("-------------------------- Log Start --------------------------\n")
        switch stage {
        case .request:
            description.append("🚀🚀发送网络请求成功🚀🚀\n")
        case .response:
            description.append("✅✅网络请求成功✅✅\n")
        case .transform:
            description.append("💯💯数据转化成功💯💯\n")
        }

        description.append("URL: \(urlRequest?.debugURL ?? "")\n")
        description.append("Method: \(urlRequest?.debugHTTPMethod ?? "")\n")
        description.append("Headers: \(urlRequest?.debugHeaderFields ?? "")\n")
        if let parameters = urlRequest?.debugParameters, !parameters.isEmpty {
            description.append("Paramters: \(parameters)\n")
        }

        description.append("------------------------------------------------------------\n")

        if let data = data {
            description.append("Response: \(data)\n")
        } else {
            description.append("Response: \n")
        }

        description.append("--------------------------- Log End ---------------------------\n")

        logDebug(description)
    }
}
