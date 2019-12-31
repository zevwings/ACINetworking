//
//  Logger.swift
//  HTTPKit
//
//  Created by zevwings on 2019/12/31.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

public struct HTTPKit {

    public enum LogLevel : Int {
        case verbose
        case debug
        case error
    }

    public static var logLevel: LogLevel = .error
}

public extension HTTPKit {

    static func logError(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if HTTPKit.logLevel.rawValue <= LogLevel.error.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }

    static func logDebug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if HTTPKit.logLevel.rawValue <= LogLevel.debug.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }

    static func logVerbose(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if HTTPKit.logLevel.rawValue <= LogLevel.verbose.rawValue {
            print(items, separator: separator, terminator: terminator)
        }
    }
}
