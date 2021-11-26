//
//  ApplicationContext.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation

public final class ApplicationContext: NSObject {
    
    public static let shared = ApplicationContext()
    
    @UserDefaults("com.zevwings.example.token", defaultValue: "")
    public var token: String
    
    private override init() {
        super.init()
    }
    
}

