//
//  HTTPClient+Logger.swift
//  HTTPKit
//
//  Created by zevwings on 2020/1/2.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

extension HTTPLogger {

    public static func success(
        _ logLevel: LogLevel,
        title: String,
        urlRequest: URLRequest?,
        extra result: Result<Response, HTTPError>? = nil
    ) {
        var description: String = ""
        description.append("-------------------------- Log Start --------------------------\n")
        description.append("\(title)\n")
        description.append("url: \(urlRequest?.url?.absoluteString ?? "")\n")
        description.append("method: \(urlRequest?.httpMethod ?? "")\n")
        description.append("headerFields: \(urlRequest?.allHTTPHeaderFields ?? [:])\n")
        if let httpBody = urlRequest?.httpBody, let parameters = String(data: httpBody, encoding: .utf8) {
            description.append("parameters: \(parameters)\n")
        } else {
            description.append("parameters: \n")
        }
        if let result = result {
            switch result {
            case .success(let response):
                if let response = String(data: response.data, encoding: .utf8) {
                    description.append("response: \(response)\n")
                } else {
                    description.append("response: \n")
                }
            case .failure(let error):
                description.append("------------------------------------------------------------\n")
                description.append("error: \(String(describing: error))\n")
            }
        }

        description.append("--------------------------- Log End ---------------------------\n")

        HTTPLogger.log(logLevel, items: description)
    }
}
