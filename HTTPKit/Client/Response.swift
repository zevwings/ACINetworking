//
//  Response.swift
//
//  Created by zevwings on 2019/1/4.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

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
            throw HTTPError.statusCode(request: request, statustCode: statusCode)
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

    func mapImage() throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw HTTPError.cast(value: data, targetType: UIImage.self)
        }
        return image
    }

    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.count < 1 && !failsOnEmptyData {
                return NSNull()
            }
            throw HTTPError.cast(value: data, targetType: Any.self)
        }
    }

    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                    throw HTTPError.cast(value: data, targetType: String.self)
            }
            return string
        } else {
            guard let string = String(data: data, encoding: .utf8) else {
                throw HTTPError.cast(value: data, targetType: String.self)
            }
            return string
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
