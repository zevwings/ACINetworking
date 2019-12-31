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

public extension Response {

    func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            let error = HTTPError.statusCode(request: request, statustCode: statusCode)
            logVerbose(isFailure: true, value: nil, error: error)
            throw error
        }
        return self
    }

    func filter(statusCode: Int) throws -> Response {
        return try filter(statusCodes: statusCode...statusCode)
    }

    func filterSuccessfulStatusCodes() throws -> Response {
        return try filter(statusCodes: 200...299)
    }

    func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        return try filter(statusCodes: 200...399)
    }

    func mapImage() throws -> Image {
        guard let image = Image(data: data) else {
            let error = HTTPError.cast(value: data, targetType: Image.self)
            logVerbose(isFailure: true, value: nil, error: error)
            throw error
        }
        logVerbose(isFailure: false, value: image, error: nil)
        return image
    }

    func mapJSON(
        options: JSONSerialization.ReadingOptions = [.allowFragments],
        failsOnEmptyData: Bool = true
    ) throws -> Any {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: options)
            logVerbose(isFailure: false, value: jsonObject, error: nil)
            return jsonObject
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            let error = HTTPError.cast(value: data, targetType: Any.self)
            logVerbose(isFailure: true, value: nil, error: error)
            throw error
        }
    }

    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            guard
                let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String
                else {
                    let error = HTTPError.cast(value: data, targetType: String.self)
                    logVerbose(isFailure: true, value: nil, error: error)
                    throw error
            }
            logVerbose(isFailure: false, value: string, error: nil)
            return string
        } else {
            guard
                let string = String(data: data, encoding: .utf8)
                else {
                    let error = HTTPError.cast(value: data, targetType: String.self)
                    logVerbose(isFailure: true, value: nil, error: error)
                    throw error
            }
            logVerbose(isFailure: false, value: string, error: nil)
            return string
        }
    }

    func mapObject<C: Codable>(
        to type: C.Type,
        decoder: JSONDecoder = JSONDecoder(),
        atKeyPath keyPath: String? = nil
    ) throws -> C {
        do {
            var value: C
            if let keyPath = keyPath {
                guard
                    let jsonDictionary = try mapJSON() as? NSDictionary,
                    let jsonObject = jsonDictionary.value(forKeyPath: keyPath)
                    else {
                        let error = HTTPError.cast(value: data, targetType: type)
                        logVerbose(isFailure: true, value: nil, error: error)
                        throw error
                }
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                value = try decoder.decode(type, from: jsonData)
            } else {
                value = try decoder.decode(type, from: data)
            }
            logVerbose(isFailure: false, value: value, error: nil)
            return value
        } catch {
            let error = HTTPError.cast(value: data, targetType: type)
            logVerbose(isFailure: true, value: nil, error: error)
            throw error
        }
    }
}

extension Response {

    private func logVerbose(isFailure: Bool, value: Any?, error: Error?) {
        if let value = value, !isFailure {
            HTTPKit.logVerbose(
                """
                ============================================================
                "数据解析成功"
                url : \( request?.url?.relativeString ?? "")
                response: \(value)
                ============================================================
                """
            )
        } else {
            HTTPKit.logVerbose(String(describing: error?.localizedDescription))
        }
    }
}

public struct ProgressResponse {

    public let response: Response?
    public let progressObject: Progress?

    public init(progress: Progress? = nil, response: Response? = nil) {
        self.progressObject = progress
        self.response = response
    }

    public var progress: Double {
        if completed {
            return 1.0
        } else if let progressObject = progressObject, progressObject.totalUnitCount > 0 {
            return progressObject.fractionCompleted
        } else {
            return 0.0
        }
    }

    public var completed: Bool {
        return response != nil
    }
}
