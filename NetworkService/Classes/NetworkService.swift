//
//  NetworkService.swift
//  SMS-iOS Template
//
//  Created by Ranjan Adhikari on 5/9/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

/**	An adapter that intercepts each network request to adapt necessary configuration (basically header configuration and authentication token.) */
fileprivate class NetworkServiceAdapter : RequestAdapter {

	private var headers : [String:String]?
	
	init() {
		printLog(log: "Adapter initialized.")
	}
	
	init(headers : [String:String]) {
		printLog(log: "Adapter initialized.")
		self.headers = headers
	}
	
	public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
		
        /*Add headers for each http requests..*/
		var httpRequest = urlRequest
        /*Header field 'Accept' is set by default..*/
		httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        /*Additional header fields provided by client..*/
        for(key, value) in NetworkServiceConfiguration.headers {
            httpRequest.setValue(value, forHTTPHeaderField: key)
        }
		
		guard OAuthTokenService.findOAuthToken() else {
			/*Authentication token has been reset. Call API with refresh token to get the new authentication token..*/
			if OAuthTokenService.findOAuthRefreshToken() {
				httpRequest.setValue(OAuthTokenService.authenticationRefreshToken, forHTTPHeaderField: "Authorization")
			}
			return httpRequest;
		}
		
		/*Set headers for other API Calls..*/
		httpRequest.setValue("Bearer " + OAuthTokenService.authenticationToken, forHTTPHeaderField: "Authorization")
				
		return httpRequest
	}
}

/** An HTTP request retrier that handles automatic retry of network calls in case of call failure.
 HTTP requests fail for invalid response. 
 Special case for authentication token is handled and pending requests are retried.
 HTTP status code 401 requires holding of current (or subsequent) requests and call API to refresh authentication token.
 After an authentication token is successfully received, one or more pending requests are retried with the new token. 
 For all other status codes (> 299) requests are not retried and response is passed forward to the error callback.
*/
fileprivate class NetworkServiceRetrier : RequestRetrier {
	
	var associatedRequest : BaseRequestService
	
    /*These static fields have common effect over any requests.*/
	static let lock = NSLock()
	static var isTokenBeingRefreshed = false
	static var requestRetries : [RequestRetryCompletion]?
	
	init(baseRequestService : BaseRequestService) {
		printLog(log: "Retrier initialized.")
		self.associatedRequest = baseRequestService
	}
	
	public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
		
		/*Lock the method execution and release after the completion of execution of this block*/
		NetworkServiceRetrier.lock.lock()
		defer { NetworkServiceRetrier.lock.unlock() }
		
		guard let response = request.task?.response as? HTTPURLResponse else {
			/*Request error encountered.*/
			completion(false, 0.0)
			return
		}
		
		switch response.statusCode {
			
		case 401:
			
			/*Only in the case of refreshing authorization token.*/
			OAuthTokenService.resetAuthTokens()
			
			/*Proceed to refresh the token if necessary..*/
			if(NetworkServiceRetrier.requestRetries == nil){
				NetworkServiceRetrier.requestRetries = []
			}
			
			NetworkServiceRetrier.requestRetries!.append(completion)
			
			if !NetworkServiceRetrier.isTokenBeingRefreshed {
				/*Refresh the token..*/
				NetworkServiceRetrier.isTokenBeingRefreshed = true
				OAuthTokenService().refreshToken { state in
					
                    if !state {
                        /*Could not refresh the token..*/
						printLog(log: "Token refresh failed. Bad Token")
                    }
                    
					/*Retry pending requests if token is successfully refreshed, otherwise halt all the requests.*/
					NetworkServiceRetrier.requestRetries!.forEach{$0(state, 0.0)}
					NetworkServiceRetrier.requestRetries!.removeAll()
					NetworkServiceRetrier.isTokenBeingRefreshed = false
					
				}
			}
			
			break
			
		default:
			
			/*In the case of any other errors..*/
			completion(false, 0.0)
			break
		}
		
	}
	
}

/** NetworkService component as an interface to be used by the client. 
	Client consuming this library can make requests for data using an instance of this class.
	
	Example for usage:
	let networkCallService = NetworkService<RequestConfiguration>().call(requestParams: requestParams) { response, error in }
	Here RequestConfiguration is a type for a generic type paramter of NetworkService. This parameter type comprises information
	about API end point and URL session configuration.
**/
open class NetworkService<T:NetworkServiceDelegate> {
	
	var requestEndPoint : T
	var requestCredentials : ServiceCredentials<T>
    var networkServiceConfiguration : NetworkServiceConfiguration
    
    private var networkRequest : DataRequestService<T>?
	
    public init(){
        /* Default */
		self.requestEndPoint = T()
        self.requestCredentials = ServiceCredentials<T>()
        self.networkServiceConfiguration = NetworkServiceConfiguration()
    }

    public init(networkServiceConfiguration : NetworkServiceConfiguration) {
		self.requestEndPoint = T()
		self.requestCredentials = ServiceCredentials<T>()
		self.networkServiceConfiguration = networkServiceConfiguration
    }
	
	public init(requestEndPoint : T, networkServiceConfiguration : NetworkServiceConfiguration) {
		self.requestEndPoint = requestEndPoint
		self.requestCredentials = ServiceCredentials<T>()
		self.networkServiceConfiguration = networkServiceConfiguration
	}
    
    deinit {
        printLog(log: "Deinitialized Network Service.")
    }
	
	/** Method is used by the client to instantiate API Call request for the data.
		@param requestParams : optional parameters to be passed to API.
		@param callback : callback passed from the client that holds either response data from the API or an error.
	*/
    @discardableResult public func call(requestParams : [String:Any]? , callback : @escaping (BaseResponse<T.V>?, NetworkServiceErrorInfo?) -> Void) {
		
        requestCredentials.callback = callback /*Callback closure instance of API Call..*/
        guard requestCredentials.callback != nil else {
			printLog(log: "Network Service Error : Callback closure is missing.")
            return
        }
        
        guard NetworkServiceConfiguration.validateServiceURL() else {
			let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.requestCredentials, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: NetworkServiceException.networkRequestIncorrectURL))
            return
        }
        
        /*Request parameters..*/
        requestCredentials.requestParameters = requestParams
        
        switch T.method {
			
		case .get, .post:
            
            self.networkRequest = DataRequestService<T>(nsConfiguration: self.requestEndPoint.getNetworkServiceConfiguration())
            self.networkRequest!.call(requestCredentials : self.requestCredentials)
			
        }
    }
	
    /**Adds headers paramters to network service API for HTTP Requests.*/
    public func addRequestHeader(key k :String, value v : String) {
        let keyExists = NetworkServiceConfiguration.headers[k]
        if keyExists == nil {
            NetworkServiceConfiguration.headers[k] = v
        }
    }

    /**Invalidates and clears the related URL session. If this network service instance is created with default Session Manager, default session manager is invalidated and cleared.*/
    public func invalidateRelatedURLSession() -> Void {
        self.networkRequest?.clearSession()
    }
    
    /**Invalidates and clears session managers..*/
    public func invalidateURLSessions() -> Void {
        self.networkRequest?.clearAllSessions()
    }

    /**Cancels currently active request..*/
    public func cancelCurrentRequest() -> Void {
        self.networkRequest?.cancelRequest()
    }
    
}

/** Base class for the data requests, upload and download request classes.
    It includes response intercepter (or validator.) For all the response with status code 200 are validated as sucessful, otherwise with failure.
 **/
open class BaseRequestService {

	var sessionManager : SessionManager?

	private static var defaultSessionManager : SessionManager?
	private static var ephimeralSessionManager : SessionManager?
    
    static var callState = true

    static let responseValidation : DataRequest.Validation = { urlRequest, urlResponse, data -> Request.ValidationResult in
		
        switch urlResponse.statusCode {
        case 200...299 :
			
            return .success
			
        default:
            
            /*TODO : other response codes..*/
            /**
             Status : 401 (Unauthorized)
             - Wrong Login credentials
             - Token not provided
             - Token Expired
             - Token Invalid
             - Token not refreshable 
			
			Failed request is halt and new request is initiated to refresh the authentication access token. 
			After the successful retrieval of auth tokens, halt request is retried along with the new access token.
             
             Status : 500 (Internal Server Errors)
             - Timeout (Server fails to respond)
             - Server Error (Server responds with error.)
			
			Failed response is available from the API along with the status message but nil data.
             */
            
            var responseError = NetworkServiceError()
            
            if let responseData = data {
                /*Response is available from the service API along with response status.*/
                responseError.data = responseData
                responseError.error = nil
            } else {
                /*Create an error type of AFError as per the response status code..*/
                let reason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: urlResponse.statusCode)
                responseError.error = AFError.responseValidationFailed(reason: reason)
                responseError.data = nil
            }
            
            return .failure(responseError)

        }
    }
    
    init(nsConfiguration : NetworkServiceConfiguration) {
		
		var urlSessionConfiguration : URLSessionConfiguration
        
        switch nsConfiguration.serviceSessionType {
        case .defaultService:

			if BaseRequestService.defaultSessionManager == nil {
				
				BaseRequestService.defaultSessionManager = Alamofire.SessionManager.default
                BaseRequestService.defaultSessionManager!.adapter = NetworkServiceAdapter()
                BaseRequestService.defaultSessionManager!.retrier = NetworkServiceRetrier(baseRequestService: self)
                
                let delegate : Alamofire.SessionDelegate = BaseRequestService.defaultSessionManager!.delegate
                delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
                    return self.redirectHTTPRequest(urlSession: session, task: task, response: response, request: request)
                }
			}
			self.sessionManager = BaseRequestService.defaultSessionManager!
			
        case .ephimeralService:
			
			if BaseRequestService.ephimeralSessionManager == nil {
				
				urlSessionConfiguration = URLSessionConfiguration.ephemeral
				BaseRequestService.ephimeralSessionManager = Alamofire.SessionManager(configuration: urlSessionConfiguration)
                BaseRequestService.ephimeralSessionManager!.adapter = NetworkServiceAdapter()
                BaseRequestService.ephimeralSessionManager!.retrier = NetworkServiceRetrier(baseRequestService: self)

                let delegate : Alamofire.SessionDelegate = BaseRequestService.ephimeralSessionManager!.delegate
                delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
                    return self.redirectHTTPRequest(urlSession: session, task: task, response: response, request: request)
                }

			}
			self.sessionManager = BaseRequestService.ephimeralSessionManager!
			
        case .backgroundService:
            
            urlSessionConfiguration = URLSessionConfiguration.background(withIdentifier: nsConfiguration.clientBundle)
            self.sessionManager = Alamofire.SessionManager(configuration: urlSessionConfiguration)
            self.sessionManager!.adapter = NetworkServiceAdapter()
            self.sessionManager!.retrier = NetworkServiceRetrier(baseRequestService: self)
            
            let delegate : Alamofire.SessionDelegate = self.sessionManager!.delegate
            delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
                return self.redirectHTTPRequest(urlSession: session, task: task, response: response, request: request)
            }
            
            delegate.taskDidComplete = { urlSession, urlSessionTask, error in
                /*TODO..
                 Need to assure that background session has been completely invalidated before intializing the new background session with same identifier.
                 */
				/**Clear the session..*/
                urlSession.finishTasksAndInvalidate()
            }
            
		}
        
	}
    
	deinit {
		printLog(log: "Deinitialized Base Network Service Request ..")
	}

    /** Handles redirection of HTTP requests. */
    private func redirectHTTPRequest(urlSession:URLSession, task : URLSessionTask, response : HTTPURLResponse, request: URLRequest) -> URLRequest {

		var finalRequest = request
		
        if task.originalRequest != nil  {
			
            /*Get redirection URL from the 'Location' key of header.*/
            let responseHeaderFields = response.allHeaderFields
            if let redirectionLocation = responseHeaderFields["Location"] as? String {
				
                /*URL to redirect to..*/
                finalRequest.url = URL(string: redirectionLocation)
                switch response.statusCode {
                case 307, 308:
                    /*Change only the URL to redirect to. Other parts of the request is same to that of original HTTP Request.*/
                    break
					
                default:
                    /*Redirect in GET request without parameters. 
                     This is the case to handle for status codes 301, 302, 303. However it is used as a default case for the redirection.*/
                    finalRequest.httpBody = nil
                    finalRequest.httpMethod = "GET"
                }
				
				/*Try to adapt this request to confirm to request headers before proceeding with the redirection.*/
				do {
					if let adaptedRequest = try self.sessionManager?.adapter?.adapt(finalRequest) {
						finalRequest = adaptedRequest
					}
				} catch {
					printLog(log: "Exception trying to addapt redirection HTTP request with the adapter.")
				}
				
            }
        }
		
        return finalRequest
    }
    
    func clearSession() -> Void {
        sessionManager?.session.finishTasksAndInvalidate()
    }
	
	func clearAllSessions() -> Void {
		BaseRequestService.defaultSessionManager?.session.finishTasksAndInvalidate()
		BaseRequestService.ephimeralSessionManager?.session.finishTasksAndInvalidate()
	}
    
}

/** Handles HTTP get and post requests of data. Data requests are handled basically with default session configurations.
*/
fileprivate class DataRequestService<T:NetworkServiceDelegate> : BaseRequestService {
	
    var requestEndPoint : T?
	var requestCredentials : ServiceCredentials<T>?
    var dataRequest : DataRequest?
    
    override init(nsConfiguration : NetworkServiceConfiguration) {
		super.init(nsConfiguration: nsConfiguration)
	}
	
    deinit {
        printLog(log: "Deinitialized data request service.")
    }
    
	func call(requestCredentials : ServiceCredentials<T>) -> Void {
        self.requestCredentials = requestCredentials
		let serviceURL = URL(string : NetworkServiceConfiguration.baseUrl+T.path)
        let httpMethod = (T.method == NetworkServiceHTTPMethod.post) ? HTTPMethod.post : HTTPMethod.get
		
		self.dataRequest = sessionManager?.request(serviceURL!, method: httpMethod, parameters: requestCredentials.requestParameters, encoding: JSONEncoding.default, headers: nil)
            .validate(contentType : ["application/json"])
            .validate(BaseRequestService.responseValidation)
            .responseJSON { defaultResponse in
				
                NetworkServiceResponseHandler<T>(requestCredentials: self.requestCredentials!)
                    .handleNetworkResponse(dataResponse: defaultResponse)
                
                /*Clean..*/
                self.dataRequest = nil
				
            }
	}
    
    func cancelRequest() -> Void {
        self.dataRequest?.cancel()
    }

}

/** Data response from http request call is handled and parsed with possible exceptions.**/
fileprivate class NetworkServiceResponseHandler<T:NetworkServiceDelegate> {
	
	var requestEndPoint : T?
	var requestCredentials : ServiceCredentials<T>?
	
    init(requestCredentials : ServiceCredentials<T>) {
        self.requestCredentials = requestCredentials
    }
    
    func handleNetworkResponse(dataResponse response : DataResponse<Any>) -> Void  {
		
		do {
            
			try self.parseResponse(dataResponse: response)
            
		} catch NetworkServiceException.networkConnection {

			let clientInterface = ClientInterface()
			clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkConnection))
			
		} catch NetworkServiceException.networkRequestTimedOut {

            let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkRequestTimedOut))
			
        } catch NetworkServiceException.networkRequestCancelled {

            let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkRequestCancelled))
			
		} catch NetworkServiceException.networkBadRequest {
			
			let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkBadRequest))
            
		} catch {
            
            /*TODO..*/
            let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkError(.networkError, .networkError)))
			
		}
    }
	
	func parseResponse(dataResponse response : DataResponse<Any>) throws -> Void {
		
		switch  response.result {
			
		case .success(let value) :
			
			let clientInterface = ClientInterface()
			clientInterface.passDataModel(requestInstance: self.requestCredentials!, responseResult: value)
			
			break
			
		case .failure(let error) :
			
			guard let responseError = error as? NetworkServiceError else {

				/*This error occurs only if request call is abrupted.*/
				if error._code == NSURLErrorNotConnectedToInternet {
					throw NetworkServiceException.networkConnection
				}
				
				if error._code == NSURLErrorTimedOut {
					throw NetworkServiceException.networkRequestTimedOut
				}
				
				if error._code == NSURLErrorCancelled {
					throw NetworkServiceException.networkRequestCancelled
				}
				
				if error._code == NSURLErrorUserAuthenticationRequired {
					throw NetworkServiceException.networkBadRequest
				}
				
				/*Throw a general error.. */
				throw NetworkServiceException.networkError(.networkError, .networkError)
			
			}
			
			/*Error Response is available from the service API along with status.*/
			guard let responseData = responseError.data else {
				
                /*Error response is not available from the service API. Try to handle the customized error.*/
				if let e = responseError.error {
                    
					/**TODO*/
                    let clientInterface = ClientInterface()
                    clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkError(.networkError, .networkError)))

				}
				
                /*Throw a general error.. */
                throw NetworkServiceException.networkError(.networkError, .networkError)
				
			}
			
			if let responseJSON = try? JSONSerialization.jsonObject(with: responseData, options: []),
                let responseDictionary = responseJSON as? [String : Any] {
				
                let clientInterface = ClientInterface()
				clientInterface.passDataModel(requestInstance: self.requestCredentials!, responseResult: responseDictionary)
				
			} else {
                
                /*Resource for the response is not available or response is invalid.*/

                let clientInterface = ClientInterface()
                clientInterface.passErrorModel(requestInstance: self.requestCredentials!, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid))
                
			}
												
		}
		
	}
		
}

/** Passes back response as data or error to the client via callback.**/
fileprivate class ClientInterface {
	
	func passDataModel<T:NetworkServiceDelegate>(requestInstance ri : ServiceCredentials<T>, responseResult result : Any) -> Void {
		
		guard let responseJSON = result as? [String: AnyObject] else {

            /*Handle invalid response.*/
			let serviceError = NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid)
			passErrorModel(requestInstance: ri, networkServiceErrorInfo: serviceError)
			return
            
		}
		
		let responseModel = Mapper<BaseResponse<T.V>>().map(JSON: responseJSON)!
        if responseModel.data == nil && responseModel.status == nil {
            
            /*Response from the API could not be deserialize with one of the required fields: body or status. Marking this as an error..*/
            let serviceError = NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid)
            passErrorModel(requestInstance: ri, networkServiceErrorInfo: serviceError)
            return
        }
        
        /*Response is deserialize as expected.*/
        ri.callback?(responseModel, nil)
        
	}
	
	func passErrorModel<T:NetworkServiceDelegate>(requestInstance ri : ServiceCredentials<T>, networkServiceErrorInfo error : NetworkServiceErrorInfo)-> Void{
		ri.callback?(nil, error)
	}
		
}

/** Handles file uploads. 
    File types supported :
        - Text
        - Image
        - Audio/Video

	Initialization:
		- Initializer to upload service takes an optional identifier string. This identifier string can be used as an identifier to the background session that handles this request. 
		- Initializer also accepts an optional callback for progress values. 
			Service notifies about the progress of upload during the process via progress callback.

	Upload:
		- This is the method, client of upload service calls to upload multipart files. 
		- A key is required for the upload of single or multiple files.
		- Last parameter to the method is upload completion callback. Client receives a response object with service status or an error after the completion of upload task.
 */
open class UploadService<T:UploadServiceDelegate> : BaseRequestService {
    
    typealias UploadProgressCallback = (Progress) -> Void
    var uploadProgressCallback : UploadProgressCallback?
    
    var uploadRequestEnd : T
    var uploadRequestCredentials : ServiceCredentials<T>
    
    var uploadRequest : UploadRequest?
    
    init(uploadIdentifier : String?, uploadProgressCallback : UploadProgressCallback?) {
        
        if uploadProgressCallback != nil {
            self.uploadProgressCallback = uploadProgressCallback
        }
        
        uploadRequestEnd = T()
        uploadRequestCredentials = ServiceCredentials<T>()
        super.init(nsConfiguration: uploadRequestEnd.getNetworkServiceConfiguration(bundleIdForBackgroundService : uploadIdentifier))
    }
    
    deinit {
        printLog(log: "Deinitialized upload service.")
    }
    
    /** Uploads single or multiple files in a given key..*/
	func upload(withKey key : String, callback : @escaping (BaseResponse<T.V>?, NetworkServiceErrorInfo?) -> Void) {

        uploadRequestCredentials.callback = callback /*Callback closure instance of API Call..*/
        guard uploadRequestCredentials.callback != nil else {
            printLog(log: "Network Service Error : error in callback closure!")
            return
        }
        
        guard NetworkServiceConfiguration.validateServiceURL() else {
            
            let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.uploadRequestCredentials, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .networkRequestIncorrectURL))
            return
        }
        
        guard let uploadParameters = T.parameters, uploadParameters.count > 0 else {
            
            let clientInterface = ClientInterface()
            clientInterface.passErrorModel(requestInstance: self.uploadRequestCredentials, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .encodingMultiplartFile))
            return
        }
        
        let serviceURL = URL(string : NetworkServiceConfiguration.baseUrl+T.path)
		
        sessionManager?.upload(
			/*First append string data or URL to files in multipart form data.*/
            multipartFormData: { multipartFormData in
                for(_, value) in uploadParameters {
                    let paramString = value as? String
                    if paramString != nil {
                        if let paramFileURL = NSURL(string: paramString!) {
                            multipartFormData.append(paramFileURL as URL, withName: key)
                        } else {
                            multipartFormData.append(paramString!.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: key)
                        }
                    }
                }
            },
            usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold,
            to: serviceURL!,
            method : .post,
            headers : nil,
            encodingCompletion: { encodingResult in
                /*After encoding of multipart form data is complete (either with success or failure.)..*/
                switch encodingResult {
                case .success(let upload, _, _):
                    self.uploadRequest = upload.uploadProgress{ p in
                            /*Progress report..*/
                            self.uploadProgressCallback?(p)
                        }.validate(contentType : ["application/json"])
                        .validate(BaseRequestService.responseValidation)
                        .responseJSON { response in
							
                            NetworkServiceResponseHandler<T>(requestCredentials: self.uploadRequestCredentials)
                                .handleNetworkResponse(dataResponse: response)
                            
                            self.uploadRequest = nil
                    }
                case .failure( _):
                    
                    /** Pass encoding error info to the caller .. */
                    let clientInterface = ClientInterface()
                    clientInterface.passErrorModel(requestInstance: self.uploadRequestCredentials, networkServiceErrorInfo: NetworkServiceErrorInfo(networkServiceException: .encodingMultiplartFile))

                    self.uploadRequest = nil

                }
        })
        
    }
    
    func cancelUploadRequest() -> Void {
        self.uploadRequest?.cancel()
    }
}

/** Handles download requests.
	Considerations:
	MIME TYPES: Text, Image, Audio and Video
 
    The download service instance accepts an optional serviceConfiguration which is required to instantiate URL Session for the request.
    Download service is started with a background URL session by default.
    Each background session is provided a unique identifier. i.e. Each background service has a unique identifier.
    Client using the download service may also provide a callback closure during intialization to get progress updates from download request instance.
 
    It has only one method : download that the client can use to initiate the download. The download method takes argument for download path, fileName to save the download file and service callback closure.
*/
open class DownloadService : BaseRequestService {
    
    typealias DownloadProgressCallback = (Progress) -> Void
    typealias DownloadResponseCallback = (Any?, NetworkServiceErrorInfo?) -> Void
    
    var downloadProgressCallback : DownloadProgressCallback?
    var downloadResponseCallback : DownloadResponseCallback?
    
    var downloadRequest : DownloadRequest?
    
    init(serviceConfiguration : NetworkServiceConfiguration?, downloadIdentifier : String?, downloadProgressCallback : DownloadProgressCallback?) {
        
        var downloadServiceConfiguration = serviceConfiguration
        
        if downloadServiceConfiguration == nil {
            
            var configuration = NetworkServiceConfiguration()
            configuration.serviceSessionType = .backgroundService
            downloadServiceConfiguration = configuration
            
        }
        
        if downloadIdentifier != nil {
            
            downloadServiceConfiguration!.clientBundle = downloadIdentifier!
            
        }
        
        super.init(nsConfiguration: downloadServiceConfiguration!)
        
        if let dp = downloadProgressCallback {
            self.downloadProgressCallback = dp
        }

        printLog(log: "Download Service Intialized")
    }
    
    deinit {
        printLog(log: "Download Service Deinitialized")
    }
    
    /**Downloads the file into the device storage from the specified service resource.*/
    func download(downloadPath : String, fileName : String?, callback : @escaping DownloadResponseCallback) {
        
        self.downloadResponseCallback = callback
        guard NetworkServiceConfiguration.validateServiceURL() else {
            
            self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkRequestIncorrectURL))
            return
        }

        let serviceURL = URL(string : NetworkServiceConfiguration.baseUrl+downloadPath)
        let downloadRequestValidation : DownloadRequest.Validation = { urlRequest, urlResponse, temporaryURL, destinationURL -> Request.ValidationResult in
            
            switch urlResponse.statusCode {
            case 200...299 :
                return .success
                
            default:
                
                /*In the case of any other status codes..*/

                /*Create an error type of AFError as per the response status code..*/
                var responseError = NetworkServiceError()
                let reason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: urlResponse.statusCode)
                responseError.error = AFError.responseValidationFailed(reason: reason)
                responseError.data = nil
                return .failure(responseError)
                
            }
        }
        
        let destination: DownloadRequest.DownloadFileDestination = { _, response in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let nameOfFile = (fileName == nil) ? "New" : fileName
            let fileURL = documentsURL.appendingPathComponent(nameOfFile!)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        self.downloadRequest = sessionManager?.download(serviceURL!, to: destination)
            .downloadProgress { (pro) in
                if self.downloadProgressCallback != nil {
                    self.downloadProgressCallback!(pro)
                }
            }.responseData { (response) in

                self.parseDownloadResponse(downloadResponse: response)
                self.downloadRequest = nil
                
            }.validate(downloadRequestValidation)
        
    }
    
    private func parseDownloadResponse(downloadResponse : DownloadResponse<Data>?) {
        
        guard downloadResponse != nil else {
            
            if self.downloadResponseCallback == nil {
                printLog(log: "Error! Callback for download request is not available.")
                return
            }
            
            self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid))
            return
        }
        
        switch downloadResponse!.result {
            
            case .success(let value) :
            
                self.downloadResponseCallback!(value, nil)
            
            case .failure(let error):
								
                let responseError = error as? NetworkServiceError
                let afError = responseError?.error as? AFError
                
				guard responseError == nil, afError == nil else {
                    
                    if afError?.responseCode == 404 {
                        self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkResponseUnavailable))
                        return
                    }

                    self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid))
					return
				}
				
				if error._code == NSURLErrorNotConnectedToInternet {
					self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkConnection))
				}
				
				if error._code == NSURLErrorTimedOut {
                    self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkRequestTimedOut))
				}
				
				if error._code == NSURLErrorCancelled {
                    self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkRequestCancelled))
				}
				
				/**Otherwise..*/
                self.downloadResponseCallback!(nil, NetworkServiceErrorInfo(networkServiceException: .networkResponseInvalid))
			
        }
		
    }
	
}

/**
	Prints log message ..
*/
fileprivate func printLog(log : Any) -> Void {
	print(log)
    
    /*TODO..************************************************************/
//    printLog(log: httpRequest.allHTTPHeaderFields ?? "No HTTP Headers")
//    for(key, value) in httpRequest.allHTTPHeaderFields! {
//        print("\(key) \(value)")
//    }
    /*TODO..************************************************************/

}
