//
//  Response+Logger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/2.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

extension HTTPLogger {

    public static func transform(
        _ logLevel: LogLevel,
        targetType: Any.Type,
        request: URLRequest?,
        extra content: Any? = nil
    ) {
        var description: String = ""
        description.append("-------------------------- Log Start --------------------------\n")
        description.append("✅✅数据转化为\(targetType)✅✅\n")
        description.append("url: \(request?.url?.absoluteString ?? "")\n")
        description.append("headerFields: \(request?.allHTTPHeaderFields ?? [:])\n")
        if let httpBody = request?.httpBody, let parameters = String(data: httpBody, encoding: .utf8) {
            description.append("parameters: \(parameters)\n")
        } else {
            description.append("parameters: \n")
        }
        if let content = content {
            description.append("------------------------------------------------------------\n")
            description.append("content: \(content)\n")
        }
        description.append("--------------------------- Log End ---------------------------\n")
        HTTPLogger.log(logLevel, items: description)
    }
}
