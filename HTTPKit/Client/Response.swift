//
//  Response.swift
//
//  Created by zevwings on 2019/1/4.
//  Copyright © 2019 zevwings. All rights reserved.
//

#if os(macOS)
import AppKit
public typealias Image = NSImage
#else
import UIKit
public typealias Image = UIImage
#endif

// MARK: - ProgressResponse

public enum ProgressResponse {
    case progress(Progress)
    case completed(Result<Response, HTTPError>)
}

public extension ProgressResponse {

    var isCompleted: Bool {
        switch self {
        case .progress:
            return false
        case .completed:
            return true
        }
    }

    var progress: Double {
        switch self {
        case let .progress(value):
            return value.fractionCompleted
        case .completed:
            return 1.0
        }
    }

    var response: Response? {
        switch self {
        case .progress:
            return nil
        case let .completed(result):
            return try? result.get()
        }
    }

    var error: Error? {
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
    public private(set) var data: Data
    public let statusCode: Int

    public init (request: URLRequest?, response: HTTPURLResponse?, data: Data ) {
        self.request = request
        self.response = response
        self.data = data
        self.statusCode = response?.statusCode ?? Int.min
    }

    public func update(_ data: Data) {
        self.data = data
    }
}

extension Response : CustomDebugStringConvertible {

    public var description: String {
        return "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    public var debugDescription: String {
        return description
    }
}

extension Response : Equatable {

    public static func == (lhs: Response, rhs: Response) -> Bool {
        return lhs.statusCode == rhs.statusCode
            && lhs.data == rhs.data
            && lhs.response == rhs.response
    }
}

// MAKR: - Filter

public extension Response {

    ///  过滤 Status Code 如果不为指定范围的 Code 时抛出异常
    /// - Throws: HttpError
    /// - Returns: 当前 Response
    func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            let error = HTTPError.statusCode(request: request, statustCode: statusCode)
            throw error
        }
        return self
    }

    ///  过滤 Status Code 如果不为指定的 Code 时抛出异常
    /// - Throws: HttpError
    /// - Returns: 当前 Response
    func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    ///  过滤 Status Code 如果不为正确的 Code 时抛出异常
    /// - Throws: HttpError
    /// - Returns: 当前 Response
    func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    ///  过滤 Status Code 如果不为正确或重定向 Code 时抛出异常
    /// - Throws: HttpError
    /// - Returns: 当前 Response
    func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }
}

// MARK: - Mapping

public extension Response {

    ///  将数据转换为图片
    /// - Throws: HttpError
    /// - Returns: 图片对象
    func mapImage() throws -> Image {
        guard let image = Image(data: data) else {
            throw HTTPError.cast(value: data, targetType: Image.self, request: request, response: response)
        }
        return image
    }

    /// 将数据转换为 JSON 对象
    /// - Parameters:
    ///   - options: JSONSerialization.ReadingOptions
    ///   - failsOnEmptyData: 错误时是否，返回一个 NSNull 对象
    ///   - logVerbose: 是否打印日志，避免多次打印
    /// - Throws: HTTPError
    /// - Returns: JSON 对象
    func mapJSON(
        options: JSONSerialization.ReadingOptions = [.allowFragments],
        failsOnEmptyData: Bool = true
    ) throws -> Any {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: options)
            return jsonObject
        } catch {
            let error = HTTPError.cast(value: data, targetType: Any.self, request: request, response: response)
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw error
        }
    }

    /// 将数据转换为字符串
    /// - Parameter keyPath: KeyPath
    /// - Throws: HttpError
    /// - Returns: 字符串
    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            let jsonDictionary = try mapJSON() as? NSDictionary
            guard let string = jsonDictionary?.value(forKeyPath: keyPath) as? String else {
                throw HTTPError.cast(value: data, targetType: String.self, request: request, response: response)
            }
            return string
        } else {
            guard let string = String(data: data, encoding: .utf8) else {
                throw HTTPError.cast(value: data, targetType: String.self, request: request, response: response)
            }
            return string
        }
    }
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
