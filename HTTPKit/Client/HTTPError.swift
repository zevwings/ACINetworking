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

    /// 服务器返回数据为空
    case emptyResponse(request: URLRequest?, response: HTTPURLResponse?)

    /// 服务器返回statusCode 不为2xx
    case statusCode(request: URLRequest?, statustCode: Int)

    /// 服务器返回数据不能转换为目标数据类型
    case cast(value: Any?, targetType: Any.Type)

    /// 网络请求操作
    case timeout(request: URLRequest?, response: HTTPURLResponse?)

    /// 网络链接错误
    case connectionLost(request: URLRequest?, response: HTTPURLResponse?)

    /// 综合网络错误
    case underlying(Swift.Error, request: URLRequest?, response: HTTPURLResponse?)

}

extension HTTPError : LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .invalidUrl, .encode:
            return "网络请求失败"
        case .emptyResponse, .cast, .statusCode:
            return "服务器返回错误"
        case .timeout:
            return "网络请求超时\n请检查网络是否正常"
        case .connectionLost:
            return "网络链接错误\n请检查网络是否正常"
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
        case .emptyResponse(let request, _):
            return """
            ============================================================
            数据为空或者无法转换为JSON数据类型
            请求路径: \(request?.url?.relativeString ?? "")
            ============================================================
            """
        case .cast(let value, let targetType):
            return """
            ============================================================
            数据为空或者无法转换为目标数据类型
            "无法将\(String(describing: value))反序列化为\(targetType)"
            ============================================================
            """
        case .statusCode(let request, let statustCode):
            return """
            ============================================================
            数据为空或者无法转换为目标数据类型
            请求路径: \(request?.url?.relativeString ?? "")
            返回状态: \(statustCode)
            ============================================================
            """
        case .invalidUrl(let url, let path):
            return """
            ============================================================
            生成网络请求失败，`baseUrl`或者`path`填写错误 \n
            请求路径: url: \(url) path:\(path)
            ============================================================
            """
        case .encode(let parameters, let encoding, let error):
            return """
            ============================================================
            网络请求参数解析错误 \n
            请求参数：\(String(describing: parameters))
            解码方式：\(encoding)
            错误原因：\(error)
            ============================================================
            """
        case .timeout(let request, _):
            return """
            ============================================================
            网络请求超时，请检查网络是否正常
            请求路径: \(request?.url?.relativeString ?? "")
            ============================================================
            """
        case .connectionLost(let request, _):
            return """
            ============================================================
            网络连接失败，请检查网络是否正常
            请求路径: \(request?.url?.relativeString ?? "")
            ============================================================
            """
        case .underlying(let error, let request, _):
            return """
            ============================================================
            网络错误，具体错误信息如下
            请求路径: \(request?.url?.relativeString ?? "")
            错误原因: \(error)
            ============================================================
            """
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
        case .underlying(let error, _, _):
            return error
        default:
            return self
        }
    }
}
