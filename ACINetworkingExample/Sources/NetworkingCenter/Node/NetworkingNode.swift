//
//  NetworkingNode.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking

public enum NetworkingNode {
    case `default`
}

extension NetworkingNode: Node {
    
    public var baseURL: URLConvertible {
        switch self {
        case .default:
            return "https://example.zevwings.com/api"
        }
    }
}
