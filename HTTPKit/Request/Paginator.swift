//
//  Paginator.swift
//
//  Created by zevwings on 2019/1/4.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

public protocol Paginator {

    /// 从返回值中获取数组元素对应的Key
    var elementKey: String { get }

    /// 当前页码，默认为0
    var index: Int { get set }

    /// 页码对应的参数Key，默认为`page`
    var indexKey: String { get }

    /// 每页数据数量，默认20
    var count: Int { get }

    /// 每页数据数量对应的Key，默认为`rows`
    var countKey: String { get }
}

// MARK: - Defaults

extension Paginator {

    public var index: Int { return 0 }

    public var indexKey: String { return "page" }

    public var count: Int { return 20 }

    public var countKey: String { return "rows" }
}

extension Paginator {

    /// 对返回数据进行转换，只对返回数据为JSON数据时有效
    mutating func transform(_ data: Data) throws -> Data {

        let options: JSONSerialization.ReadingOptions = [.allowFragments, .mutableLeaves, .mutableContainers]
        if let model = try JSONSerialization.jsonObject(with: data, options: options) as? NSDictionary,
            let elements = model.value(forKeyPath: elementKey) as? [[String: Any]] {
            if elements.count >= count {
                index += 1
            }
            return try JSONSerialization.data(withJSONObject: elements, options: .prettyPrinted)
        }
        return data
    }
}

// MARK: - Paginator

extension Request where Self : Paginator {

    public var paginator: Paginator? { return self }

}
