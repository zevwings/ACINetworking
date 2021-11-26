//
//  UserDefaults.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation

// MARK: - UserDefault

@propertyWrapper
public struct UserDefaults<T: Codable> {

    let key: String
    let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            return Foundation.UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            Foundation.UserDefaults.standard.set(newValue, forKey: key)
            Foundation.UserDefaults.standard.synchronize()
        }
    }
}
