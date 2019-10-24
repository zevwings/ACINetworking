//
//  Observable+HandyJSON.swift
//
//  Created by zevwings on 2019/9/10.
//  Copyright © 2019 zevwings. All rights reserved.
//

import RxSwift
import HandyJSON
#if !COCOAPODS
import HTTPKit
#endif

public extension ObservableType where Element == Response {

    func mapObject<T: HandyJSON>(_ type: T.Type, atKeyPath keyPath: String? = nil) -> Observable<T> {
        return flatMap { response -> Observable<T> in
            return Observable.just(try response.mapObject(type, atKeyPath: keyPath))
        }
    }

    func mapArray<T: HandyJSON>(_ type: T.Type, atKeyPath keyPath: String? = nil) -> Observable<[T]> {
        return flatMap { response -> Observable<[T]> in
            return Observable.just(try response.mapArray(type, atKeyPath: keyPath))
        }
    }
}
