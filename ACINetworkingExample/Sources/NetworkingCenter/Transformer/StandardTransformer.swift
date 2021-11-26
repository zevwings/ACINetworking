//
//  StandardTransformer.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking

public enum TransformerError : Error {
    case dataEmpty
    case dataMissing
    case format(code: Int, message: String)
}

extension TransformerError : LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .dataEmpty:
            return "网络请求失败"
        case .dataMissing:
            return "服务器返回错误"
        case let .format(_, message):
            return message
        }
    }
}

/// 校验所有数据，必须有返回值，没有则报错
public struct StandardTransformer : Transformer {
        
    public static var standard  = StandardTransformer()

    public func transform(_ data: Data?) throws -> Data? {
        do {
            guard let data = data else {
                throw TransformerError.dataEmpty
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.mutableLeaves, .mutableContainers, .fragmentsAllowed]) as? [String: Any]
                guard let code = jsonObject?["code"] as? Int else {
                    throw TransformerError.dataMissing
                }

                guard code == 0 else {
                    var message = jsonObject?["message"] as? String ?? "服务器返回错误"
                    message = message.isEmpty ? "服务器返回错误" : message
                    throw TransformerError.format(code: code, message: message)
                }

                guard let data = jsonObject?["data"] else {
                    return nil
                }

                return try JSONSerialization.data(withJSONObject: data, options: [.fragmentsAllowed, .prettyPrinted, .sortedKeys])
            } catch {
                throw TransformerError.dataEmpty
            }
        } catch {
            throw error
        }
    }
}
