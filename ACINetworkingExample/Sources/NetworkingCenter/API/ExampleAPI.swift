//
//  ExampleAPI.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import Foundation
import ACINetworking

enum ExampleAPI {

    case verifyCode(String)

    case smsLogin(telno: String, code: String, invitationCode: String?)
    
    case userInfo
}

extension ExampleAPI : ApiManager {

    var node: NetworkingNode {
        return .default
    }

    var route: Route {
        switch self {
        case let .verifyCode(telno):
            return .get("login/\(telno)")
        case .smsLogin:
            return .post("login/verifycode")
        case .userInfo:
            return .get("account/info")
        }
    }

    var content: Content {
        switch self {
        case .verifyCode:
            return .requestPlain
        case let .smsLogin(telno, code, invitationCode):
            var parameters: [String: Any] = [:]
            parameters["phone"] = telno
            parameters["smsCode"] = code
            parameters["clientType"] = "ios"
            parameters["invitationCode"] = invitationCode
            return .requestParameters(parameters: JSONEncoding() => parameters)
        case .userInfo:
            return .requestPlain
        }
    }
    
    var transformer: Transformer? {
        return StandardTransformer.standard
    }
}

// MARK: - Service

final class ExampleService {
    
    typealias API = ExampleAPI

    static let shared = ExampleService()

    let client = HTTPClient<API>(session: .default, plugins: [OSTypePlugin()])
    
    @discardableResult func request(
        api: API,
        callbackQueue: DispatchQueue = .main,
        progressHandler: ((ProgressResponse) -> Void)? = nil,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> TaskType? {
        return client.request(
            api: api,
            callbackQueue: callbackQueue,
            progressHandler: progressHandler,
            completionHandler: completionHandler
        )
    }
}
