Pod::Spec.new do |spec|

  spec.name         = "ACINetworking.swift"
  spec.module_name  = "ACINetworking"
  spec.version      = "3.0.0"
  spec.summary      = "ACINetworking是基于Alamofire封装的业务网络处理层"
  spec.swift_version   = '5.1'

  spec.description  = <<-DESC
                  ACINetworking是基于Alamofire封装的业务网络处理层，使网络请求更简洁、更易维护。
                   DESC

  spec.homepage     = "https://github.com/zevwings/ACINetworking"
  spec.license      = "MIT"
  spec.author       = { "zevwings" => "zev.wings@gmail.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/zevwings/ACINetworking.git", :tag => "#{spec.version}" }
  spec.source_files = "Sources/Supporting Files/ACINetworking.h", "Sources/ACINetworking/**/*.swift"
  spec.requires_arc = true
  spec.dependency 'Alamofire'

end
