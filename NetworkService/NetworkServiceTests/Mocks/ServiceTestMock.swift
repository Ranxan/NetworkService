//
//  NSTestService.swift
//  SMS-iOS Template
//
//  Created by Ranjan Adhikari on 5/12/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

@testable import SMS_iOS_Template

/** Service Test Model.. */
class TestModel : BaseModel {
    
    /*Default values are to be received as from API..*/
    var id : Int? = 1
    var userId : Int? = 1
    var title : String? = "Title"
    var body : String? = "Body"
    
    override init() {
        super.init()
    }
    
    required init?(map: Map) {
        super.init(map: map)
    }
    
    override func mapping(map: Map) {
        id <- map["id"]
        userId <- map["userId"]
        title <- map["title"]
        body <- map["body"]
    }
    
}

/** API Call configuration.. */
struct TestRequestConfiguration : NetworkServiceDelegate {
    
    static var path = "/test"
    static var method = NetworkServiceHTTPMethod.get
    typealias V = TestModel /*Response Model Type..*/
    
}

/** API Call configuration.. */
class ServiceTestMock {
	
    static var MESSAGE_SUCCESS : String = "Success."
    static var MESSAGE_FAILURE : String = "Failure."
    
    var serviceTestResponseState : Bool? = false
    var serviceTestMessage : String?
    var requestParams : [String:Any]? = TestModel().toJSON()
    
    func call(callback : @escaping (Bool) -> Void) {
        NetworkService<TestRequestConfiguration>()
			.call(requestParams: requestParams) { response, error in
                
                guard let responseData = response else {
                
                    /*Get error message..*/
                    print(error as Any)
                    self.serviceTestResponseState = false
                    self.serviceTestMessage = error?.errorMessage.rawValue
                    callback(false)
                    return

                }
                
                if let data = responseData.data {
                    
                    /*Response data is available.*/
                    print(String(describing: data.body))
                    self.serviceTestResponseState = true
                    self.serviceTestMessage = ServiceTestMock.MESSAGE_SUCCESS
                    callback(true)
                    
                } else {
                    
                    /*Response status is available, in case response data is not available*/
                    print(responseData.status?.message ?? "No status Message.")
                    self.serviceTestResponseState = false
                    self.serviceTestMessage = ServiceTestMock.MESSAGE_FAILURE
                    callback(false)
                     
                }
                
        }
    }
    
}







