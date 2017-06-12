//
//  NetworkServiceOAuthHandler.swift
//  SMS-iOS Template
//
//  Created by Ranxan Adhikari on 5/15/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import ObjectMapper

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

/** Defines requirements for network service call to refresh the authentication token.*/
struct OAuthTokenServiceRequirements : NetworkServiceDelegate {

	static var path : String = "/auth/refresh"
	static var method = NetworkServiceHTTPMethod.post
	typealias V = OAuthTokenModel /*Response*/
	
}

/** Service manages authentication tokens for OAuth Validations.
    For the token expired, it resets token values stored in the user defaults, calls API to refresh the tokens and stores new authentication token with refresh token in the userdefaults.
*/
class OAuthTokenService {
		
    static let TAG = "OAuthTokenService"
    
	/** Service instances **/
	var networkCallCompletionHandler : NetworkServiceCallStatusCallback?
    
    static let AUTHENTICATION_TOKEN : String = "AUTHENTICATION_TOKEN"
    static let AUTHENTICATION_REFRESH_TOKEN : String = "AUTHENTICATION_REFRESH_TOKEN"
	
	static var authenticationToken = ""
	static var authenticationRefreshToken = ""
	
	init() {
	}
	
    /*Calls network service API caller to refresh the authentication token. */
	func refreshToken(completionCallback : @escaping NetworkServiceCallStatusCallback) {
		self.networkCallCompletionHandler = completionCallback
        
        NetworkService<OAuthTokenServiceRequirements>().call(requestParams : OAuthTokenModel().toJSON()) { data, error in
            
            /*Hanlding response in the closure callback..*/
            guard let responseData = data, let oAuthModel = responseData.data else {
                /*Hanlde error..*/
                print(error?.errorMessage ?? "ERROR: refreshToken : \(OAuthTokenService.TAG) ")
                OAuthTokenService.resetAuthTokens()
                self.networkCallCompletionHandler!(false)
                return
            }
            
            OAuthTokenService.saveOAuthTokens(authenticationModel: oAuthModel)
            self.networkCallCompletionHandler!(true)
        }
	}
	
    /**Persisting authentication tokens .. */
    static func saveOAuthTokens(authenticationModel oAuthModel : OAuthTokenModel) -> Void {
        let userDefaults = UserDefaults.standard
        userDefaults.set(oAuthModel.refreshToken, forKey: OAuthTokenService.AUTHENTICATION_REFRESH_TOKEN)
        userDefaults.set(oAuthModel.accessToken, forKey: OAuthTokenService.AUTHENTICATION_TOKEN)
        
        OAuthTokenService.authenticationRefreshToken = oAuthModel.refreshToken!
        OAuthTokenService.authenticationToken = oAuthModel.accessToken!
    }
    
    static func resetAuthTokens() {
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: OAuthTokenService.AUTHENTICATION_TOKEN)
        OAuthTokenService.authenticationToken = ""
    }

    static func findOAuthToken() -> Bool {
        if OAuthTokenService.authenticationToken.characters.count == 0 {
            let userDefaults = UserDefaults.standard
            if let AUTH_TOKEN = userDefaults.string(forKey: OAuthTokenService.AUTHENTICATION_TOKEN) {
                OAuthTokenService.authenticationToken = AUTH_TOKEN
            }
        }
		
		if OAuthTokenService.authenticationToken.characters.count == 0 {
			return false
		}
		
		return true
    }
    
    static func findOAuthRefreshToken() -> Bool {
        if OAuthTokenService.authenticationRefreshToken.characters.count == 0 {
            let userDefaults = UserDefaults.standard
            if let REFRESH_TOKEN = userDefaults.string(forKey: OAuthTokenService.AUTHENTICATION_REFRESH_TOKEN) {
                OAuthTokenService.authenticationRefreshToken = REFRESH_TOKEN
            }
        }
		
		if OAuthTokenService.authenticationRefreshToken.characters.count == 0 {
			return false
		}
		
		return true
    }

}
