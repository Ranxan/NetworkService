//
//  EndpointsConfiguration.swift
//  SMS-iOS Template
//
//  Created by Ranjan Adhikari on 5/9/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

/** Enum representing basic HTTP methods. */
public enum NetworkServiceHTTPMethod {
    case get
    case post
}

/** Identifier to create session manager. 
    By default,
     - all the data requests are handled by default session manager.
     - all the upload and download tasks are handled by the background session manager.
    Any request may be handled by an ephimeral session manager as per the requirement.
*/
enum NetworkServiceSessionType {
    case defaultService
    case ephimeralService
    case backgroundService
}

/** A common configuration used the Network Service Component for all the HTTP Requests.**/
public struct NetworkServiceConfiguration {
    
    static var baseUrl = "http://52.187.44.240/api" /* API Base endpoint */
    static var timeoutValue = TimeInterval(10) /* Request timeout seconds. */
    static var headers : [String:String] = [:]
    
    var serviceSessionType : NetworkServiceSessionType = .defaultService /* URL Session type. */
    var clientBundle = "com.networkservice.api" /*Unique identifier of the client. Identifier is used for the background session types.*/
    
    static var urlIsValid : Bool = false
    
    init() {
    }
    
    static func validateServiceURL() -> Bool {
        guard !NetworkServiceConfiguration.urlIsValid, NetworkServiceConfiguration.baseUrl.characters.count > 0 else {
            return NetworkServiceConfiguration.urlIsValid
        }
        /*Validate that http URL has correct format ..*/
        NetworkServiceConfiguration.urlIsValid = NSPredicate(format: "SELF MATCHES %@", "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)").evaluate(with: NetworkServiceConfiguration.baseUrl)
        return NetworkServiceConfiguration.urlIsValid
    }
    
}

/** Main service protocol. Every client of this NetworkService API caller must use an object which implements this protocol.**/
public protocol NetworkServiceDelegate {
    
    init()
    
    static var path : String {get set}
    static var method : NetworkServiceHTTPMethod {get set}
    associatedtype V : BaseModel

}

/** Extension to service delegate that contains default method implementations. */
extension NetworkServiceDelegate {
	
    /** By default, ServiceDelegate types are incorporated with default network service configuration. */
    func getNetworkServiceConfiguration() -> NetworkServiceConfiguration {
        return NetworkServiceConfiguration()
    }
	
}

/** A protocol delegate for upload service. It extends from ServiceDelegate and contains paramters field to hold Any type of file to upload.**/
public protocol UploadServiceDelegate : NetworkServiceDelegate {
    static var parameters : [String:Any]? {get set}
}

/** Extension to download service delegate that contains default method implementations. */
extension UploadServiceDelegate {
    
    func getNetworkServiceConfiguration(bundleIdForBackgroundService : String?) -> NetworkServiceConfiguration {
        var serviceConfiguration = NetworkServiceConfiguration()
        serviceConfiguration.serviceSessionType = .backgroundService
        
        if let id = bundleIdForBackgroundService {
            serviceConfiguration.clientBundle = id
        }
        
        return serviceConfiguration
    }
    
}

/** A protocol delegate for download service.**/
public protocol DownloadServiceDelegate {
    
    static var path : String {get set}
    static var method : NetworkServiceHTTPMethod {get set}
    static var file : Any? {get set}
    
}

/** Extension to download service delegate that contains default method implementations. */
extension DownloadServiceDelegate {
    
    func getNetworkServiceConfiguration() -> NetworkServiceConfiguration {
        var serviceConfiguration = NetworkServiceConfiguration()
        serviceConfiguration.serviceSessionType = .backgroundService
        return serviceConfiguration
    }
    
}

/** NetworkServiceBaseResponse protocol defines basic structure for the API response. **/
public protocol NetworkServiceBaseResponse : Mappable {
	
    associatedtype U : Mappable /*Generic type for the response status. */
    associatedtype V : Mappable /*Generic type for the response model.  */
	
	var status : U? {get set}
	var data : V? {get set}
	
}

/** A custom type that may be used as a closure callback for any network related asynchronus calls. Callback parameter can be used to identify a boolean state of network calls.*/
typealias NetworkServiceCallStatusCallback = (Bool) -> Void

/** Incorporates request credentials required before each data request. Network Service component uses this structure internally to wrap the service response and pass back to the service caller via callback.
 Response from service API is received as a type of BaseResponse<T.V>.
 Here, BaseResponse is a structure and T.V is a generic paramter for the type BaseModel. BaseModel is a base model class for all other application data models. BaseModel is eventually inheritance of Mappable protocol of ObjectMapper and hence BaseModel is a Mappable. The BaseResponse contains service API response as :
 {
    body : T.V // Service API response data.
    status: {} // Service API response status.
 }
 Next is callback parameter which saves reference to the callback from the network service caller.
 And the requestParameters is used to hold caller's paramters for the data request. It is passed around the components within Network Service.
 */
struct ServiceCredentials<T:NetworkServiceDelegate> {
    
    typealias C = (BaseResponse<T.V>?, NetworkServiceErrorInfo?) -> Void
    var callback : C?
    var requestParameters : [String:Any]?
    
}
