
Pod::Spec.new do |spec|

  spec.name           = "HTTPKit.swift"
  spec.module_name    = "HTTPKit"
  spec.version        = "2.2.3"
  spec.summary        = "HTTPKit is deprecated, please use ACINetworking instead."
  spec.swift_version  = "5.1"
  spec.deprecated     = true


  spec.description  = <<-DESC
                    A network layer base on Alamofire.
                    1. support HandyJSON decode Data
                    2. support SwiftyJSON decode Data
                    3. support RxSwift
                   DESC

  spec.homepage     = "https://github.com/zevwings/HTTPKit"
  spec.license      = "Apache"
  spec.author       = { "zevwings" => "zev.wings@gmail.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/zevwings/HTTPKit.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.source_files = "Sources/**/*.swift"

end

