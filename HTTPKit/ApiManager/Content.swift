//
//  Content.swift
//
//  Created by zevwings on 2019/1/3.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

/// 请求内容
///
/// - requestPlain 无参数请求
/// - requestParameters: 普通请求
/// - download: 下载文件
/// - downloadParameters: 带参数的文件下载
/// - uploadFile: 上传文件
/// - uploadFormData: 上传`MultipartFormData`
/// - uploadFormDataParameters: 带参数的文件上传`MultipartFormData`
public enum Content {

    /// 无参数请求
    case requestPlain

    /// 有参数请求
    case requestParameters(parameters: Parameters)

//    /// 使用 `Encodable` 参数请求
//    case requestJSONEncodable(Encodable)
//
//    /// 使用自定义 `Encodable` 参数请求
//    case requestCustomJSONEncodable(Encodable, encoder: JSONEncoder)

    /// 无参数下载请求
    case download(destination: Destination?)

    /// 有参数下载请求
    case downloadParameters(destination: Destination?, parameters: Parameters)

    /// 上传文件请求
    case uploadFile(fileURL: URL)

    /// 无参数Mutipart上传请求
    case uploadFormData(mutipartFormData: [MultipartFormData])

    /// 有参数Mutipart上传请求
    case uploadFormDataParameters(mutipartFormData: [MultipartFormData], parameters: Parameters)
}

extension Content {

    var parameters: Parameters? {
        switch self {
        case let .requestParameters(parameters):
            return parameters
        case let .downloadParameters(_, parameters):
            return parameters
        case let .uploadFormDataParameters(_, parameters):
            return parameters
        default:
            return nil
        }
    }
}

//struct AnyEncodable: Encodable {
//
//    private let encodable: Encodable
//
//    public init(_ encodable: Encodable) {
//        self.encodable = encodable
//    }
//
//    func encode(to encoder: Encoder) throws {
//        try encodable.encode(to: encoder)
//    }
//}
//
//
//extension URLRequest {
//
//    mutating func encoded(encodable: Encodable, encoder: JSONEncoder = JSONEncoder()) throws -> URLRequest {
//        do {
//            let encodable = AnyEncodable(encodable)
//            httpBody = try encoder.encode(encodable)
//
//            let contentTypeHeaderName = "Content-Type"
//            if value(forHTTPHeaderField: contentTypeHeaderName) == nil {
//                setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
//            }
//
//            return self
//        } catch {
//            throw MoyaError.encodableMapping(error)
//        }
//    }
//
//    func encoded(parameters: [String: Any], parameterEncoding: ParameterEncoding) throws -> URLRequest {
//        do {
//            return try parameterEncoding.encode(self, with: parameters)
//        } catch {
//            throw MoyaError.parameterEncoding(error)
//        }
//    }
//}
