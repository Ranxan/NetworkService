//
//  Exception.swift
//  SMS-iOS Template
//
//  Created by Ranjan Adhikari on 5/9/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation

/** Fundamental exceptions handled by the network service component. */
public enum NetworkServiceException : Error {
	case networkConnection
    case networkRequestCancelled
    case networkRequestIncorrectURL
    case networkResponseInvalid
    case encodingMultiplartFile
    case networkError(ExceptionCode, ExceptionStatus)
    case undefined
    
    case networkBadRequest
    case networkRequestAuthenticationFailure
    case networkRequestUserForbidden
    case networkResponseUnavailable
    case networkRequestMethodNotAllowed
	case networkRequestTimedOut
	case networkServiceUnavailable
}

/** Exception codes for corresponding exception. */
public enum ExceptionCode : Int {
	
    /*Custom status codes.*/
	case networkConnection = -1
	case networkRequestCancelled = -2
	case networkRequestIncorrectURL = -3 /*Service path URL is not correct .. */
    case networkResponseInvalid = -4
    case encodingMultiplartFile = -5
    case networkError = -6 /*Any error except the one especified by these exception codes.*/
    case undefined = -7
    
	case networkBadRequest = 400 /*HTTPRequest is not valid. For example, if type of data requested against identified by header. If expected JSON response does not have valid format. 
                                    Similarly another case would be expired refreshToken.*/
    case networkRequestAuthenticationFailure = 401 /*Authentication for the request failed.*/
    case networkRequestUserForbidden = 403 /**/
	case networkResponseUnavailable = 404 /*HTTP Request for a particular resource is unavailable.*/
    case networkRequestMethodNotAllowed = 405 /*Wrong method used for the HTTP Request.*/
    case networkRequestTimedOut = 408 /*Client request's timed out.*/
	case networkServiceUnavailable = 300 /*Network service location changed.*/
		
}

/** Exception messages for corresponding exception. */
public enum ExceptionStatus : String {
    
	case networkConnection = "Error in network connection."
    case networkRequestCancelled = "Network request has been cancelled."
    case networkRequestIncorrectURL = "Incorrect URL."
    case networkResponseInvalid = "API response is not valid."
    case encodingMultiplartFile = "Error encoding multipart file."
    case networkError = "Network error."
    case undefined = "Could not identify an error."
    
    case networkBadRequest = "Bad network request."
    case networkRequestAuthenticationFailure = "Network request token error."
    case networkRequestUserForbidden = "User is forbidden for the request."
    case networkResponseUnavailable = "API response unavailable."
    case networkRequestMethodNotAllowed = "HTTP Request method is not allowed."
	case networkRequestTimedOut = "Network request timed out."
	case networkServiceUnavailable = "API service is not available."
	
}

/** Wraps response data available from the service API if available, otherwise carries an error of type NSError (or Error). 
    It is only used by the network service component internally.
*/
struct NetworkServiceError : Error {
	var error : Error?
	var data : Data?
}

/** Carries error information (with error code and status message) generated during HTTP Requests or handling of HTTP Response.*/
public struct NetworkServiceErrorInfo {

    var errorCode : ExceptionCode
    var errorMessage : ExceptionStatus
	
	init() {
		errorCode = ExceptionCode.undefined
		errorMessage = ExceptionStatus.undefined
	}
	
	init(exceptionCode ec : ExceptionCode, exceptionMessage em : ExceptionStatus) {
		errorCode = ec
		errorMessage = em
	}
	
	init(networkServiceException : NetworkServiceException) {
		
		switch networkServiceException {
		case .networkConnection:
			errorCode = .networkConnection
			errorMessage = .networkConnection
        case .networkRequestCancelled:
            errorCode = .networkRequestCancelled
            errorMessage = .networkRequestCancelled
        case .networkRequestIncorrectURL:
            errorCode = .networkRequestIncorrectURL
            errorMessage = .networkRequestIncorrectURL
        case .networkResponseInvalid:
            errorCode = .networkResponseInvalid
            errorMessage = .networkResponseInvalid
        case .encodingMultiplartFile:
            errorCode = .encodingMultiplartFile
            errorMessage = .encodingMultiplartFile
        case .networkBadRequest:
            errorCode = .networkBadRequest
            errorMessage = .networkBadRequest
		case .networkRequestAuthenticationFailure:
            errorCode = .networkRequestAuthenticationFailure
            errorMessage = .networkRequestAuthenticationFailure
        case .networkRequestUserForbidden:
            errorCode = .networkRequestUserForbidden
            errorMessage = .networkRequestUserForbidden
        case .networkResponseUnavailable:
            errorCode = .networkResponseUnavailable
            errorMessage = .networkResponseUnavailable
        case .networkRequestMethodNotAllowed:
            errorCode = .networkRequestMethodNotAllowed
            errorMessage = .networkRequestMethodNotAllowed
        case .networkRequestTimedOut:
            errorCode = .networkRequestTimedOut
            errorMessage = .networkRequestTimedOut
		case .networkServiceUnavailable:
            errorCode = .networkServiceUnavailable
            errorMessage = .networkServiceUnavailable
		case .networkError(let code, let message):
            errorCode = .networkError
            errorMessage = .networkError
		default:
            errorCode = .undefined
            errorMessage = .undefined
		}
	}
	
}
