//
//  Transformer.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

/// 将服务器数据转化模型为业务数据模型
///     示例
///     ```
///     public struct StandardTransformer : Transformer {
///
///         public func transform(_ data: Data?) throws -> Data? {
///
///             do {
///                 guard let data = data else {
///                     throw TransformerError.dataEmpty
///                 }
///
///                 let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
///
///                 guard
///                     let object = json as? [String: Any],
///                     let data = object["data"]
///                 else {
///                     throw TransformerError.dataMissing
///                 }
///
///                 guard JSONSerialization.isValidJSONObject(data) else {
///                     throw TransformerError.dataMissing
///                 }
///
///                 return try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
///             } catch {
///                 throw TransformerError.dataMissing
///             }
///         }
///     }
///     ```
///
public protocol Transformer {

    /// 将服务器返回数据转换为业务数据
    ///
    /// - Parameters:
    ///   - data: 转换前的数据
    ///   - request: 请求
    /// - Returns: 转换后的数据
    /// - Throws: 转换异常
    func transform(_ data: Data?) throws -> Data?

}
