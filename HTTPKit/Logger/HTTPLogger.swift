//
//  HTTPLogger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/2.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

public struct HTTPLogger {

    public enum LogLevel : Int {
        case verbose
        case debug
        case error
        case none
    }

    public static var logLevel: HTTPLogger.LogLevel = .none

    public static func error(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.error, items: items, separator: separator, terminator: terminator)
    }

    public static func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.debug, items: items, separator: separator, terminator: terminator)
    }

    public static func verbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        log(.verbose, items: items, separator: separator, terminator: terminator)
    }

    public static func log(_ logLevel: LogLevel, items: Any..., separator: String = " ", terminator: String = "\n") {
        if HTTPLogger.logLevel.rawValue <= logLevel.rawValue {
            let description = items.map { String(describing: $0) }.joined(separator: separator)
            print(description, separator: separator, terminator: terminator)
        }
    }
}
