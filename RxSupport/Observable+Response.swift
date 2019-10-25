//
//  Observable+Response.swift
//
//  Created by zevwings on 2019/9/11.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation
import RxSwift
#if !COCOAPODS
import HTTPKit
#endif

public extension ObservableType where Element == Response {

    func filter<R: RangeExpression>(statusCodes: R) -> Observable<Element> where R.Bound == Int {
        return flatMap { Observable.just(try $0.filter(statusCodes: statusCodes)) }
    }

    func filter(statusCode: Int) -> Observable<Element> {
        return flatMap { Observable.just(try $0.filter(statusCode: statusCode)) }
    }

    func filterSuccessfulStatusCodes() -> Observable<Element> {
        return flatMap { Observable.just(try $0.filterSuccessfulStatusCodes()) }
    }

    func filterSuccessfulStatusAndRedirectCodes() -> Observable<Element> {
        return flatMap { Observable.just(try $0.filterSuccessfulStatusAndRedirectCodes()) }
    }

    func mapImage() -> Observable<UIImage> {
        return flatMap { Observable.just(try $0.mapImage()) }
    }

    func mapJSON(failsOnEmptyData: Bool = true) -> Observable<Any> {
        return flatMap { Observable.just(try $0.mapJSON(failsOnEmptyData: failsOnEmptyData)) }
    }

    func mapString(atKeyPath keyPath: String? = nil) -> Observable<String> {
        return flatMap { Observable.just(try $0.mapString(atKeyPath: keyPath)) }
    }
}

public extension ObservableType where Element == ProgressResponse {

    func filterCompleted() -> Observable<Response> {
        return self
            .filter { $0.completed }
            .flatMap { progress -> Observable<Response> in
                switch progress.response {
                case .some(let response): return .just(response)
                case .none: return .empty()
                }
        }
    }

    func filterProgress() -> Observable<Double> {
        return self.filter { !$0.completed }.map { $0.progress }
    }
}
