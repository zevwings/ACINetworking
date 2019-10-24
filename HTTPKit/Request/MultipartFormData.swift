//
//  MultipartFormData.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

public struct MultipartFormData {

    public enum MultipartFormDataType {
        case data(Foundation.Data)
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

// MARK: - Alamofire MultipartFormData

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
        append(stream,
               withLength: length,
               name: bodyPart.name,
               fileName: bodyPart.fileName ?? "",
               mimeType: bodyPart.mimeType ?? "")
    }

    func applyMoyaMultipartFormData(_ multipartBody: [MultipartFormData]) {
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
