//
//  NetworkCallerTests.swift
//  SMS-iOS Template
//
//  Created by Ranxan Adhikari on 5/8/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import XCTest

@testable import SMS_iOS_Template

class NetworkCallerTests: XCTestCase {

    
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
        
        NetworkServiceConfiguration.baseUrl = "http://52.187.44.240/api"
        TestRequestConfiguration.path = "/mirror"
        TestRequestConfiguration.method = .get

	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	/**
		Test Cases
	
		1. Positive scenario
        - Test if service endpoint path (Base URL) has correct format.
        - Test valid credentials are provided for POST request
        - Test POST request is successful
        - Test valid credentials are provided for GET request
        - Test GET request is successful
        - Test request is completed within the given timeout value.
        - Test context in response callback is not cleared by ARC
		- Test multiple requests work in parallel.
		- Test Text files are uploaded successfully.
		- Test Image files are uploaded successfully.
		- Test Video files are uploaded successfully.
        - Test redirection becomes sucessfully.
     
     
     
		2. Negative Scenario
        - Test wrong format for the service path is handled with appropriate exception.
        - Test invalid credentials for POST requests are handled with appropriate exception.
        - Test POST request failure is handled with appropriate exception.
        - Test invalid credentials for GET requests are handled with appropriate exception.
        - Test GET request failure is handled with appropriate exception.
        - Test request timedout is handled with appropriate exception.
        - Test reference to context being nil is handled with appropriate exception.
		- Test failure of Text files uploads is handled with appropriate exception.
		- Test failure of Image files uploads is handled with appropriate exception.
		- Test failure of Video files uploads is handled with appropriate exception.
	*/
	
    /** This test unit verifies API call with correct service end point succeeds. : For example correct URL such as http://abc.com/path.
     If service end point and path have correct formats, this test must pass.
    **/
    func testHTTPRequestWithCorrectURL() {
        let theExpectation = expectation(description: "The Expectation")
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil
        networkServiceClient.call { serviceTestResponseState in
            XCTAssertTrue(NSPredicate(format: "SELF MATCHES %@", "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)").evaluate(with: NetworkServiceConfiguration.baseUrl), "Service URL must have correct format to pass this test.")
            XCTAssertTrue(serviceTestResponseState, "Callback response must be true for the successful API call with correct URL. ")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** This test unit verifies API call with wrong format of service end point fails. : For example wrong URL such as htp://abc.com/path/..\..//
     If service end point and path have correct formats, this test must pass.
     **/
    func testHTTPRequestWithWrongURL() {
        let theExpectation = expectation(description: "The Expectation")
        NetworkServiceConfiguration.baseUrl += "htp://abc.com/path/...." /*Setting wrong URL format..*/
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.call { serviceTestResponseState in
            XCTAssertFalse(NSPredicate(format: "SELF MATCHES %@", "(?i)https?://(?:www\\.)?\\S+(?:/|\\b)").evaluate(with: NetworkServiceConfiguration.baseUrl), "Service URL needed to have wrong format to pass this test.")
            XCTAssertFalse(serviceTestResponseState, "Service call response must have false state with wrong URL format.")
            XCTAssertEqual(networkServiceClient.serviceTestMessage, ExceptionStatus.networkRequestIncorrectURL.rawValue)
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
        
    }
    
    /** This test unit tests for a successful POST request with correct request paramters. **/
    func testPostRequestIsSuccessful() {

        /*Prepare credentials for the POST request.*/
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.method = NetworkServiceHTTPMethod.post
        TestRequestConfiguration.path = "/mirror"
        
        let networkServiceClient = ServiceTestMock()
        let testModel = TestModel()
        networkServiceClient.requestParams = testModel.toJSON()
        
        networkServiceClient.call { status in
            XCTAssertTrue(status, "Post request has to be successful with correct credentials.")
            XCTAssertEqual("Title", testModel.title)
            XCTAssertEqual("Body", testModel.body)
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** This test unit tests for failure POST request with given correct credentials but wrong/unexpected response.
     1. Invalid respones (response as text)
     2. Invalid JSON response (response as an empty JSON object or with arbitrary members)
     **/
    func testPostRequestFailure() {
        
        /*Prepare credentials for the POST request.*/
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.path = "/invalid/response123"
        //        TestRequestConfiguration.path = "/invalid/json"
        TestRequestConfiguration.method = NetworkServiceHTTPMethod.post
        
        let networkServiceClient = ServiceTestMock()
        let testModel = TestModel()
        networkServiceClient.requestParams = testModel.toJSON()
        
        networkServiceClient.call { status in
            XCTAssertFalse(status, "Post request has to fail with wrong response.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** This test unit verifies multiple POST requests from same (single) thread succeeds with correct credentials.
     **/
    func testParallelPostRequestsFromSingleThread() {

        /*Prepare credentials for the POST request.*/
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.method = NetworkServiceHTTPMethod.post
        
        let testModel1 = TestModel()
        testModel1.id = 1
        testModel1.body = "Body 1"
        testModel1.title = "Title 1"
        let networkServiceTestClient1 = ServiceTestMock()
        networkServiceTestClient1.requestParams = testModel1.toJSON()
        
        let testModel2 = TestModel()
        testModel2.id = 2
        testModel2.body = "Body 2"
        testModel2.title = "Title 2"
        let networkServiceTestClient2 = ServiceTestMock()
        networkServiceTestClient2.requestParams = testModel2.toJSON()
        
        let testModel3 = TestModel()
        testModel3.id = 3
        testModel3.body = "Body 3"
        testModel3.title = "Title 3"
        let networkServiceTestClient3 = ServiceTestMock()
        networkServiceTestClient3.requestParams = testModel3.toJSON()
        
        var count = 0;
        
        DispatchQueue.global(qos: .userInitiated).sync {
            
            networkServiceTestClient1.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 1", testModel1.title)
                XCTAssertEqual("Body 1", testModel1.body)
                
                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }
            }
            
            networkServiceTestClient2.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 2", testModel2.title)
                XCTAssertEqual("Body 2", testModel2.body)

                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }
            }
            
            networkServiceTestClient3.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 3", testModel3.title)
                XCTAssertEqual("Body 3", testModel3.body)
                
                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }

            }
            
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }

    /** Test unit tests for multiple POST requests from different threads.**/
    func testParallelPostRequestsFromMulitpleThreads() {
        
        /*Prepare credentials for the POST request.*/
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.method = NetworkServiceHTTPMethod.post
        
        let testModel1 = TestModel()
        testModel1.id = 1
        testModel1.body = "Body 1"
        testModel1.title = "Title 1"
        let networkServiceTestClient1 = ServiceTestMock()
        networkServiceTestClient1.requestParams = testModel1.toJSON()
        
        let testModel2 = TestModel()
        testModel2.id = 2
        testModel2.body = "Body 2"
        testModel2.title = "Title 2"
        let networkServiceTestClient2 = ServiceTestMock()
        networkServiceTestClient2.requestParams = testModel2.toJSON()
        
        let testModel3 = TestModel()
        testModel3.id = 3
        testModel3.body = "Body 3"
        testModel3.title = "Title 3"
        let networkServiceTestClient3 = ServiceTestMock()
        networkServiceTestClient3.requestParams = testModel3.toJSON()
        
        var count = 0;
        
        DispatchQueue.global(qos: .userInitiated).async {
            networkServiceTestClient1.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 1", testModel1.title)
                XCTAssertEqual("Body 1", testModel1.body)
                
                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }
                
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            networkServiceTestClient2.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 2", testModel2.title)
                XCTAssertEqual("Body 2", testModel2.body)

                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }

            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            networkServiceTestClient3.call { status in
                XCTAssertTrue(status, "Post request has to pass with correct credentials from any thread instance.")
                XCTAssertEqual("Title 3", testModel3.title)
                XCTAssertEqual("Body 3", testModel3.body)

                count += 1
                if count == 3 {
                    theExpectation.fulfill()
                }

            }
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
	/** Test unit tests for successful GET request with given correct credentials.
	**/
	func testGetRequestIsSuccessful() {
        
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.path = "/test/required?id=1"
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil
        
        let testModel = TestModel()
        
		networkServiceClient.call { status in
			XCTAssertTrue(status, "Get request has to be successful with correct credentials.")
			XCTAssertEqual("Title", testModel.title)
			XCTAssertEqual("Body", testModel.body)
			XCTAssertTrue(networkServiceClient.serviceTestResponseState!, "Service call response must have true state with correct credentials and HTTP Status Code 200.")
			theExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 20) { error in
			if let error = error {
				XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
			}
		}
	}
    
    /** Test unit tests for failure of GET request with wrong/insufficient credentials (get request parameters.).**/
    func testGetRequestFailure() {
        
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.path = "/test/required"
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil

        networkServiceClient.call { status in
            XCTAssertFalse(status, "Get request has to fail with wrong or insufficient credentials.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for successful request for authentication token.
     **/
    func testSuccessfulRequestForAuthenticationToken() {
        let theExpectation = expectation(description: "The Expectation")
        let oAuthClient = UserAuthentication()
        oAuthClient.requestParams = UserModel().toJSON()
        oAuthClient.receiveAuthToken { status in
            XCTAssertTrue(status, "Test has to pass with correct user credentials to get authentication token.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for failure request for authentication token.
     **/
    func testFailureRequestForAuthenticationToken() {
        let theExpectation = expectation(description: "The Expectation")
        let oAuthClient = UserAuthentication()
        oAuthClient.requestParams = nil
        oAuthClient.receiveAuthToken { status in
            XCTAssertFalse(status, "Test has to fail with wrong user credentials to get authentication token.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** This test unit tests for multiple POST requests with token refresh.
	**/
    func testParallelPostRequestsWithTokenRefresh() {
		
        let theExpectation = expectation(description: "The Expectation")

        TestRequestConfiguration.method = .post

        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil
        let testModel = TestModel()
        
        var count = 0
        
        let networkServiceClient1 = ServiceTestMock()
        networkServiceClient1.requestParams = testModel.toJSON()
        networkServiceClient1.call { status in
            XCTAssertTrue(status, "Post request has to fail with wrong response.")
            
            count += 1
            if count == 2 {
                theExpectation.fulfill()
            }
            
        }
        
        let networkServiceClient2 = ServiceTestMock()
        networkServiceClient2.requestParams = testModel.toJSON()
        networkServiceClient2.call { status in
            XCTAssertTrue(status, "Post request has to fail with wrong response.")
            
            count += 1
            if count == 2 {
                theExpectation.fulfill()
            }
            
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
	/** This test unit tests for multiple POST requests from different threads with token refresh.
	**/
	func testParallelPostRequestsFromMultipleThreadsWithTokenRefresh() {
        let theExpectation = expectation(description: "The Expectation")

        TestRequestConfiguration.method = .post
        
		var count = 0
		
		DispatchQueue.global(qos: .userInitiated).async {
            let testModel1 = TestModel()
            testModel1.title = "Title 1"
            testModel1.body = "Body 1"
            
			let networkServiceClient1 = ServiceTestMock()
			networkServiceClient1.requestParams = testModel1.toJSON()
			networkServiceClient1.call { status in
				XCTAssertTrue(status, "Post request has to fail with wrong response.")
				count += 1
				if count == 2 {
					theExpectation.fulfill()
				}
			}
		}

		DispatchQueue.global(qos: .userInitiated).async {
            let testModel2 = TestModel()
            testModel2.title = "Title 2"
            testModel2.body = "Body 2"
            
			let networkServiceClient2 = ServiceTestMock()
			networkServiceClient2.requestParams = testModel2.toJSON()
			networkServiceClient2.call { status in
				XCTAssertTrue(status, "Post request has to fail with wrong response.")
				count += 1
				if count == 2 {
					theExpectation.fulfill()
				}
			}
		}

		waitForExpectations(timeout: 20) { error in
			if let error = error {
				XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
			}
		}
	}
    
    /**Test unit tests for successful redirection with token refresh.*/
    func testSuccessfulRedirectionWithTokenRefresh() {

        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.path = "/redirect/success"
        TestRequestConfiguration.method = .get
        
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil
        networkServiceClient.call { status in
            XCTAssertTrue(status, "Redirection has to succeed with token refresh.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /**Test unit tests for failure redirection with wrong response content along with token refresh.*/
    func testFailureRedirectionWithTokenRefresh() {
        let theExpectation = expectation(description: "The Expectation")
        TestRequestConfiguration.path = "/redirect/failure"
        TestRequestConfiguration.method = .get
        
        let networkServiceClient = ServiceTestMock()
        networkServiceClient.requestParams = nil
        networkServiceClient.call { status in
            XCTAssertFalse(status, "Redirection has to faile with wrong response contents.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for upload of text files with background thread.
     **/
    func testSuccessfulUploadOfTextFiles() {
        let theExpectation = expectation(description: "The Expectation")
        FileUploadConfiguration.path = "/upload"
        let fileServiceClient = FileServiceTestMock()
        
        fileServiceClient.uploadTextFile(withKey: "files[]", identifier: nil) { status in
            XCTAssertTrue(status, "Upload request has to be successful with valid path to a .txt file and file key.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests failure of upload of text files.**/
    func testFailureUploadOfTextFiles() {
        let theExpectation = expectation(description: "The Expectation")
        FileUploadConfiguration.path = "/upload"
        let fileServiceClient = FileServiceTestMock()
        
        fileServiceClient.uploadTextFile(withKey: "",  identifier: nil) { status in
            XCTAssertFalse(status, "Upload request has to fail with invalid file key/name")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for upload of text files from different threads..*/
    func testUploadOfTextFilesFromDifferentThreads() {
        let theExpectation = expectation(description: "The Expectation")
        FileUploadConfiguration.path = "/upload"

        var count = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileServiceClient1 = FileServiceTestMock()
            fileServiceClient1.uploadTextFile(withKey: "files[]", identifier: "id1") { status in
                print("Received 1")
                XCTAssertTrue(status, "Upload request has to be successful with valid path to a .txt file.")
                count += 1
                if count == 2 {
                    theExpectation.fulfill()
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileServiceClient2 = FileServiceTestMock()
            fileServiceClient2.uploadTextFile(withKey: "files[]", identifier: "identifier") { status in
                print("Received 2")
                XCTAssertTrue(status, "Upload request has to be successful with valid path to a .txt file.")
                count += 1
                if count == 2 {
                    theExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
        
    }
    
    /** Test unit tests for upload of media file with background thread.
     **/
    func testSuccessfulUploadOfMediaFile() {
        let theExpectation = expectation(description: "The Expectation")
        FileUploadConfiguration.path = "/upload"
        let fileServiceClient = FileServiceTestMock()
        
        fileServiceClient.uploadVideoFile(withKey: "files[]", identifier: nil) { status in
            XCTAssertTrue(status, "Upload request has to be successful with valid path to a .txt file and file key.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2000) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for successful download of text files with background thread.
     **/
    func testSuccessfulDownloadOfTextFiles() {
        let theExpectation = expectation(description: "The Expectation")
        let fileServiceClient = FileServiceTestMock()
        fileServiceClient.downloadTextFile(fileName: "NewFile1", path: "/download?type=pdf", downloadIdentifier: "downloaID1") { status in
            XCTAssertTrue(status, "The text file has to be downloaded with successful request.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }

    /** Test unit tests for successful download of media files with background thread.
     **/
    func testSuccessfulDownloadOfMediaFiles() {
        let theExpectation = expectation(description: "The Expectation")
        let fileServiceClient = FileServiceTestMock()
        fileServiceClient.downloadMediaFile(fileName: "NewSong", path: "/download?type=video", downloadIdentifier: "downloaIdentifier") { status in
            XCTAssertTrue(status, "The text file has to be downloaded with successful request.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2000) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
    }
    
    /** Test unit tests for failure download of text files with background thread.
     **/
    func testFailureDownloadOfTextFiles() {
        let theExpectation = expectation(description: "The Expectation")
        let fileServiceClient = FileServiceTestMock()
        fileServiceClient.downloadTextFile(fileName: "NewFile2", path: "/download", downloadIdentifier: "downloaID1") { status in
            XCTAssertFalse(status, "The download of text file has to fail with unsuccessful request.")
            theExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
        
    }
    
    /** Test unit tests for download of text files from different threads..*/
    func testDownloadOfTextFilesFromDifferentThreads() {
        let theExpectation = expectation(description: "The Expectation")
        var count = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let fileServiceClient1 = FileServiceTestMock()
            fileServiceClient1.downloadTextFile(fileName: "NewFile3", path: "/download?type=xml", downloadIdentifier: "downloaID1") { status in
                XCTAssertTrue(status, "The download of text file has to be successful with correct request credentials.")
                count += 1
                if count == 2 {
                    theExpectation.fulfill()
                }
            }
            
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fileServiceClient2 = FileServiceTestMock()
            fileServiceClient2.downloadTextFile(fileName: "NewFile4", path: "/download?type=xml", downloadIdentifier: "downloaID2") { status in
                XCTAssertTrue(status, "The download of text file has to be successful with correct request credentials.")
                count += 1
                if count == 2 {
                    theExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("EXPECTATION TIMEDOUT ERROR. \(error)")
            }
        }
        
    }
    

}
