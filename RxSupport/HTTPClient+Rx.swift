//
//  HTTPClient+Rx.swift
//
//  Created by zevwings on 2019/1/29.
//  Copyright © 2019 zevwings. All rights reserved.
//

import Foundation
import RxSwift
#if !COCOAPODS
import HTTPKit
#endif

extension HTTPClient: ReactiveCompatible {}

public extension Reactive where Base: Client {

    @discardableResult
    func request(
        _ request: Base.R,
        callbackQueue: DispatchQueue = .main
    ) -> Single<Response> {

        return Single.create(subscribe: { [weak base] single -> Disposable in

            let task = base?.request(
                request: request,
                callbackQueue: callbackQueue,
                progressHandler: nil,
                completionHandler: { result in
                    switch result {
                    case .success(let value):
                        single(.success(value))
                    case .failure(let error):
                        single(.error(error))
                    }
            })

            return Disposables.create {
                task?.cancel()
            }
        })
    }

    @discardableResult
    func requestWithProgress(
        _ request: Base.R,
        callbackQueue: DispatchQueue = .main
    ) -> Observable<ProgressResponse> {

        let progressHandler: (AnyObserver) -> (ProgressResponse) -> Void = { observer in
            return { progress in
                observer.onNext(progress)
            }
        }

        let response: Observable<ProgressResponse> = Observable.create { [weak base] observer in
            let task = base?.request(
                request: request,
                callbackQueue: callbackQueue,
                progressHandler: progressHandler(observer),
                completionHandler: { result in
                    switch result {
                    case .success:
                        observer.onCompleted()
                    case .failure(let error):
                        observer.onError(error)
                    }
            })

            return Disposables.create {
                task?.cancel()
            }
        }

        return response.scan(ProgressResponse(), accumulator: { (last, progress) in
            let progressObject = progress.progressObject ?? last.progressObject
            let response = progress.response ?? last.response
            return ProgressResponse(progress: progressObject, response: response)
        })
    }
}
