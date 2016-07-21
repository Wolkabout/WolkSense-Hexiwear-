//
//  Hexiwear application is used to pair with Hexiwear BLE devices
//  and send sensor readings to WolkSense sensor data cloud
//
//  Copyright (C) 2016 WolkAbout Technology s.r.o.
//
//  Hexiwear is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Hexiwear is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  WebAPI.swift
//

import Foundation
import UIKit
import CoreLocation


public enum Reason {
    case InvalidRequest
    case AccessTokenExpired
    case Cancelled
    case CouldNotParseResponse
    case NoData
    case NoSuccessStatusCode(statusCode: Int)
    case Other(NSError)
}

func defaultSimpleFailureHandler(failureReason: Reason) {
    switch failureReason {
    case .InvalidRequest:
        print("Invalid request")
    case .AccessTokenExpired:
        print("Access token expired")
    case .Cancelled:
        print("Request cancelled")
    case .CouldNotParseResponse:
        print("Could not parse JSON")
    case .NoData:
        print("No data")
    case .NoSuccessStatusCode(let statusCode):
        print("No success status code: \(statusCode)")
    case .Other(let err):
        print("Other error \(err.description)")
    }
}

func setNetworkActivityIndicatorVisible(visible: Bool) {
    dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = visible
    }
}

public class WebAPIConfiguration {
    let session: NSURLSession
    let refreshTokenTimeout: NSTimeInterval
    let pageSize: Int
    let isNetworkActivityIndicated: Bool
    let userCredentials: UserCredentials
    let wolkaboutURL = "https://api.wolksense.com/api"
    
    init(session: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()),
         refreshTokenTimeout: NSTimeInterval = 20 * 60, // 20 minutes
        pageSize: Int = 20,
        isNetworkActivityIndicated: Bool = true,
        userCredentials: UserCredentials = UserCredentials())
    {
        self.session = session
        self.refreshTokenTimeout = refreshTokenTimeout
        self.pageSize = pageSize
        self.isNetworkActivityIndicated = isNetworkActivityIndicated
        self.userCredentials = userCredentials
    }
}

public class WebAPI {
    
    public static let sharedWebAPI = WebAPI()
    
    var defaultFailureHandler: (Reason) -> () {
        get {
            return defaultSimpleFailureHandler
        }
    }
    
    private let HTTP_OK = 200
    private let configuration: WebAPIConfiguration
    
    private lazy var requestQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "com.wolkabout.Hexiwear.webAPIQueue"
        queue.maxConcurrentOperationCount = 1 // 1 running request allowed
        return queue
    }()
    
    init(webAPIConfiguration: WebAPIConfiguration = WebAPIConfiguration()) {
        self.configuration = webAPIConfiguration
    }
    
    deinit {
        cancelRequests()
    }
    
    func cancelRequests() {
        if configuration.isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(false) }
        requestQueue.cancelAllOperations()
    }
    
    
    //MARK: - Device management functions
    
    // GET ACTIVATION STATUS
    func getDeviceActivationStatus(deviceSerialNumber: String, onFailure:(Reason) -> (), onSuccess: (activationStatus: String) -> ()) {
        
        guard !deviceSerialNumber.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)/activation_status"
        
        let onSuccessConverter = { [unowned self] (let responseData: NSData?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding) else {
                    onFailure(.CouldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).stringByReplacingOccurrencesOfString("\r", withString: "")
            responseString = responseString.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            let status = self.getActivationStatusFromString(responseString)
            status.isEmpty ? onFailure(.NoData)
                : onSuccess(activationStatus: status)
        }
        
        let getDeviceStatusOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: nil, method: "GET", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(getDeviceStatusOperation)
    }
    
    //  GET RANDOM SERIAL
    func getRandomSerial(onFailure:(Reason) -> (), onSuccess: (serial: String) -> ()) {
        let requestURL = configuration.wolkaboutURL + "/v3/devices/random_serial"
        let queryString = "?type=HEXIWEAR"
        
        let onSuccessConverter = { [unowned self] (let responseData: NSData?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding) else {
                    onFailure(.CouldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).stringByReplacingOccurrencesOfString("\r", withString: "")
            responseString = responseString.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            let serialNumber = self.getSerialFromString(responseString)
            serialNumber.isEmpty ? onFailure(.NoData)
                : onSuccess(serial: serialNumber)
        }
        
        let getRandomSerialOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: queryString, requestData: nil, method: "GET", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(getRandomSerialOperation)
    }
    
    // ACTIVATE
    func activateDevice(deviceSerialNumber: String, deviceName: String, onFailure:(Reason) -> (), onSuccess: (pointId: Int, password: String) -> ()) {
        
        guard !deviceSerialNumber.isEmpty && !deviceName.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)"
        
        let requestJson: [String:AnyObject] = ["name": deviceName]
        guard let requestData = try? NSJSONSerialization.dataWithJSONObject(requestJson, options: NSJSONWritingOptions.PrettyPrinted) else {
            onFailure(.InvalidRequest)
            return
        }
        
        let onSuccessConverter = { [unowned self] (let responseData: NSData?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding) else {
                    onFailure(.CouldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).stringByReplacingOccurrencesOfString("\r", withString: "")
            responseString = responseString.stringByReplacingOccurrencesOfString("\n", withString: "")
            
            if let pointNumber = self.getPointIdFromString(responseString) {
                let password = self.getPasswordFromString(responseString)
                onSuccess(pointId: pointNumber, password: password)
            }
            else {
                onFailure(.NoData)
            }
        }
        
        let activateDeviceOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(activateDeviceOperation)
    }
    
    
    // DEACTIVATE
    func deactivateDevice(deviceSerialNumber: String, onFailure:(Reason) -> (), onSuccess: () -> ()) {
        guard !deviceSerialNumber.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)"
        
        let onSuccessConverter = { (_: NSData?) in onSuccess() }
        
        let deactivateOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: nil, method: "DELETE", sendAuthorisationToken: true, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(deactivateOperation)
    }
    
    
    // FETCH POINTS
    func fetchPoints(onFailure:(Reason) -> (), onSuccess: ([Device]) -> ()) {
        let requestURL = configuration.wolkaboutURL + "/v3/points"
        
        let onSuccessConverter = { (let responseData: NSData?) in
            // Response data can be deserialized to JSON
            guard let responseData = responseData, jsonArrayOfDict = try? NSJSONSerialization.JSONObjectWithData(responseData, options: []) as! [[String:AnyObject]] else {
                onFailure(.CouldNotParseResponse)
                return
            }
            
            // Generate result from JSON
            var result = [Device]()
            result = jsonArrayOfDict.reduce([]) { (accum, elem) in
                var accum = accum
                if let item = Device.parseDeviceJSON(elem) {
                    accum.append(item)
                }
                return accum
            }
            onSuccess(result)
        }
        
        let fetchOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: nil, method: "GET", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(fetchOperation)
    }
    
    
    //MARK: - User account management functions
    
    // SIGN UP
    func signUp(firstName: String, lastName: String, email: String, password: String, onFailure:(Reason) -> (), onSuccess: () -> ()) {
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/signUp"
        let requestJson: [String:AnyObject] = ["firstName": firstName, "lastName": lastName, "email": email, "password": password]
        print(requestJson)
        guard let requestData = try? NSJSONSerialization.dataWithJSONObject(requestJson, options: NSJSONWritingOptions.PrettyPrinted) else {
            onFailure(.InvalidRequest)
            return
        }
        
        let onSuccessConverter = { (_: NSData?) in onSuccess() }
        
        let signUpOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: false, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(signUpOperation)
    }
    
    
    //SIGN IN
    func signIn(username: String, password: String, onFailure:(Reason) -> (), onSuccess: () -> ()) {
        guard !username.isEmpty && !password.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/signIn"
        let requestJson: [String:AnyObject] = ["email": username, "password": password]
        guard let requestData = try? NSJSONSerialization.dataWithJSONObject(requestJson, options: NSJSONWritingOptions.PrettyPrinted) else {
            onFailure(.InvalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (let responseData: NSData?) in
            self.configuration.userCredentials.accessToken = ""
            // Response data can be deserialized to JSON
            guard let responseData = responseData, credentials = try? NSJSONSerialization.JSONObjectWithData(responseData, options: []) as! [String:String] else {
                onFailure(.CouldNotParseResponse)
                return
            }
            
            self.configuration.userCredentials.storeCredentials(credentials)
            onSuccess()
        }
        
        let signInOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken:false, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(signInOperation)
    }
    
    // RESET PASSWORD
    func resetPassword(userEmail: String, onFailure:(Reason) -> (), onSuccess: () -> ()) {
        guard !userEmail.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/reset-password"
        let requestJson: [String:AnyObject] = ["email": userEmail]
        guard let requestData = try? NSJSONSerialization.dataWithJSONObject(requestJson, options: NSJSONWritingOptions.PrettyPrinted) else {
            onFailure(.InvalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (_: NSData?) in onSuccess() }
        
        let verifyOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: false, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(verifyOperation)
    }
    
    // CHANGE PASSWORD
    func changePassword(userEmail: String, oldPassword: String, newPassword: String, onFailure:(Reason) -> (), onSuccess: () -> ()) {
        guard !oldPassword.isEmpty && !newPassword.isEmpty && !userEmail.isEmpty else { onFailure(.InvalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/change-password"
        let requestJson: [String:AnyObject] = ["email": userEmail, "oldPassword": oldPassword, "newPassword": newPassword]
        guard let requestData = try? NSJSONSerialization.dataWithJSONObject(requestJson, options: NSJSONWritingOptions.PrettyPrinted) else {
            onFailure(.InvalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (_: NSData?) in onSuccess() }
        
        let verifyOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: true, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(verifyOperation)
    }
    
}

//MARK: - Private functions
extension WebAPI {
    
    //MARK:- WolkAboutWebRequest
    private class WolkAboutWebRequest: NSOperation {
        private unowned let webApi: WebAPI
        private let requestURL: String
        private let queryString: String?
        private let requestData: NSData?
        private let method: String
        private let sendAuthorisationToken: Bool
        private let isResponseDataExpected: Bool
        private let isNetworkActivityIndicated: Bool
        private let failure: (Reason) -> ()
        private let success: (NSData?) -> ()
        
        // Request/response vars
        private let requestURLPath: String
        private var request: NSMutableURLRequest!
        private var failureReason: Reason?
        private var result: NSData?
        
        // Async task management
        private var responseSemaphore: NSCondition!
        private var responseReceived = false
        
        init (webApi: WebAPI, requestURL: String, queryString: String?, requestData: NSData?, method: String, sendAuthorisationToken: Bool, isResponseDataExpected: Bool, isNetworkActivityIndicated: Bool, onFailure:(Reason) -> (), onSuccess: (NSData?) -> ()) {
            self.webApi = webApi
            self.requestURL = requestURL
            self.queryString = queryString
            self.requestData = requestData
            self.method = method
            self.sendAuthorisationToken = sendAuthorisationToken
            self.isResponseDataExpected = isResponseDataExpected
            self.isNetworkActivityIndicated = isNetworkActivityIndicated
            self.failure = onFailure
            self.success = onSuccess
            
            self.requestURLPath = requestURL + (queryString ?? "")
        }
        
        override func main() {
            
            // Bounce if cancelled
            guard !cancelled else {
                failure(Reason.Cancelled)
                return
            }
            
            // Bounce if access token expired
            if sendAuthorisationToken {
                guard webApi.checkAccessToken() else {
                    failure(.AccessTokenExpired)
                    return
                }
            }
            
            // Bounce if cancelled
            guard !cancelled else {
                failure(Reason.Cancelled)
                return
            }
            request = webApi.createWebAPIRequest(requestURLPath, method: method, jsonData: requestData, sendAuthorisationToken: sendAuthorisationToken)
            
            // Bounce if cancelled
            guard !cancelled else {
                failure(Reason.Cancelled)
                return
            }
            responseSemaphore = NSCondition()
            
            if isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(true) }
            
            let task = webApi.configuration.session.dataTaskWithRequest(request) { data, response, error in
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // There is no error
                guard error == nil else {
                    self.failureReason = .Other(error!)
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // Response is valid
                guard let httpResponse = response as? NSHTTPURLResponse else {
                    self.failureReason = .NoData
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // Response status code is successful
                guard httpResponse.statusCode == self.webApi.HTTP_OK else {
                    self.failureReason = .NoSuccessStatusCode(statusCode: httpResponse.statusCode)
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // Is response data expected (i.e. exit if only statusCode is needed)
                guard self.isResponseDataExpected else {
                    self.failureReason = nil
                    self.result = nil
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // There is response data
                guard let responseData = data else {
                    self.failureReason = .NoData
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.cancelled else {
                    self.failureReason = .Cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // signal that data task is done
                self.result = responseData
                self.signalResponseReceived()
                
            }
            task.resume()
            
            // wait for async data task to end
            responseSemaphore.lock()
            while !responseReceived {
                responseSemaphore.wait()
            }
            responseSemaphore.unlock()
            
            if isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(false) }
            
            // Callback success or failure
            if let reason = failureReason {
                failure(reason)
            }
            else {
                success(result)
            }
        }
        
        private func signalResponseReceived() {
            // signal that data task is done
            responseSemaphore.lock()
            responseReceived = true
            responseSemaphore.signal()
            responseSemaphore.unlock()
        }
    }
    
    // Create REQUEST
    private func createWebAPIRequest(requestURLPath: String, method: String = "GET", jsonData: NSData? = nil, sendAuthorisationToken: Bool = true) -> NSMutableURLRequest {
        let requestURLPathEscaped = requestURLPath.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        let requestURL: NSURL = NSURL(string: requestURLPathEscaped!)!
        let request = NSMutableURLRequest(URL: requestURL)
        request.HTTPMethod = method
        
        if let data = jsonData {
            let postDataLengthString = "\(data.length)"
            request.setValue(postDataLengthString, forHTTPHeaderField: "Content-Length")
            request.HTTPBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let accessToken = configuration.userCredentials.accessToken where sendAuthorisationToken {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        print(request)
        return request
    }
    
    private func makeQueryString(dict: [String:String]) -> String {
        var keyValuePairs = ""
        for (k, v) in dict {
            keyValuePairs += "\(k)=\(v)&"
        }
        return keyValuePairs == "" ? "" : "?\(keyValuePairs[keyValuePairs.startIndex..<keyValuePairs.endIndex.predecessor()])"
    }
    
    private func checkAccessToken() -> Bool {
        
        if !(configuration.userCredentials.accessTokenExpires != nil && configuration.userCredentials.accessTokenExpires!.timeIntervalSinceNow < configuration.refreshTokenTimeout) {
            return true
        }
        
        let responseSemaphore: NSCondition = NSCondition()
        var responseReceived = false
        var accessTokenOk = false
        
        if configuration.userCredentials.accessTokenExpires != nil && configuration.userCredentials.accessTokenExpires!.timeIntervalSinceNow < configuration.refreshTokenTimeout {
            let content = String("{\"refreshToken\":\"\(configuration.userCredentials.refreshToken!)\"}");
            guard let jsonData = content.dataUsingEncoding(NSUTF8StringEncoding) else {
                configuration.userCredentials.clearCredentials()
                return false
            }
            
            if configuration.isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(true) }
            
            let refreshRequest = createWebAPIRequest(configuration.wolkaboutURL + "/refreshToken", jsonData: jsonData, method: "POST")
            configuration.session.dataTaskWithRequest(refreshRequest) { [unowned self] (let data, let response, let error) in
                // Response is valid
                guard let httpResponse = response as? NSHTTPURLResponse else {
                    self.configuration.userCredentials.clearCredentials()
                    
                    // signal that data task is done
                    responseSemaphore.lock()
                    responseReceived = true
                    responseSemaphore.signal()
                    responseSemaphore.unlock()
                    return
                }
                
                // Response status code is successful
                guard httpResponse.statusCode == self.HTTP_OK else {
                    self.configuration.userCredentials.clearCredentials()
                    
                    // signal that data task is done
                    responseSemaphore.lock()
                    responseReceived = true
                    responseSemaphore.signal()
                    responseSemaphore.unlock()
                    return
                }
                
                // There is response data
                guard let responseData = data else {
                    self.configuration.userCredentials.clearCredentials()
                    
                    // signal that data task is done
                    responseSemaphore.lock()
                    responseReceived = true
                    responseSemaphore.signal()
                    responseSemaphore.unlock()
                    return
                }
                
                guard let credentials = try? NSJSONSerialization.JSONObjectWithData(responseData, options: [.MutableContainers]) as! [String:String] else {
                    self.configuration.userCredentials.clearCredentials()
                    
                    // signal that data task is done
                    responseSemaphore.lock()
                    responseReceived = true
                    responseSemaphore.signal()
                    responseSemaphore.unlock()
                    return
                }
                
                
                self.configuration.userCredentials.storeCredentials(credentials)
                accessTokenOk = true
                
                // signal that data task is done
                responseSemaphore.lock()
                responseReceived = true
                responseSemaphore.signal()
                responseSemaphore.unlock()
                
                }.resume()
            
            // wait for async data task to end
            responseSemaphore.lock()
            while !responseReceived {
                responseSemaphore.wait()
            }
            responseSemaphore.unlock()
            
            if configuration.isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(false) }
            
        }
        return accessTokenOk
    }
    
    private func getActivationStatusFromString(jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "activationStatus")
    }
    
    private func getSerialFromString(jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "serial")
    }
    
    private func getPointIdFromString(jsonString: String) -> Int? {
        return getIntFromJSON(jsonString, key: "pointId")
    }
    
    private func getPasswordFromString(jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "password")
    }
    
    private func getStringFromJSON(jsonString: String, key: String) -> String {
        do {
            if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
                authenticationResponse = try NSJSONSerialization.JSONObjectWithData(data, options: [.MutableContainers]) as? NSDictionary,
                stringValue = authenticationResponse[key] as? String
            {
                return stringValue
            }
        }
        catch {
            return ""
        }
        
        return ""
    }
    
    private func getIntFromJSON(jsonString: String, key: String) -> Int? {
        do {
            if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding),
                authenticationResponse = try NSJSONSerialization.JSONObjectWithData(data, options: [.MutableContainers]) as? NSDictionary,
                intValue = authenticationResponse[key] as? Int
            {
                return intValue
            }
            
        }
        catch {
            return nil
        }
        
        return nil
    }
}
