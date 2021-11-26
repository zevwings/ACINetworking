//
//  Content.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

/// 请求内容
///
/// - requestPlain 无参数请求
/// - requestData 参数请求
/// - requestParameters: 普通请求
/// - download: 下载文件
/// - downloadParameters: 带参数的文件下载
/// - uploadFile: 上传文件
/// - uploadFormData: 上传`MultipartFormData`
/// - uploadFormDataParameters: 带参数的文件上传`MultipartFormData`
public enum Content {

    /// 无参数请求
    case requestPlain
    /// 有参数请求，直接设置 htttp body
    case requestData(Data)
    /// 有参数请求
    case requestParameters(parameters: Parameters)
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

// MARK: - MultipartFormData

/// `Mutilpart` 上传包装，将需要上传的内容封装到 `MultipartFormData` 对象中
///     示例
///     ```
///     let formData = MultipartFormData(
///         .data(data),
///         name: "file",
///         fileName: "file",
///         mimeType: "image/jpeg"
///     )
///     ```
///
public struct MultipartFormData {

    public enum MultipartFormDataType {
        case data(Data)
        case file(URL)
        case stream(InputStream, UInt64)
    }

    public let formDataType: MultipartFormDataType
    public let name: String
    public let fileName: String?
    public let mimeType: String?

    public init(
        _ formDataType: MultipartFormDataType,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.formDataType = formDataType
        self.name = name
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: - RequestMultipartFormData

extension RequestMultipartFormData {

    func append(
        data: Data,
        bodyPart: MultipartFormData
    ) {
        if let mimeType = bodyPart.mimeType {
            if let fileName = bodyPart.fileName {
                append(data, withName: bodyPart.name, fileName: fileName, mimeType: mimeType)
            } else {
                append(data, withName: bodyPart.name, mimeType: mimeType)
            }
        } else {
            append(data, withName: bodyPart.name)
        }
    }

    func append(
        fileURL url: URL,
        bodyPart: MultipartFormData
    ) {
        if let fileName = bodyPart.fileName, let mimeType = bodyPart.mimeType {
            append(url, withName: bodyPart.name, fileName: fileName, mimeType: mimeType)
        } else {
            append(url, withName: bodyPart.name)
        }
    }

    func append(
        stream: InputStream,
        length: UInt64,
        bodyPart: MultipartFormData
    ) {
        append(
            stream,
            withLength: length,
            name: bodyPart.name,
            fileName: bodyPart.fileName ?? "",
            mimeType: bodyPart.mimeType ?? ""
        )
    }

    func applyMultipartFormData(_ multipartBody: [MultipartFormData]) {
        multipartBody.forEach { bodyPart in
            switch bodyPart.formDataType {
            case .data(let data):
                append(data: data, bodyPart: bodyPart)
            case .file(let url):
                append(fileURL: url, bodyPart: bodyPart)
            case .stream(let stream, let length):
                append(stream: stream, length: length, bodyPart: bodyPart)
            }
        }
    }
}
