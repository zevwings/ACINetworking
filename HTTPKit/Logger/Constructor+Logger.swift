//
//  Constructor+Logger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/8.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

extension HTTPLogger {

    public static func request(
        _ logLevel: LogLevel,
        urlRequest: URLRequest?
    ) {
        var description: String = ""
        description.append("-------------------------- Log Start --------------------------\n")
        description.append("🚀🚀准备发起网络请求🚀🚀\n")
        description.append("url: \(urlRequest?.url?.absoluteString ?? "")\n")
        description.append("method: \(urlRequest?.httpMethod ?? "")\n")
        description.append("headerFields: \(urlRequest?.allHTTPHeaderFields ?? [:])\n")
        if let httpBody = urlRequest?.httpBody, let parameters = String(data: httpBody, encoding: .utf8) {
            description.append("parameters: \(parameters)\n")
        } else {
            description.append("parameters: \n")
        }
        description.append("--------------------------- Log End ---------------------------\n")
        HTTPLogger.log(logLevel, items: description)
    }
}
