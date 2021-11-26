//
//  Parameters.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

///
/// `AnyEncodable` 类型将的真实类型进行包装
/// 对值类型消除，隐藏其真实的类型
///
///     let dictionary: [String: Encodable] = [
///         "boolean": true,
///         "integer": 42,
///         "double": 3.141592653589793,
///         "string": "string",
///         "array": [1, 2, 3],
///         "nested": [
///             "a": "alpha",
///             "b": "bravo",
///             "c": "charlie"
///         ],
///         "null": nil
///     ]
///
///     let encoder = JSONEncoder()
///     let json = try! encoder.encode(dictionary)
///
public struct AnyEncodable: Encodable {

    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

/// 将参数解码方式和参数同时封装到 `Parameters` 对象中
/// `Parameters` 拥有一个参数解码方式和值，使用`=>` 操作符进行操作
///
///     示例:
///     ```
///     JSONEncoding() => [
///         "key1": "value1",
///         "key2": "value2",
///         "key3": nil,      // will be ignored
///     ]
///     ```
public struct Parameters {

    public let encoding: ParameterEncoding
    public let values: [String: Any]

    public init(encoding: ParameterEncoding, dictionary: [String: Any?]) {
        /// 设置参数解码方式
        self.encoding = encoding
        /// 过滤参数，保证参数非空
        var newDictionary: [String: Any] = [:]
        for (key, value) in dictionary {
            guard let value = value else { continue }
            newDictionary[key] = value
        }
        self.values = newDictionary
    }
}

// MARK: - Operator => 

infix operator =>

/// 将操作符右边的字典包装为`Parameters`对象
///
///     示例 1:
///     ```
///     JSONEncoding() => [
///         "key1": "value1",
///         "key2": "value2",
///         "key3": nil,      // will be ignored
///     ]
///     ```
///
public func => (encoding: ParameterEncoding, values: [String: Any?]) -> Parameters {
    return Parameters(encoding: encoding, dictionary: values)
}

/// 将操作符右边的字典包装为`Parameters`对象
///
///     示例 1:
///     ```
///     struct User: Encodable {
///         let name: String
///     }
///
///     let user = User(name: "zevwings")
///
///     JSONEncoding() => user
///     ```
///
public func => (encoding: ParameterEncoding, encodable: Encodable) -> Parameters {

    var values: [String: Any?] = [:]
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(AnyEncodable(encodable))
        if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any?] {
            values = json
        }
    } catch {
        HTTPLogger.logError("\(encodable) 转换为请求参数失败")
    }

    return Parameters(encoding: encoding, dictionary: values)
}
