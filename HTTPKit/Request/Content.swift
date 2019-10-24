//
//  Content.swift
//
//  Created by zevwings on 2019/1/3.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

public typealias Parameters = [String: Any]

/// 参数格式化类型，根据格式化类型选取`Alamofire`的`ParameterEncoding`
public enum ParameterFormatter {
    case url
    case json
}

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
    case requestParameters(parameters: Parameters, formatter: ParameterFormatter)

    /// 无参数下载请求
    case download(destination: Destination?)

    /// 有参数下载请求
    case downloadParameters(parameters: Parameters, formatter: ParameterFormatter, destination: Destination?)

    /// 上传文件请求
    case uploadFile(fileURL: URL)

    /// 无参数Mutipart上传请求
    case uploadFormData(mutipartFormData: [MultipartFormData])

    /// 有参数Mutipart上传请求
    // swiftlint:disable:next line_length
    case uploadFormDataParameters(parameters: Parameters, formatter: ParameterFormatter, mutipartFormData: [MultipartFormData])
}

extension Content {

    var parameters: Parameters? {
        switch self {
        case .requestParameters(let parameters, _):
            return parameters
        case .downloadParameters(let parameters, _, _):
            return parameters
        case .uploadFormDataParameters(let parameters, _, _):
            return parameters
        default:
            return nil
        }
    }

    var encoding: ParameterEncoding? {
        switch self {
        case .requestParameters(_, let formatter):
            return encoding(for: formatter)
        case .downloadParameters(_, let formatter, _):
            return encoding(for: formatter)
        case .uploadFormDataParameters(_, let formatter, _):
            return encoding(for: formatter)
        default:
            return nil
        }
    }

    private func encoding(for formatter: ParameterFormatter) -> ParameterEncoding {
        switch formatter {
        case .json:
            return JSONEncoding.default
        case .url:
            return URLEncoding.default
        }
    }
}
