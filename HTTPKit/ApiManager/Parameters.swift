//
//  Parameters.swift
//  HTTPClient
//
//  Created by zevwings on 2020/8/17.
//  Copyright © 2020 zevwings. All rights reserved.
//

import Foundation

// MARK: - AnyEncodable

private struct AnyEncodable: Encodable {

    let value: Encodable

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

// MARK: - Parameters

/// `Parameters` 拥有一个参数解码方式和值，使用`=>` 操作符进行操作
///
/// 示例:
///
/// ```
/// JSONEncoding() => [
///   "key1": "value1",
///   "key2": "value2",
///   "key3": nil,      // will be ignored
/// ]
/// ```
public struct Parameters {

    public var encoding: ParameterEncoding
    public var values: [String: Any]

    public init(encoding: ParameterEncoding, values: [String: Any?]) {
        self.encoding = encoding
        self.values = filterNil(values)
    }
}

extension Parameters: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any?)...) {
        var values: [String: Any?] = [:]
        for (key, value) in elements {
            values[key] = value
        }
        self.init(encoding: URLEncoding(), values: values)
    }

    public func encode(urlRequest: URLRequest) throws -> URLRequest {
        return try encoding.encode(urlRequest, with: values)
    }
}

/// Returns a new dictinoary by filtering out nil values.
private func filterNil(_ dictionary: [String: Any?]) -> [String: Any] {
    var newDictionary: [String: Any] = [:]
    for (key, value) in dictionary {
        guard let value = value else { continue }
        newDictionary[key] = value
    }
    return newDictionary
}

// MARK: - 参数转换操作符

infix operator =>

/// 将操作符右边的字典包装为`Parameters`对象
/// 示例 1:
///
/// ```
/// JSONEncoding() => [
///   "key1": "value1",
///   "key2": "value2",
///   "key3": nil,      // will be ignored
/// ]
/// ```
public func => (encoding: ParameterEncoding, values: [String: Any?]) -> Parameters {
    return Parameters(encoding: encoding, values: values)
}

/// 将操作符右边的字典包装为`Parameters`对象
/// 示例 1:
///
/// ```
/// struct User : Encodable {
///     let name: String
/// }
///
/// let user = User(name: "zevwings")
///
/// JSONEncoding() => user
/// ```
public func => (encoding: ParameterEncoding, encodable: Encodable) -> Parameters {

    var values: [String: Any?] = [:]
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(AnyEncodable(value: encodable))
        if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any?] {
            values = json
        }
    } catch {
        HTTPLogger.log(.error, items: "\(encodable) 转换为请求参数失败")
    }

    return Parameters(encoding: encoding, values: values)
}
