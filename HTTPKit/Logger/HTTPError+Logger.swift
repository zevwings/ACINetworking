//
//  HTTPError+Logger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/2.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

extension HTTPLogger {

    public static func failure(
        _ logLevel: LogLevel,
        error: HTTPError
    ) {
        var description: String = ""
        description.append("-------------------------- Log Start --------------------------\n")
        description.append("💢💢\(error.description)💢💢\n")

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
        description.append("------------------------------------------------------------\n")
        description.append("error: \(error.error)\n")
        description.append("--------------------------- Log End ---------------------------")
        HTTPLogger.log(logLevel, items: description)
    }

}
