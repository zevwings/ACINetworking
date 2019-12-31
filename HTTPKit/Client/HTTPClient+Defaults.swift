//
//  HTTPClient+Defaults.swift
//
//  Created by zevwings on 2019/1/24.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation

extension HTTPClient {

    /// 默认的Alamofire.Session
    public class func defaultSessionManager() -> SessionManager {

        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 30.0

        let delegate = SessionDelegate()
//        let rootQueue = DispatchQueue(label: "com.zevwings.httpkit.rootQueue")
//        let requestQueue = DispatchQueue(label: "com.zevwings.httpkit.requestQueue", target: rootQueue)
//        let serializationQueue = DispatchQueue(label: "com.zevwings.httpkit.serializationQueue", target: rootQueue)

        return SessionManager(
            configuration: configuration,
            delegate: delegate,
            serverTrustPolicyManager: nil
        )
    }
}
