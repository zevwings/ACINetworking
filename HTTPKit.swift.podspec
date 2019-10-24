#
#  Be sure to run `pod spec lint HTTPKit.swift.podspec" to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name           = "HTTPKit.swift"
  spec.module_name    = "HTTPKit"
  spec.version        = "0.0.1"
  spec.summary        = "A network layer base on Alamofire."
  spec.swift_version  = "5.1"

  spec.description  = <<-DESC
                    A network layer base on Alamofire.
                    1. support HandyJSON decode Data
                    2. support SwiftyJSON decode Data
                    2. support RxSwift
                   DESC

  spec.homepage     = "https://github.com/zevwings/HTTPKit"
  spec.license      = "Apache"
  spec.author       = { "zevwings" => "zev.wings@gmail.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/zevwings/HTTPKit.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.default_subspecs = "Core"

  spec.subspec "Core" do |core|
    core.source_files = "HTTPKit/HTTPKit.h", "HTTPKit/**/*.swift"
    core.dependency "Alamofire", "~> 5.0.0-rc.2"
  end

  spec.subspec "RxSwift" do |rx|
    rx.source_files = "RxSupport/RxSupport.h", "RxSupport/**/*.swift"
    rx.dependency "HTTPKit.swift/Core"
    rx.dependency "RxSwift"
  end

end

