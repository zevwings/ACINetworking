//
//  Single+Response.swift
//
//  Created by zevwings on 2019/9/11.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation
import RxSwift
#if !COCOAPODS
import HTTPKit
#endif

public extension PrimitiveSequence where Trait == SingleTrait, Element == Response {

    func filter<R: RangeExpression>(statusCodes: R) -> Single<Element> where R.Bound == Int {
        return flatMap { .just(try $0.filter(statusCodes: statusCodes)) }
    }

    func filter(statusCode: Int) -> Single<Element> {
        return flatMap { .just(try $0.filter(statusCode: statusCode)) }
    }

    func filterSuccessfulStatusCodes() -> Single<Element> {
        return flatMap { .just(try $0.filterSuccessfulStatusCodes()) }
    }

    func filterSuccessfulStatusAndRedirectCodes() -> Single<Element> {
        return flatMap { .just(try $0.filterSuccessfulStatusAndRedirectCodes()) }
    }

    func mapImage() -> Single<UIImage> {
        return flatMap { .just(try $0.mapImage()) }
    }

    func mapJSON(failsOnEmptyData: Bool = true) -> Single<Any> {
        return flatMap { .just(try $0.mapJSON(failsOnEmptyData: failsOnEmptyData)) }
    }

    func mapString(atKeyPath keyPath: String? = nil) -> Single<String> {
        return flatMap { .just(try $0.mapString(atKeyPath: keyPath)) }
    }
}
