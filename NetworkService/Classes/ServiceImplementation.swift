//
//  ServiceImplementation.swift
//  SMS-iOS Template
//
//  Created by Ranxan Adhikari on 5/22/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import ObjectMapper

/*  These are the base implementations for using NetworkService library. 
    Response models to be received by the client must be defined with these base models.
    
    Response from the API is received in the following format:
    {
        status : {}
        body : {} /*Single object is received as a body itself and array of objects are received with further pagination information inside the body.*/
    }
    
    Each data model extends from BaseModel which is a Mappable type from ObjectMapper library.
    Status is of type ServiceResponseStatus, which is a custom type that incorporates fields and the fields hold response status from the service API.

    Hence, major implementation of NetworkService component includes:
    
    - BaseModel (for response data models)
    - ServiceResponseStatus (for response status)
    - BaseResponse (for response as a whole, wrapping both response data model and status)
 
 **/

/** Base structure for the status response. **/
public struct ServiceResponseStatus : Mappable {
	
    /*Status message that describes the corresponding response 'code'*/
	var message : String?
    /*Status specific response code. This might not be a corresponding HTTP status code. For example: HTTP status code 400 might include break down status with specific meaning.*/
    var code : String?
    /*Timestamp from the server, after the execution of request process in the server.*/
	var responseTimeStamp : String?
	
	public init() {
	}
	
	public init?(map: Map) {
	}
	
	// Maps the Status's properties with the corresponding key sent from the server
	mutating public func mapping(map: Map) {
		self.message <- map["message"]
		self.code <- map["code"]
		self.responseTimeStamp <- map["responseTimeStamp"]
	}
}

/** This is a base response model. Any response from the api is received wrapped within this model. */
 public struct BaseResponse<T:BaseModel> : NetworkServiceBaseResponse {
	
	public typealias U = ServiceResponseStatus
	public typealias V = T
	
	public var status : U?
	public var data : T?
	
	public init(){
	}
	
	public init?(map: Map) {
	}
	
	public mutating func mapping(map: Map) {
		status <- map["status"]
		data <- map["body"]
	}
}

/** This is a base model for every other data models to be received from the API.. */
public class BaseModel : Mappable {
	
	public init() {
		/*Default..*/
	}
	
	required public init?(map: Map) {
	}
	
	public func mapping(map: Map) {
	}
	
}
