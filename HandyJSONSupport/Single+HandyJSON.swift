//
//  Single+HandyJSON.swift
//
//  Created by zevwings on 2019/9/10.
//  Copyright © 2019 zevwings. All rights reserved.
//

import RxSwift
import HandyJSON
#if !COCOAPODS
import HTTPKit
#endif

public extension PrimitiveSequence where Trait == SingleTrait, Element == Response {

    func mapObject<T: HandyJSON>(_ type: T.Type, atKeyPath keyPath: String? = nil) -> Single<T> {
        return flatMap { response -> Single<T> in
            return Single.just(try response.mapObject(type, atKeyPath: keyPath))
        }
    }

    func mapArray<T: HandyJSON>(_ type: T.Type, atKeyPath keyPath: String? = nil) -> Single<[T]> {
        return flatMap { response -> Single<[T]> in
            return Single.just(try response.mapArray(type, atKeyPath: keyPath))
        }
    }
}
