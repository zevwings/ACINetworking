//
//  ViewController.swift
//  ACINetworkingExample
//
//  Created by 张伟 on 2021/11/15.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func catchVerifyCode(_ sender: Any) {

        ExampleService.shared.request(api: .verifyCode("17712341234")) { result in
            switch result {
            case let .success(response):
                do {
                    let json = try response.mapJSON()
                    print(json)
                } catch {
                    print(error)
                }
            case let .failure(error):
                print(error)
            }
        }
    }
    
    @IBAction func login(_ sender: Any) {
        ExampleService.shared.request(api: .smsLogin(telno: "17712341234", code: "888888", invitationCode: nil)) { result in
            switch result {
            case let .success(response):
                do {
                    let json = try response.mapJSON()
                    print(json)
                } catch {
                    print(error)
                }
            case let .failure(error):
                print(error)
            }
        }

    }
}

