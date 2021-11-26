//
//  HTTPError.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/12.
//

import Foundation

public protocol HTTPErrorSendable {

    /// 自定义输出描述
    var description: String { get }

    /// 自定义 DEBUG 输出描述
    var debugDescription: String { get }

}

public enum HTTPError: Error {

    /// 在请求中发生错误的上下问对象（Alamofire 请求发送之后）
    public struct Context {

        /// 网络请求
        public let request: URLRequest?

        /// 网络返回
        public let response: URLResponse?

        /// 错误包装
        public let underlyingError: Error?

        public init(
            request: URLRequest?,
            response: URLResponse?,
            underlyingError: Error? = nil
        ) {
            self.request = request
            self.response = response
            self.underlyingError = underlyingError
        }
    }

    /// 请求链接错误，不能拼接成正确的Url
    case invalidURL(baseURL: URL?, path: String?)
    /// 解析参数错误
    case encode(urlRequest: URLRequest, parameters: [String: Any]?, encoding: ParameterEncoding, error: Error)
    /// 构建 Multi-part 网络请求失败
    case multipart(reqeuest: URLRequest, error: Error?)

    /// 网络请求操作
    case timeout(HTTPError.Context)
    /// 网络链接错误
    case connectionLost(HTTPError.Context)

    /// 校验 URLReponse Code 错误
    case statusCode(code: Int, context: HTTPError.Context)
    /// 服务器返回数据为空
    case emptyResponse(HTTPError.Context)
    /// Response 不能被解码成对应的类型
    case typeMismatch(value: Any?, targetType: Any.Type, context: HTTPError.Context)

    /// 自定义错误（接收自定义错误，可以自定义提示）
    case underlying(HTTPError.Context)
}

extension HTTPError : LocalizedError {

    public var errorDescription: String? {
        return errorMessage
    }
}

extension HTTPError : CustomStringConvertible {

    public var description: String {
        return errorMessage
    }
}

extension HTTPError: CustomDebugStringConvertible {

    public var debugDescription: String {
        switch self {
        case let .invalidURL(url, path):
            return """
            URL不合法，生成请求链接错误
            基础域名：\(String(describing: url?.absoluteString))
            请求路径：\(String(describing: path))
            """
        case let .encode(urlRequest, parameters, encoding, error):
            return """
            参数解析失败
            请求地址：\(String(describing: urlRequest.url?.absoluteString))
            解码方法：\(String(describing: encoding))
            解析参数：\(String(describing: parameters))
            失败原因：\(String(describing: error))
            """
        case let .multipart(urlRequest, error):
            return """
            "构建 `multi-part` 网络请求失败"
            请求地址：\(String(describing: urlRequest.url?.absoluteString))
            失败原因：\(String(describing: error))
            """
        case let .emptyResponse(context):
            return """
            服务器返回数据为空
            请求地址：\(String(describing: context))
            失败原因：\(String(describing: context.underlyingError))
            """
        case let .typeMismatch(value, type, context):
            return """
            数据为空或者无法转换为目标数据类型
            请求地址：\(String(describing: context))
            目标类型：\(String(describing: type))
            返回数据：\(String(describing: value))
            失败原因：\(String(describing: context.underlyingError))
            """
        case let .statusCode(code, context):
            return """
            服务器返回错误，Status Code \(code)
            请求地址：\(String(describing: context))
            """
        case let .timeout(context):
            return """
            网络请求超时，请检查网络是否正常
            请求地址：\(String(describing: context))
            """
        case let .connectionLost(context):
            return """
            网络连接失败，请检查网络是否正常
            请求地址：\(String(describing: context))
            """
        case let .underlying(context):
            return context.underlyingError.debugDescription
        }
    }
}

extension HTTPError {

    private var errorMessage: String {
        switch self {
        case .invalidURL, .encode, .multipart:
            return "网络请求失败"
        case .emptyResponse, .typeMismatch, .statusCode:
            return "服务器返回错误"
        case .timeout:
            return "网络请求超时"
        case .connectionLost:
            return "网络链接错误"
        case .underlying(let context):
            if let error = context.underlyingError as? LocalizedError {
                return error.localizedDescription
            } else {
                return "网络错误"
            }
        }
    }
}

// MARK: - Error Unwrapped

extension Error {

    public var httpError: HTTPError? {
        if self is HTTPError {
            return self as? HTTPError
        }
        return nil
    }

    public func asHTTPError(or defaultAFError: @autoclosure () -> HTTPError) -> HTTPError {
        self as? HTTPError ?? defaultAFError()
    }

    public var requestError: RequestError? {

        if let error = self as? RequestError {
            return error
        }

        if let error = self as? HTTPError {
            switch error {
            case let .encode(_, _, _, error):
                return error as? RequestError
            case let .multipart(_, error):
                return error as? RequestError
            case let .timeout(context):
                return context.underlyingError as? RequestError
            case let .connectionLost(context):
                return context.underlyingError as? RequestError
            case let .underlying(context):
                return context.underlyingError as? RequestError
            default:
                return nil
            }
        }

        return nil
    }

    public func asRequestError(or defaultAFError: @autoclosure () -> RequestError) -> RequestError {
        self as? RequestError ?? defaultAFError()
    }
}

// MARK: - Debug

extension URLRequest {

    public var debugURL: String {
        return url?.absoluteString ?? ""
    }

    public var debugHTTPMethod: String {
        return httpMethod ?? ""
    }

    public var debugHeaderFields: String {
        return String(describing: allHTTPHeaderFields ?? [:])
    }

    public var debugParameters: String {
        guard let httpBody = httpBody else { return "" }
        guard let parameters = String(data: httpBody, encoding: .utf8) else { return "" }
        return parameters
    }

    public var debugMessage: String {
        var message: String = ""
        message.append("请求地址：\(debugURL))\n")
        message.append("请求方法：\(debugHTTPMethod))\n")
        message.append("请求头：　\(debugHeaderFields))\n")
        message.append("请求参数：\(debugParameters))\n")
        return message
    }
}

extension HTTPError {

    public var debugURL: String {
        switch self {
        case let .invalidURL(baseURL, _):
            return baseURL?.absoluteString ?? ""
        case let .encode(urlRequest, _, _, _):
            return urlRequest.debugURL
        case let .multipart(urlRequest, _):
            return urlRequest.debugURL
        case let .timeout(context):
            return context.request?.debugURL ?? ""
        case let .connectionLost(context):
            return context.request?.debugURL ?? ""
        case let .statusCode(_, context):
            return context.request?.debugURL ?? ""
        case let .emptyResponse(context):
            return context.request?.debugURL ?? ""
        case let .typeMismatch(_, _, context):
            return context.request?.debugURL ?? ""
        case let .underlying(context):
            return context.request?.debugURL ?? ""
        }
    }

    public var debugHTTPMethod: String {
        switch self {
        case .invalidURL:
            return ""
        case let .encode(urlRequest, _, _, _):
            return urlRequest.debugHTTPMethod
        case let .multipart(urlRequest, _):
            return urlRequest.debugHTTPMethod
        case let .timeout(context):
            return context.request?.debugHTTPMethod ?? ""
        case let .connectionLost(context):
            return context.request?.debugHTTPMethod ?? ""
        case let .statusCode(_, context):
            return context.request?.debugHTTPMethod ?? ""
        case let .emptyResponse(context):
            return context.request?.debugHTTPMethod ?? ""
        case let .typeMismatch(_, _, context):
            return context.request?.debugHTTPMethod ?? ""
        case let .underlying(context):
            return context.request?.debugHTTPMethod ?? ""
        }
    }

    public var debugHeaderFields: String {
        switch self {
        case .invalidURL:
            return ""
        case let .encode(urlRequest, _, _, _):
            return urlRequest.debugHeaderFields
        case let .multipart(urlRequest, _):
            return urlRequest.debugHeaderFields
        case let .timeout(context):
            return context.request?.debugHeaderFields ?? ""
        case let .connectionLost(context):
            return context.request?.debugHeaderFields ?? ""
        case let .statusCode(_, context):
            return context.request?.debugHeaderFields ?? ""
        case let .emptyResponse(context):
            return context.request?.debugHeaderFields ?? ""
        case let .typeMismatch(_, _, context):
            return context.request?.debugHeaderFields ?? ""
        case let .underlying(context):
            return context.request?.debugHeaderFields ?? ""
        }
    }

    public var debugParameters: String {
        switch self {
        case .invalidURL:
            return ""
        case let .encode(urlRequest, _, _, _):
            return urlRequest.debugParameters
        case let .multipart(urlRequest, _):
            return urlRequest.debugParameters
        case let .timeout(context):
            return context.request?.debugParameters ?? ""
        case let .connectionLost(context):
            return context.request?.debugParameters ?? ""
        case let .statusCode(_, context):
            return context.request?.debugParameters ?? ""
        case let .emptyResponse(context):
            return context.request?.debugParameters ?? ""
        case let .typeMismatch(_, _, context):
            return context.request?.debugParameters ?? ""
        case let .underlying(context):
            return context.request?.debugParameters ?? ""
        }
    }
}
