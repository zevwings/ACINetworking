//
//  Paginator.swift
//  ACINetworking
//
//  Created by 张伟 on 2021/11/13.
//

import Foundation

/// 自动为网络接口参数进行分页
///
///     示例
///     ```
///     public final class Pager : Paginator {
///
///         public var totalCount: Int = 0
///         public var totalPage: Int = 0
///         public var currentPage: Int = 1
///
///         public var index: Int = 1
///         public var indexKey: String {
///             return "pageIndex"
///         }
///
///         public var count: Int { return 12 }
///         public var countKey: String {
///             return "pageSize"
///         }
///
///         @discardableResult public func reset() -> Int {
///             index = 1
///             return index
///         }
///
///         @discardableResult public func next() -> Int {
///             index += 1
///             return index
///         }
///
///         public func updateIndex(_ data: Data?) throws {
///
///             guard let data = data else { return }
///
///             let options: JSONSerialization.ReadingOptions = [
///                 .allowFragments,
///                 .mutableLeaves,
///                 .mutableContainers
///             ]
///
///             let json: [String: Any]?
///             do {
///                 json = try JSONSerialization.jsonObject(with: data, options: options) as? [String: Any]
///             } catch {
///                 throw HTTPError.external(error, request: nil, response: nil)
///             }
///
///             if let page = json?["page"] as? [String: Any],
///                let currentPage = page["currentPage"] as? Int,
///                let totalPage = page["totalPage"] as? Int,
///                let totalCount = page["totalPage"] as? Int {
///                 self.currentPage = currentPage
///                 self.totalPage = totalPage
///                 self.totalCount = totalCount
///             }
///
///             _ = next()
///         }
///     }
///     ```
///
public protocol Paginator {

    /// 当前页码
    var index: Int { get set }

    /// 页码对应的参数Key
    var indexKey: String { get }

    /// 每页数据数量，默认20
    var count: Int { get }

    /// 每页数据数量对应的Key
    var countKey: String { get }

    /// 重置下标
    func reset() -> Int

    /// 下一页
    func next() -> Int

    /// 更新分页索引下标
    func updateIndex(_ data: Data?) throws
}
