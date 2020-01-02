//
//  HTTPError.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public enum HTTPError : Error {

    /// 请求链接错误，不能拼接成正确的Url
    case invalidUrl(url: URL, path: String)

    /// 解析参数错误
    case encode(parameters: Parameters?, encoding: ParameterEncoding, error: Error)

    /// 构建 Multi-part 网络请求失败
    case multipart(error: Error?, reqeuest: URLRequest)

    /// 服务器返回数据为空
    case emptyResponse(request: URLRequest?, response: HTTPURLResponse?)

    /// 服务器返回statusCode 不为2xx
    case statusCode(request: URLRequest?, statustCode: Int)

    /// 服务器返回数据不能转换为目标数据类型
    case cast(value: Any?, targetType: Any.Type, request: URLRequest?, response: HTTPURLResponse?)

    /// 网络请求操作
    case timeout(request: URLRequest?, response: HTTPURLResponse?)

    /// 网络链接错误
    case connectionLost(request: URLRequest?, response: HTTPURLResponse?)

    /// 外部错误，系统错误或者AF底层错误
    case external(Swift.Error, request: URLRequest?, response: HTTPURLResponse?)

    /// 综合网络错误
    case underlying(Swift.Error, request: URLRequest?, response: HTTPURLResponse?)

}

extension HTTPError : LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidUrl, .encode, .multipart:
            return "网络请求失败"
        case .emptyResponse, .cast, .statusCode:
            return "服务器返回错误"
        case .timeout:
            return "网络请求超时\n请检查网络是否正常"
        case .connectionLost:
            return "网络链接错误\n请检查网络是否正常"
        case .external:
            return "网络请求失败"
        case .underlying(let error, _, _):
            return errorHandler(error: error, defaultMessage: "网络错误")
        }
    }

    func errorHandler(error: Error, defaultMessage message: String) -> String {
        if error is LocalizedError {
            return error.localizedDescription
        } else {
            return message
        }
    }
}

extension HTTPError : CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        switch self {
        case .invalidUrl:
            return "URL不合法"
        case .encode:
            return "网络请求参数解析错误"
        case .multipart:
            return "无法成功构建Multi-part网络请求"
        case .emptyResponse:
            return "数据为空或者无法转换为JSON数据类型"
        case .cast:
            return "数据为空或者无法转换为目标数据类型"
        case .statusCode:
            return "服务器返回StatusCode不为2xx"
        case .timeout:
            return "网络请求超时，请检查网络是否正常"
        case .connectionLost:
            return "网络连接失败，请检查网络是否正常"
        case .external:
            return "系统错误"
        case .underlying:
            return "网络错误，具体错误信息如下"
        }
    }

    public var debugDescription: String {
        return description
    }
}

extension HTTPError {

    /// 获取到真实的Error
    public var error: Error {
        switch self {
        case .multipart(let error, _):
            if let error = error {
                return error
            } else {
                return self
            }
        case .underlying(let error, _, _):
            return error
        case .external(let error, _, _):
            return error
        default:
            return self
        }
    }

    public var request: URLRequest? {
        switch self {
        case .invalidUrl, .encode:
            return nil
        case .multipart(_, let request):
            return request
        case .emptyResponse(let request, _):
            return request
        case .cast(_, _, let request, _):
            return request
        case .statusCode(let request, _):
            return request
        case .timeout(let request, _):
            return request
        case .connectionLost(let request, _):
            return request
        case .external(_, let request, _):
            return request
        case .underlying(_, let request, _):
            return request
        }

    }

    public var url: String? {
        switch self {
        case .invalidUrl(let url, let path):
            return String(format: "%@ ----> %@", path, url.absoluteString)
        default:
            return request?.url?.absoluteString
        }
    }
}
