//
//  Response+HandyJSON.swift
//
//  Created by zevwings on 2019/9/10.
//  Copyright © 2019 zevwings. All rights reserved.
//

import HandyJSON
#if !COCOAPODS
import HTTPKit
#endif

public extension Response {

    func mapObject<T: HandyJSON>(
        _ type: T.Type,
        atKeyPath keyPath: String? = nil
    ) throws -> T {

        guard let json = try value(for: keyPath) as? [String: Any] else {
            throw HTTPError.cast(value: data, targetType: [[String: Any]].self)
        }

        guard let result = T.deserialize(from: json) else {
            throw HTTPError.cast(value: json, targetType: T.self)
        }

        return result
    }

    func mapArray<T: HandyJSON>(
        _ type: T.Type,
        atKeyPath keyPath: String? = nil
    ) throws -> [T] {

        guard let array = try value(for: keyPath) as? [[String: Any]] else {
            throw HTTPError.cast(value: data, targetType: [[String: Any]].self)
        }

        guard let result = [T].deserialize(from: array) as? [T] else {
            throw HTTPError.cast(value: array, targetType: [T].self)
        }

        return result
    }

    func value(for keyPath: String?) throws -> Any? {
        if let keyPath = keyPath {
            return (try mapJSON() as? NSDictionary)?.value(forKeyPath: keyPath)
        } else {
            return try mapJSON()
        }
    }
}
