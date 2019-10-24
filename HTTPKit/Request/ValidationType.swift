//
//  ValidationType.swift
//
//  Created by zevwings on 2018/12/29.
//  Copyright © 2018 zevwings. All rights reserved.
//

import Foundation

// MARK: - ValidationType

public enum ValidationType {

    /// 不做校验
    case none
    /// 校验数据，成功code为2xx
    case successCodes
    /// 校验数据，成功code为2xx和3xx
    case successAndRedirectCodes
    /// 自定义校验成功Code
    case customCodes([Int])

    var statusCodes: [Int] {
        switch self {
        case .successCodes:
            return Array(200..<300)
        case .successAndRedirectCodes:
            return Array(200..<400)
        case .customCodes(let codes):
            return codes
        case .none:
            return []
        }
    }
}

extension ValidationType : Equatable {

    public static func == (lhs: ValidationType, rhs: ValidationType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.successCodes, .successCodes),
             (.successAndRedirectCodes, .successAndRedirectCodes):
            return true
        case (.customCodes(let code1), .customCodes(let code2)):
            return code1 == code2
        default:
            return false
        }
    }
}
