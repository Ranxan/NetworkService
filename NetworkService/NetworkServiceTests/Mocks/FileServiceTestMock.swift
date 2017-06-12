//
//  FileServiceTest.swift
//  SMS-iOS Template
//
//  Created by Ranjan Adhikari on 5/24/17.
//  Copyright © 2017 SMS. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

@testable import SMS_iOS_Template

/** Service Test Model.. */
class FileServiceTestModel : BaseModel {
    
    var id : Int?
    var userId : Int?
    var title : String?
    var body : String?
    
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

/** File upload Call configuration.. */
struct FileUploadConfiguration : UploadServiceDelegate {
    
    static var path = "/upload"
    static var method = NetworkServiceHTTPMethod.post
    typealias V = FileServiceTestModel /*Response Model Type..*/

    static var parameters : [String:Any]? = [:]
    
}

/** API Call configuration.. */
class FileServiceTestMock {
    
    static var MESSAGE_SUCCESS : String = "Success."
    static var MESSAGE_FAILURE : String = "Failure."
    
    var serviceTestResponseState : Bool? = false
    var serviceTestMessage : String?
    
    
    func uploadTextFile(withKey : String, identifier : String?, callback : @escaping (Bool) -> Void) {
        
        let FILE = "XFile.txt" //this is the file. we will write to and read from it
        let text = "Hi, welcome to another video of Cold Fusion. In this video .." //just a text
        
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            /**/
            callback(false)
            return
        }
        
        let path = dir.appendingPathComponent(FILE)
        do {
            try text.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            
            /***/
            FileUploadConfiguration.parameters?["file1"] = path.absoluteString
            FileUploadConfiguration.parameters?["file2"] = path.absoluteString
            
            UploadService<FileUploadConfiguration>(uploadIdentifier : identifier ){ p in
                    print(p.fractionCompleted)
                }.upload(withKey: withKey) { response, error in
                    
                    /***/
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
        } catch {
            print("Error writing to a file.")
            self.serviceTestResponseState = false
            self.serviceTestMessage = ServiceTestMock.MESSAGE_FAILURE
            callback(false)
        }
    }
    
    /***/
    func uploadImageFile(callback : @escaping (Bool) -> Void) {
        let image = UIImage(named: "icon_phone.png")
        
        guard let data = UIImagePNGRepresentation(image!) else {
            callback(false)
            return
        }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileName = documentsDirectory.appendingPathComponent("icon_phone.png")
        try? data.write(to: fileName)
        FileUploadConfiguration.path = fileName.absoluteString
        UploadService<FileUploadConfiguration>(uploadIdentifier : nil, uploadProgressCallback: nil)
            .upload(withKey: "ImageFile") { response, error in
                
                /*Hanlding response in the closure callback..*/
                guard let responseData = response else {
                    print(error as Any)
                    callback(false)
                    return
                }
                
                guard let data = responseData.data else {
                    print(responseData.status?.message ?? "Error!")
                    callback(false)
                    return
                }
                
                print(data)
                callback(true)
        }
    }
    
    /***/
    func uploadVideoFile(withKey : String, identifier : String?, callback : @escaping (Bool) -> Void) {
        
        guard var path = Bundle.main.path(forResource: "song", ofType: "mp4") else {
            print("File not found.")
            callback(false)
            return
        }
        
        let url = URL(fileURLWithPath: path)
        path = url.absoluteString
        print(path)
        FileUploadConfiguration.parameters?["file1"] = path

        UploadService<FileUploadConfiguration>(uploadIdentifier : nil, uploadProgressCallback: nil)
            .upload(withKey: withKey) { response, error in
                
                /*Hanlding response in the closure callback..*/
                guard let responseData = response else {
                    print(error as Any)
                    callback(false)
                    return
                }
                
                guard let data = responseData.data else {
                    print(responseData.status?.message ?? "Error!")
                    callback(false)
                    return
                }
                
                print(data)
                callback(true)
        }
        
    }
    
    /***/
    func downloadTextFile(fileName : String, path : String, downloadIdentifier : String?, callback : @escaping (Bool) -> Void) {
        
        DownloadService(serviceConfiguration: nil, downloadIdentifier : downloadIdentifier) { progress in
                print(progress.fractionCompleted)
            }.download(downloadPath: path, fileName: fileName) { response, error in
                
                /*Hanlding response in the closure callback..*/
                guard let responseData = response else {
                    print(error as Any)
                    callback(false)
                    return
                }
                
                do {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appendingPathComponent(fileName)
                    let filePath = try String(describing: fileURL)
                    
                    /*Reading file contents..*/
                    let file : FileHandle? = try FileHandle(forReadingFrom: fileURL)
                    if file != nil {
                        // Read all the data
                        let data = file?.readDataToEndOfFile()
                        // Close the file
                        file?.closeFile()
                        
                        // Convert our data to string
                        let str = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                        print(str)
                        callback(true)
                    }
                    else {
                        print("Ooops! Something went wrong!")
                        callback(false)
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                    callback(false)
                }
                
        }
    }
    
    func downloadMediaFile(fileName : String, path : String, downloadIdentifier : String?, callback : @escaping (Bool) -> Void){
        DownloadService(serviceConfiguration: nil, downloadIdentifier : downloadIdentifier) { progress in
            print(progress.fractionCompleted)
            }.download(downloadPath: path, fileName: fileName) { response, error in
                
                /*Hanlding response in the closure callback..*/
                guard let responseData = response else {
                    print(error as Any)
                    callback(false)
                    return
                }
                
                do {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appendingPathComponent(fileName)
                    let filePath = try String(describing: fileURL)
                    
                    /*Reading file contents..*/
                    let file : FileHandle? = try FileHandle(forReadingFrom: fileURL)
                    if file != nil {
                        callback(true)
                    }
                    else {
                        print("Ooops! Something went wrong!")
                        callback(false)
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                    callback(false)
                }
                
        }
    }

}
