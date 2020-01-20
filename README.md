# HTTPKit

![](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)[](https://github.com/Carthage/Carthage)
![](https://img.shields.io/badge/CocoaPods-1.6.1-4BC51D.svg?style=flat)[](https://cocoapods.org)
![](https://img.shields.io/badge/SPM-compatible-4BB32E.svg)[](https://swift.org/package-manager/)
![](https://img.shields.io/badge/Platform-iOS-4BB32E.svg)
![](https://img.shields.io/badge/License-MIT-4BC51D.svg)
![](https://img.shields.io/badge/swift-5.1-4BC51D.svg)
<br/>

[HTTPKit](https://github.com/zevwings/HTTPKit)是基于`Alamofire`的网络抽象层，它可以帮助我们规范`Alamofire`的网络请求。`HTTPKit`充分的封装了`Alamofire`网络请求的细节，你可以通过`HTTPKit`使用到所有`Alamofire`的功能。
项目主要分为`Serviceable`, `Request`, `Constructor`, `Client`, `Task`, `Transformer`, `Plugin`这七个模块，他们会帮助我们处理网络请求，分别在不同的阶段帮助我们处理网络请求。

## Usage

##### Serviceable

实现服务器网络请求封装

```
public enum NetwrokService : String {
    case api
    case auth
}

extension NetwrokService: Serviceable {

    public var baseUrl: String {
        switch self {
        case .api:
                return "https://api.base.com"
        case .auth
                return "https://auth.base.com"
        }
    }
}
```

### Request

``` swift
enum MessageCenter {

    /// 主面板
    case board(String)
    case content(String, paginator: Paginator)
}

extension MessageCenter : Request {

    typealias Service = NetwrokService

    /// 基础路径
    var service: Service {
        return .message
    }

        /// 请求路由
    var route: Route {
        switch self {
        case .board:
            return .post("message/board")
        case .content:
            return .post("message/content")
        }
    }

    /// 请求内容
    var content: Content {
        switch self {
        case .board(let type):
            var parameters: [String: String] = [:]
            ...
            return .requestParameters(formatter: .json, parameters: parameters)
        case .content(let messageType, _):
            var parameters: [String: String] = [:]
            ...
            return .requestParameters(formatter: .json, parameters: parameters)
        }
    }

        /// 分页控制器
    var paginator: Paginator? {
        switch self {
        case .content(_, let paginator):
            return paginator
        default:
            return nil
        }
    }

    /// 数据转换器
    var transformer: Transformer? {
        return BasicTransformer()
    }
}

```

### Client 

用于发起网络请求

```swift
let client = HTTPClient<MessageCenter>()
client.request(request: .board("messageTyp")) { result in
    switch result {
    case .success(let response):
        break
    case .failure(let error):
        break
    }
}
```
使用 RxSwift
```swift
client.rx.request(.board(messageType))
    .mapJSON()
    .subscribe(onSuccess: { json in

    }, onError: { error in

    })
```

### Response

用于处理返回结果

```swift
do {
    try response.mapJSON()
} catch {

}
```



## Introduction

### Serviceable
`Serviceable`是对服务器的封装，在我们开发过程中可能会涉及多个`baseUrl`，我们可以通过`Serviceable` 来封装。

```swift
public protocol Serviceable {

    /// 服务器基础路径
    var baseUrl: String { get }
}
```

### Request

`Request`它封装了一组类似的网络请求，这是一个抽象的协议，它包含了我们需要访问的网络服务节点，网络请求内容、参数以及请求头，他可以预定义处理的返回校验

```swift
public protocol Request {

    /// 服务器
    associatedtype Service: Serviceable

    /// 基础路径
    var service: Service { get }

    /// 请求路径
    var route: Route { get }

    /// 请求内容
    var content: Content { get }

    /// 请求头设置，默认为空
    var headerFields: [String: String] { get }

    /// 校验类型，校验返回的 status code 是否为正确的值，默认校验正确和重定向code
    var validationType: ValidationType { get }

    /// 请求拦截器
    var interceptor: RequestInterceptor? { get }

    /// 分页参数
    var paginator: Paginator? { get }

    /// 数据转换器，默认为`nil`
    var transformer: Transformer? { get }

}
```

### Content 
`Content`是对网络请求内容的封装，通过`Enum`的形式封装了一组通用的请求参数，请求参数解析及`MultipartFormData`的请求体。
```swift
/// 请求内容
///
/// - requestPlain 无参数请求
/// - requestParameters: 普通请求
/// - download: 下载文件
/// - downloadParameters: 带参数的文件下载
/// - uploadFile: 上传文件
/// - uploadFormData: 上传`MultipartFormData`
/// - uploadFormDataParameters: 带参数的文件上传`MultipartFormData`
public enum Content {

    /// 参数格式化类型，根据格式化类型选取`Alamofire`的`ParameterEncoding`
    public enum ParameterFormatter {
        case url
        case json
        case custom(ParameterEncoding)
    }

    /// 无参数请求
    case requestPlain

    /// 有参数请求
    case requestParameters(formatter: ParameterFormatter, parameters: Parameters)

    /// 无参数下载请求
    case download(destination: Destination?)

    /// 有参数下载请求
    case downloadParameters(formatter: ParameterFormatter, parameters: Parameters, destination: Destination?)

    /// 上传文件请求
    case uploadFile(fileURL: URL)

    /// 无参数Mutipart上传请求
    case uploadFormData(mutipartFormData: [MultipartFormData])

    /// 有参数Mutipart上传请求
    // swiftlint:disable:next line_length
    case uploadFormDataParameters(formatter: ParameterFormatter, parameters: Parameters, mutipartFormData: [MultipartFormData])
}
```

### Route
`Route`参考自`MoyaSurge`，以 `HTTPMethod(URLString)` 的形式使请求内容更简单，更简约。

```swift
public enum Route {
    case get(String)
    case post(String)
    case put(String)
    case delete(String)
    case options(String)
    case head(String)
    case patch(String)
    case trace(String)
    case connect(String)
}
```

### Client 
`Client`是网络请求客户端的抽象，用于统一发起网络请求

```swift
public protocol Client : AnyObject {

    // swiftlint:disable:next type_name
    associatedtype R: Request

    /// 发送一个网络请求
    ///
    /// - Parameters:
    ///   - request: Requestable
    ///   - callbackQueue: 回调线程
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 进度回调
    /// - Returns: 请求任务
    func request(
        request: R,
        callbackQueue: DispatchQueue,
        progressHandler: ((ProgressResponse) -> Void)?,
        completionHandler: @escaping (Result<Response, HTTPError>) -> Void
    ) -> Task?
}
```

### Builder
`Builder` 是网络请求构建器，从`Request`构建可用的`Alamofire.Request`

```swift
public protocol Builder {

    /// 处理`Request`，将`Request`处理构建成一个`Alamofire.Request`
    func process<R>(request: R, manager: SessionManager, plugins: [PluginType]) throws -> Requestable where R: Request
}
```

### Response
`Response`是对返回数据的封装，包含`URLRequest`，`HTTPURLResponse`以及返回数据的`Data`和`Status Code`。

```swift
public final class Response {

    public let request: URLRequest?
    public let response: HTTPURLResponse?
    public private(set) var data: Data
    public let statusCode: Int

    ...
}
```

## Requirements

- iOS 9.0+ 
- Swift 5.0

## Installation
### Cocoapod
[CocoaPods](https://cocoapods.org) is a dependency manager for Swift and Objective-C Cocoa projects.
<br/>

You can install Cocoapod with the following command

```
$ sudo gem install cocoapods
```
To integrate `HTTPKit` into your project using CocoaPods, specify it into your `Podfile`

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

target 'TargetName' do
    use_frameworks!
    pod 'HTTPKit' ~> '1.0.0'
end
```

Then，install your dependencies with [CocoaPods](https://cocoapods.org).

``` sh
$ pod install
```
### Carthage 

[Carthage](https://github.com/Carthage/Carthage) is intended to be the simplest way to add frameworks to your application.

You can install Carthage with [Homebrew](https://brew.sh) using following command:

``` sh
$ brew update
$ brew install carthage
```

To integrate `HTTPKit` into your project using Carthage, specify it into your `Cartfile`

``` 
github "zevwings/HTTPKit" ~> 0.0.1
```

Then，build the framework with Carthage
using `carthage update` and drag `HTTPKit.framework` into your project.

#### Note:
The framework is under the Carthage/Build, and you should drag it into  `Target` -> `Genral` -> `Embedded Binaries`

### Manual
Download this project, And drag `HTTPKit.xcodeproj` into your own project.

In your target’s General tab, click the ’+’ button under `Embedded Binaries`

Select the `HTTPKit.framework` to Add to your platform. 


## License
`HTTPKit` distributed under the terms and conditions of the [MIT License](https://github.com/zevwings/HTTPKit/blob/master/LICENSE).


