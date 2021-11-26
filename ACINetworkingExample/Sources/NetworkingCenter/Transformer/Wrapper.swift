//
//  Wrapper.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking
import AnyCodable

struct Page : Codable {
    var currentPage : Int = 0
    var totalPage : Int = 0
    var totalCount : Int = 0
}

struct ResponseWrapper : Decodable {

    var code : String?
    var message: String?
    var page: Page?
    var data: AnyCodable?
}
