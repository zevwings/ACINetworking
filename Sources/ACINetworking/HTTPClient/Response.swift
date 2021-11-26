//
//  Response.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/12.
//

import Foundation

#if canImport(AppKit)
import AppKit
public typealias Image = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias Image = UIImage
#endif

// MARK: - ProgressResponse

public enum ProgressResponse {
    case progress(Progress)
    case completed(Result<Response, HTTPError>)
}

extension ProgressResponse {

    public var isCompleted: Bool {
        switch self {
        case .progress:
            return false
        case .completed:
            return true
        }
    }

    public var progress: Double {
        switch self {
        case let .progress(value):
            return value.fractionCompleted
        case .completed:
            return 1.0
        }
    }

    public var response: Response? {
        switch self {
        case .progress:
            return nil
        case let .completed(result):
            return try? result.get()
        }
    }

    public var error: Error? {
        switch self {
        case .progress:
            return nil
        case let .completed(result):
            return result.error
        }
    }
}

// MARK: - Response

public final class Response {

    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public private(set) var data: Data?
    public let statusCode: Int

    public init (request: URLRequest?, response: HTTPURLResponse?, data: Data?) {
        self.request = request
        self.response = response
        self.data = data
        self.statusCode = response?.statusCode ?? Int.min
    }

    public func updateData(_ data: Data?) {
        self.data = data
    }
}

extension Response : CustomDebugStringConvertible {

    public var description: String {
        return "StatusCode: \(statusCode), data: \(data?.count ?? 0)"
    }

    public var debugDescription: String {
        return """
        Response Request: \(request?.url?.absoluteString ?? "")
        StatusCode: \(statusCode)
        data: \(data?.count ?? 0)
        """
    }
}

extension Response : Equatable {}

public func == (lhs: Response, rhs: Response) -> Bool {
    return lhs.statusCode == rhs.statusCode
        && lhs.data == rhs.data
        && lhs.response == rhs.response
}

// MAKR: - Filter

extension Response {

    ///  过滤 Status Code 如果不为指定范围的 Code 时抛出异常
    /// - Throws: HTTPError
    /// - Returns: 当前 Response
    public func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            let context = HTTPError.Context(request: request, response: response)
            throw HTTPError.statusCode(code: statusCode, context: context)
        }
        return self
    }

    ///  过滤 Status Code 如果不为指定的 Code 时抛出异常
    /// - Throws: HTTPError
    /// - Returns: 当前 Response
    public func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    ///  过滤 Status Code 如果不为正确的 Code 时抛出异常
    /// - Throws: HTTPError
    /// - Returns: 当前 Response
    public func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    ///  过滤 Status Code 如果不为正确或重定向 Code 时抛出异常
    /// - Throws: HTTPError
    /// - Returns: 当前 Response
    public func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }
}

// MARK: - Mapping

extension Response {

    ///  将数据转换为图片
    /// - Throws: HTTPError
    /// - Returns: 图片对象
    public func mapImage(logSwitch: Bool = true) throws -> Image {

        guard let data = data else {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.emptyResponse(context)
            if logSwitch {
                HTTPLogger.logFailure(.transform, error: error)
            }
            throw error
        }

        guard let image = UIImage(data: data) else {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.typeMismatch(
                value: data,
                targetType: UIImage.self,
                context: context
            )
            if logSwitch {
                HTTPLogger.logFailure(.transform, error: error)
            }
            throw error
        }
        if logSwitch {
            HTTPLogger.logSuccess(.transform, urlRequest: request, data: image)
        }
        return image
    }

    /// 将数据转换为 JSON 对象
    /// - Parameters:
    ///   - atKeyPath: 从字典的中取出 `keyPath` 对应的值
    ///   - options: JSONSerialization.ReadingOptions
    ///   - failsOnEmptyData: 错误时是否，返回一个 NSNull 对象
    /// - Throws: HTTPError
    /// - Returns: JSON 对象
    public func mapJSON(
        atKeyPath keyPath: String? = nil,
        options: JSONSerialization.ReadingOptions = [.allowFragments],
        failsOnEmptyData: Bool = true,
        logSwitch: Bool = true
    ) throws -> Any {

        guard let data = data else {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.emptyResponse(context)
            if logSwitch {
                HTTPLogger.logFailure(.transform, error: error)
            }
            throw error
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: options)
            if let keyPath = keyPath {
                guard
                    let dictionary = (json as? [String: Any]) as NSDictionary?,
                    let value = dictionary.value(forKey: keyPath)
                else {
                    let context = HTTPError.Context(request: request, response: response)
                    let error = HTTPError.emptyResponse(context)
                    if logSwitch {
                        HTTPLogger.logFailure(.transform, error: error)
                    }
                    throw error
                }
                if logSwitch {
                    HTTPLogger.logSuccess(.transform, urlRequest: request, data: value)
                }
                return value
            } else {
                if logSwitch {
                    HTTPLogger.logSuccess(.transform, urlRequest: request, data: json)
                }
                return json
            }
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.typeMismatch(
                value: try? mapJSON(logSwitch: false),
                targetType: Any.self,
                context: context
            )
            if logSwitch {
                HTTPLogger.logFailure(.transform, error: error)
            }
            throw error
        }
    }

    /// 将数据转换为字符串
    /// - Parameter keyPath: KeyPath
    /// - Throws: HTTPError
    /// - Returns: 字符串
    public func mapString(atKeyPath keyPath: String? = nil, logSwitch: Bool = true) throws -> String {

        guard let data = data else {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.emptyResponse(context)
            if logSwitch {
                HTTPLogger.logFailure(.transform, error: error)
            }
            throw error
        }

        if let keyPath = keyPath {

            let value: Any
            do {
                value = try mapJSON(atKeyPath: keyPath, logSwitch: false)
            } catch let error as HTTPError {
                if logSwitch {
                    HTTPLogger.logFailure(.transform, error: error)
                }
                throw error
            } catch { /// 此处错误抓取不会执行，此处仅保证 `mapJSON`方法抛出异常必定被捕捉到
                let context = HTTPError.Context(request: request, response: response, underlyingError: error)
                let error = HTTPError.typeMismatch(
                    value: try? mapJSON(logSwitch: false),
                    targetType: String.self,
                    context: context
                )
                if logSwitch {
                    HTTPLogger.logFailure(.transform, error: error)
                }
                throw error
            }

            guard let string = value as? String else {
                let context = HTTPError.Context(request: request, response: response)
                let error = HTTPError.typeMismatch(
                    value: try? mapJSON(logSwitch: false),
                    targetType: String.self,
                    context: context
                )
                if logSwitch {
                    HTTPLogger.logFailure(.transform, error: error)
                }
                throw error
            }
            if logSwitch {
                HTTPLogger.logSuccess(.transform, urlRequest: request, data: string)
            }
            return string
        } else {
            guard let string = String(data: data, encoding: .utf8) else {
                let context = HTTPError.Context(request: request, response: response)
                let error = HTTPError.typeMismatch(
                    value: try? mapJSON(logSwitch: false),
                    targetType: String.self,
                    context: context
                )
                if logSwitch {
                    HTTPLogger.logFailure(.transform, error: error)
                }
                throw error
            }
            if logSwitch {
                HTTPLogger.logSuccess(.transform, urlRequest: request, data: string)
            }
            return string
        }
    }

    /// 将数据转换为 JSON 对象
    /// - Parameters:
    ///   - type: 映射对象类型
    ///   - keyPath: 从字典的中取出 `keyPath` 对应的值，用于映射数据
    ///   - decoder: JSON 解析器
    ///   - failsOnEmptyData: 错误时是否，返回一个 NSNull 对象
    /// - Throws: HTTPError
    /// - Returns: JSON 对象
    public func map<T>(
        _ type: T.Type,
        atKeyPath keyPath: String? = nil,
        using decoder: JSONDecoder = JSONDecoder(),
        failsOnEmptyData: Bool = true
    ) throws -> T where T: Decodable {

        let serializedData: Data?
        if let keyPath = keyPath, !keyPath.isEmpty {

            let value: Any
            do {
                value = try mapJSON(atKeyPath: keyPath, failsOnEmptyData: failsOnEmptyData, logSwitch: false)
            } catch let error as HTTPError {
                HTTPLogger.logFailure(.transform, error: error)
                throw error
            } catch { /// 此处错误抓取不会执行，此处仅保证 `mapJSON`方法抛出异常必定被捕捉到
                let context = HTTPError.Context(request: request, response: response, underlyingError: error)
                let error = HTTPError.typeMismatch(
                    value: try? mapJSON(logSwitch: false),
                    targetType: T.self,
                    context: context
                )
                HTTPLogger.logFailure(.transform, error: error)
                throw error
            }

            if JSONSerialization.isValidJSONObject(value) {
                do {
                    serializedData = try JSONSerialization.data(withJSONObject: value)
                } catch {
                    let context = HTTPError.Context(request: request, response: response, underlyingError: error)
                    let error = HTTPError.typeMismatch(
                        value: try? mapJSON(logSwitch: false),
                        targetType: T.self,
                        context: context
                    )
                    HTTPLogger.logFailure(.transform, error: error)
                    throw error
                }
            } else {
                let wrappedJSONObject = ["value": value]
                let wrappedJSONData = try JSONSerialization.data(withJSONObject: wrappedJSONObject)
                do {
                    let data = try decoder.decode(DecodableWrapper<T>.self, from: wrappedJSONData).value
                    HTTPLogger.logSuccess(.transform, urlRequest: request, data: data)
                    return data
                } catch {
                    let context = HTTPError.Context(request: request, response: response)
                    let error = HTTPError.typeMismatch(
                        value: try? mapJSON(logSwitch: false),
                        targetType: T.self,
                        context: context
                    )
                    HTTPLogger.logFailure(.transform, error: error)
                    throw error
                }
            }
        } else {
            serializedData = data
        }

        guard let serializedData = serializedData else {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.emptyResponse(context)
            HTTPLogger.logFailure(.transform, error: error)
            throw error
        }

        do {
            let decodable = try decoder.decode(T.self, from: serializedData)
            HTTPLogger.logSuccess(.transform, urlRequest: request, data: decodable)
            return decodable
        } catch {
            let context = HTTPError.Context(request: request, response: response)
            let error = HTTPError.typeMismatch(
                value: try? mapJSON(logSwitch: false),
                targetType: T.self,
                context: context
            )
            HTTPLogger.logFailure(.transform, error: error)
            throw error
        }
    }
}

// MARK: - DecodableWrapper

private struct DecodableWrapper<T: Decodable>: Decodable {
    let value: T
}

// MARK: - Result

public extension Result {

    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var isFailure: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }

    var error: Error? {
        switch self {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}
