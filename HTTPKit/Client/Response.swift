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
            HTTPLogger.failure(.verbose, error: error)
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
            let error = HTTPError.cast(
                value: data,
                targetType: Image.self,
                request: request,
                response: response
            )
            HTTPLogger.failure(.verbose, error: error)
            throw error
        }
        HTTPLogger.transform(.verbose, targetType: Image.self, request: request, extra: image)
        return image
    }

    func mapJSON(
        options: JSONSerialization.ReadingOptions = [.allowFragments],
        failsOnEmptyData: Bool = true,
        logVerbose: Bool = true
    ) throws -> Any {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: options)
            if logVerbose {
                HTTPLogger.transform(.verbose, targetType: Any.self, request: request, extra: jsonObject)
            }
            return jsonObject
        } catch {
            let error = HTTPError.cast(
                value: data,
                targetType: Image.self,
                request: request,
                response: response
            )
            HTTPLogger.failure(.verbose, error: error)
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw error
        }
    }

    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            guard
                let jsonDictionary = try mapJSON(logVerbose: false) as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                    let error = HTTPError.cast(
                        value: data,
                        targetType: String.self,
                        request: request,
                        response: response
                    )
                    HTTPLogger.failure(.verbose, error: error)
                    throw error
            }
            HTTPLogger.transform(.verbose, targetType: String.self, request: request, extra: string)
            return string
        } else {
            guard let string = String(data: data, encoding: .utf8) else {
                let error = HTTPError.cast(
                    value: data,
                    targetType: String.self,
                    request: request,
                    response: response
                )
                HTTPLogger.failure(.verbose, error: error)
                throw error
            }
            HTTPLogger.transform(.verbose, targetType: String.self, request: request, extra: string)
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
                    let jsonDictionary = try mapJSON(logVerbose: false) as? NSDictionary,
                    let jsonObject = jsonDictionary.value(forKeyPath: keyPath) else {
                        let error = HTTPError.cast(
                            value: data,
                            targetType: type,
                            request: request,
                            response: response
                        )
                        HTTPLogger.failure(.verbose, error: error)
                        throw error
                }
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                value = try decoder.decode(type, from: jsonData)
            } else {
                value = try decoder.decode(type, from: data)
            }
            HTTPLogger.transform(.verbose, targetType: type, request: request, extra: value)
            return value
        } catch {
            let error = HTTPError.cast(
                value: data,
                targetType: type,
                request: request,
                response: response
            )
            HTTPLogger.failure(.verbose, error: error)
            throw error
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
