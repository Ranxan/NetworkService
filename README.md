# NetworkService

[![CI Status](http://img.shields.io/travis/Ranxan/NetworkService.svg?style=flat)](https://travis-ci.org/Ranxan/NetworkService)
[![Version](https://img.shields.io/cocoapods/v/NetworkService.svg?style=flat)](http://cocoapods.org/pods/NetworkService)
[![License](https://img.shields.io/cocoapods/l/NetworkService.svg?style=flat)](http://cocoapods.org/pods/NetworkService)
[![Platform](https://img.shields.io/cocoapods/p/NetworkService.svg?style=flat)](http://cocoapods.org/pods/NetworkService)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
Swift 3.0

## Installation

NetworkService is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NetworkService', '~> 0.1.0'
```
## Author

Ranjan Adhikari, 
ranjan.smartmobe@gmail.com 
ranxan4ix@gmail.com

## License

NetworkService is available under the MIT license. See the LICENSE file for more info.

**About**

Network Service is an API caller library module. It is written in swift 3.0. It's intention remains to help iOS applications to communicate with API services easily and efficiently. Network Service library is designed on popular Swift libraries **Alamofire** and **ObjectMapper**. 


**Get Started**

Network Service library uses Alamofire for all network activities. The library works on predetermined HTTP request and response data structures. Presentation format for both request and response data is based upon JSON notations. It uses ObjectMapper to parse JSON data. Response JSON data is deserialized into Swift object and Swift object is serialized into request JSON data.

 
** Fundamentals **

* Network Service Configuration

NetworkServiceConfiguration structure incorporates general configurations that library needs in all network calls. 
**baseUrl** is a static property field. It is a root pointer to the API service. Application can change the value for this field before working on any network calls. It is a common property that library uses for all the HTTP calls.
**timeoutValue** is a request timeout till when client waits for the response to arrive. Default timeout value is set to 10 seconds time interval. This may be customised as required.
**headers** field is a dictionary type property. It holds values for the headers fields of http requests. Client can provide additional header fields in this dictionary. In each HTTP request call, library checks for this property and adds available item(s) from the dictionary as key-value pairs in request headers.
**serviceSessionType** field identifies the type of session to instantiate for http requests. There are basic three types of session types we can consider for the HTTP requests. : default, ephemeral and background sessions. Network Service library handles data requests with default sessions and file uploads and downloads with background sessions. 
**clientBundle** is a unique identifier basically for the background services. Network Service library prefers single background session for single request. [Needs review for future enhancements.]

Network Service Configuration also checks for valid URL format before making API requests.

```
public struct NetworkServiceConfiguration {

static var baseUrl = "http://domain/api" 
static var timeoutValue = TimeInterval(10) 
static var headers : [String:String] = [:]

var serviceSessionType : NetworkServiceSessionType = .defaultService 
var clientBundle = "com.networkservice.api"

static var urlIsValid : Bool = false

init() {
}

static func validateServiceURL() -> Bool {
/*Validates that http URL has correct format ..*/
}

}

```

* Network Service Delegate

Each data request requires basic parameters that are unique to the request. Network Service Delegate is a protocol that defines required parameters : path, method and a type of a model class for response data. Response data is deserialized into the model class identified by the associated type 'v'. Network Service caller for the data request must create a structure that confirms to this protocol. 

```

public protocol NetworkServiceDelegate {

init()

static var path : String {get set}
static var method : NetworkServiceHTTPMethod {get set}
associatedtype V : BaseModel

}

```

* Request and Response Data

General POST and GET requests are handled with request parameters. A model class (swift class) is serialized into JSON data for all the POST requests parameters. Network Service Library provides basic implementations and components that clients must use to generate requests and receive response.

**BaseModel** is a base class that all the model classes has to extend from. Whether the class represents a request model or a response model. HTTP response data is deserialized into the type of **BaseResponse**. BaseResponse includes a structure member as a status of a API service response and data object that contains model (or array of models) of type BaseModel.

```
#!swift
open class BaseModel : Mappable {

public init() {
/*Default..*/
}

required public init?(map: Map) {
}

public func mapping(map: Map) {
}

}

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

/** Base structure for the status response. **/
public struct ServiceResponseStatus : Mappable {

var message : String?
var code : String?
var responseTimeStamp : String?

public init() {
}

public init?(map: Map) {
}

mutating public func mapping(map: Map) {
self.message <- map["message"]
self.code <- map["code"]
self.responseTimeStamp <- map["responseTimeStamp"]
}
}

```

In the above code snippet, we can see that BaseModel confirms to the Mappable protocol of ObjectMapper. BaseResponse accepts a type parameter of type BaseModel and confirms to the internal protocol NetworkServiceBaseResponse. ServiceResponseStatus is a structure that provides status information of either successful or failure response for particular network request.


* Network Caller Service

Basic network calls for GET, POST and Upload requests are initiated by **NetworkService** class. It takes type parameter of type NetworkServiceDelegate. Client uses an instance of NetworkService to make HTTP requests.

NetworkService handles following functionality:

1. Initialization of data requests and upload requests.
2. Verifying request path and credentials. 
3. Handle http response.
4. Deserialize response data into class models.
5. Handle general exceptions.
6. Pass back API response to the client as a response model or error in case.

The outline of NetworkService class is as shown in the code snippet below: 

```
#!swift
open class NetworkService<T:NetworkServiceDelegate> {

var requestEndPoint : T
var requestCredentials : ServiceCredentials<T>
var networkServiceConfiguration : NetworkServiceConfiguration

private var networkRequest : DataRequestService<T>?

public init(){
/* Default */

}

public init(networkServiceConfiguration : NetworkServiceConfiguration) {

}

public init(requestEndPoint : T, networkServiceConfiguration : NetworkServiceConfiguration) {

}

deinit {
printLog(log: "Deinitialized Network Service.")
}

/** Method is used by the client to instantiate API Call request for the data.
@param requestParams : optional parameters to be passed to API.
@param callback : callback passed from the client that holds either response data from the API or an error.
*/
@discardableResult public func call(requestParams : [String:Any]? , callback : @escaping (BaseResponse<T.V>?, NetworkServiceErrorInfo?) -> Void) {
}


/**Adds headers parameters to network service API for HTTP Requests.*/
public func addRequestHeader(key k :String, value v : String) {
}

/**Invalidates and clears the related URL session. If this network service instance is created with default Session Manager, default session manager is invalidated and cleared.*/
public func invalidateRelatedURLSession() -> Void {
}

/**Invalidates and clears session managers..*/
public func invalidateURLSessions() -> Void {
}

/**Cancels currently active request..*/
public func cancelCurrentRequest() -> Void {
}

}
```



**Example**

```
#!swift

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

/** Request configuration.. */
struct RequestConfiguration : NetworkServiceDelegate {

static var path = "/test"
static var method = NetworkServiceHTTPMethod.get
typealias V = TestModel /*Response Model Type..*/

}

/** API Call configuration.. */
class TestService {

/*Here, model for request and response is same. This is only for the purpose of test demo.*/
var requestParams : [String:Any]? = TestModel().toJSON()

func call() {
NetworkService<RequestConfiguration>()
.call(requestParams: requestParams) { response, error in

guard let responseData = response else {

/*Get error message..*/
print(error as Any)
return

}

if let data = responseData.data {

/*Response data is available.*/
print(String(describing: data.body))

} else {

/*Response status is available, in case response data is not available*/
print(responseData.status?.message ?? "No status Message.")
}
}
}

}

```


**Uploading and Downloading Files**

Upload and download tasks are handled in background sessions by default. Single request for an upload or download is handled by a single session. Once the task for upload or download is completed, corresponding session is invalidated.

Uploading of files is handled by the **UploadService** class. UploadService accepts a type parameter of type UploadServiceDelegate. UploadServiceDelegate extends NetworkServiceDelegate protocol and contains data or URL for files to upload.

Initialization parameters

- Optional Identifier String (Used for corresponding background session.)
- Optional progress callback (Used to provide progress on updates.)

Method **upload**

- The parameter **key** is used as identifier for the files to upload. 
- API response from update call is passed back to the client via closure **callback** parameter of the method. 

```
#!swift
open class UploadService<T:UploadServiceDelegate> : BaseRequestService {

typealias UploadProgressCallback = (Progress) -> Void
var uploadProgressCallback : UploadProgressCallback?

var uploadRequestEnd : T
var uploadRequestCredentials : ServiceCredentials<T>

var uploadRequest : UploadRequest?

init(uploadIdentifier : String?, uploadProgressCallback : UploadProgressCallback?) {

}


/** Uploads single or multiple files in a given key..*/
func upload(withKey key : String, callback : @escaping (BaseResponse<T.V>?, NetworkServiceErrorInfo?) -> Void) {

}

func cancelUploadRequest() -> Void {
}
}

```

Download task is performed by the **DownloadService** class. 

Initialization parameters

- Optional NetworkServiceConfiguration.
Initiation of download service and session configuration is based upon the NetworkServiceConfiguration.
- Optional Identifier String (Used for corresponding background session.)
- Optional progress callback (Used to provide progress on downloads.)

Method **download**

- The parameter **downloadPath** is used to point the remote resource to be downloaded.
- The parameter **fileName** is used for a name of the resource file in the document's directory of the device after it is downloaded.
- Downloaded resource is also passed back to the client via closure **callback** parameter.

Download service also handles exception cases and notifies client about the error using NetworkServiceErrorInfo. 

```
#!swift
open class DownloadService : BaseRequestService {

typealias DownloadProgressCallback = (Progress) -> Void
typealias DownloadResponseCallback = (Any?, NetworkServiceErrorInfo?) -> Void

var downloadProgressCallback : DownloadProgressCallback?
var downloadResponseCallback : DownloadResponseCallback?

var downloadRequest : DownloadRequest?

init(serviceConfiguration : ServiceConfiguration?, downloadIdentifier : String?, downloadProgressCallback : DownloadProgressCallback?) {
/*Initialization..*/
}

/**Downloads the file into the device storage from the specified service resource.*/
func download(downloadPath : String, fileName : String?, callback : @escaping DownloadResponseCallback) {
/*Handle download..*/        
}


}

```

**Requests Adapter and Retrier**

Network Service adapts to every HTTP requests. All most requests require one or more headers along the requests. For example, an HTTP request requires authentication tokens. It checks for the authentication token and includes into the header if available. Otherwise request is proceeded without authentication token.

HTTP requests can fail with the failure in validation of response. Requests fail with unsuccessful HTTP status codes or unexpected content types. In such cases, requests are retried. Currently, failed requests are retried only for invalid authentication token. Other failure cases are handled with error.

Successful requests are handled with status codes 200..<299. Besides,
unsuccessful requests are handled with information available from the API service in the status key of the response data.


** Handling authentication based on OAuth **

Network Service handles oAuth tokens for every HTTP requests. If HTTP request fails in authentication, service holds the request and initiates a new HTTP request to refresh authentication token. To refresh the auth token, library sets the refresh token to the request header. API verifies the refresh token and responds back to the request with new authentication token as well as new refresh token. And then pending requests are continued with new token again.

Basic structure for Authentication Handler with AuthenticationModel class is as shown in the snippet below:

```
#!swift

/** Base model to be received from service API for the authentication tokens.*/
class OAuthTokenModel : BaseModel {

var tokenType : String?
var expiresIn : Double?
var refreshToken : String?
var accessToken : String?

override init() {
super.init()
}

required init?(map: Map) {
super.init(map: map)
}

override func mapping(map: Map) {
tokenType <- map["token_type"]
expiresIn <- map["expires_in"]
refreshToken <- map["refresh_token"]
accessToken <- map["access_token"]
}
}

class OAuthTokenService {

init() {
}

func refreshToken(completionCallback : @escaping NetworkServiceCallStatusCallback) {	
/* Calls network service API caller to refresh the authentication token. */
}

static func saveOAuthTokens(authenticationModel oAuthModel : OAuthTokenModel) -> Void {
/**Persisting authentication tokens .. */
}

static func resetAuthTokens() {
/* Removes locally stored authentication token from the application.*/
}

static func findOAuthToken() -> Bool {
/* Verifies the authentication token is available for use.*/
}

static func findOAuthRefreshToken() -> Bool {
/* Verifies the authentication refresh token is available for use.*/
}

}

```

Client can call for user authentication API to receive authentication tokens. Response for authentication token is received as **OAuthTokenModel**. The method **saveOAuthTokens** saves tokens into local storage for the application.

** HTTP Redirection **

Network Service implements basic redirection mechanism for any HTTP requests. Any HTTP response with status code 3XX is interrupted to find URL of the new source where the request is redirected. 

[ Note : Part of redirection needs further analysis and implementations.]
