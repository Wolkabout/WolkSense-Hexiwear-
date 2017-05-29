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
    case invalidRequest
    case accessTokenExpired
    case cancelled
    case couldNotParseResponse
    case noData
    case noSuccessStatusCode(statusCode: Int, data: String?)
    case other(NSError)
}

func defaultSimpleFailureHandler(_ failureReason: Reason) {
    switch failureReason {
    case .invalidRequest:
        print("Invalid request")
    case .accessTokenExpired:
        print("Access token expired")
    case .cancelled:
        print("Request cancelled")
    case .couldNotParseResponse:
        print("Could not parse JSON")
    case .noData:
        print("No data")
    case .noSuccessStatusCode(let statusCode):
        print("No success status code: \(statusCode)")
    case .other(let err):
        print("Other error \(err.description)")
    }
}

func setNetworkActivityIndicatorVisible(_ visible: Bool) {
    DispatchQueue.main.async {
        UIApplication.shared.isNetworkActivityIndicatorVisible = visible
    }
}

open class WebAPIConfiguration {
    let session: URLSession
    let refreshTokenTimeout: TimeInterval
    let pageSize: Int
    let isNetworkActivityIndicated: Bool
    let userCredentials: UserCredentials
    let wolkaboutURL = "https://api.wolksense.com/api"
    
    init(session: URLSession = URLSession(configuration: URLSessionConfiguration.default),
         refreshTokenTimeout: TimeInterval = 20 * 60, // 20 minutes
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

open class WebAPI {
    
    open static let sharedWebAPI = WebAPI()
    
    var defaultFailureHandler: (Reason) -> () {
        get {
            return defaultSimpleFailureHandler
        }
    }
    
    fileprivate let HTTP_OK = 200
    fileprivate let configuration: WebAPIConfiguration
    
    fileprivate lazy var requestQueue: OperationQueue = {
        var queue = OperationQueue()
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
    func getDeviceActivationStatus(_ deviceSerialNumber: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  (_ activationStatus: String) -> ()) {
        
        guard !deviceSerialNumber.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)/activation_status"
        
        let onSuccessConverter = { [unowned self] (responseData: Data?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                let dataString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue) else {
                    onFailure(.couldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).replacingOccurrences(of: "\r", with: "")
            responseString = responseString.replacingOccurrences(of: "\n", with: "")
            
            let status = self.getActivationStatusFromString(responseString)
            status.isEmpty ? onFailure(.noData)
                : onSuccess(status)
        }
        
        let getDeviceStatusOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: nil, method: "GET", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(getDeviceStatusOperation)
    }
    
    //  GET RANDOM SERIAL
    func getRandomSerial(_ onFailure: @escaping (Reason) -> (), onSuccess: @escaping  (_ serial: String) -> ()) {
        let requestURL = configuration.wolkaboutURL + "/v3/devices/random_serial"
        let queryString = "?type=HEXIWEAR"
        
        let onSuccessConverter = { [unowned self] (responseData: Data?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                let dataString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue) else {
                    onFailure(.couldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).replacingOccurrences(of: "\r", with: "")
            responseString = responseString.replacingOccurrences(of: "\n", with: "")
            
            let serialNumber = self.getSerialFromString(responseString)
            serialNumber.isEmpty ? onFailure(.noData)
                : onSuccess(serialNumber)
        }
        
        let getRandomSerialOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: queryString, requestData: nil, method: "GET", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(getRandomSerialOperation)
    }
    
    // ACTIVATE
    func activateDevice(_ deviceSerialNumber: String, deviceName: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  (_ pointId: Int, _ password: String) -> ()) {
        
        guard !deviceSerialNumber.isEmpty && !deviceName.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)"
        
        let requestJson: [String:AnyObject] = ["name": deviceName as AnyObject]
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestJson, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            onFailure(.invalidRequest)
            return
        }
        
        let onSuccessConverter = { [unowned self] (responseData: Data?) in
            
            // Response data can be deserialized to String
            guard let responseData = responseData,
                let dataString = NSString(data: responseData, encoding: String.Encoding.utf8.rawValue) else {
                    onFailure(.couldNotParseResponse)
                    return
            }
            
            var responseString: String = String(dataString).replacingOccurrences(of: "\r", with: "")
            responseString = responseString.replacingOccurrences(of: "\n", with: "")
            
            if let pointNumber = self.getPointIdFromString(responseString) {
                let password = self.getPasswordFromString(responseString)
                onSuccess(pointNumber, password)
            }
            else {
                onFailure(.noData)
            }
        }
        
        let activateDeviceOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: true, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(activateDeviceOperation)
    }
    
    
    // DEACTIVATE
    func deactivateDevice(_ deviceSerialNumber: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  () -> ()) {
        guard !deviceSerialNumber.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/devices/\(deviceSerialNumber)"
        
        let onSuccessConverter = { (_: Data?) in onSuccess() }
        
        let deactivateOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: nil, method: "DELETE", sendAuthorisationToken: true, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(deactivateOperation)
    }
    
    
    // FETCH POINTS
    func fetchPoints(_ onFailure: @escaping (Reason) -> (), onSuccess: @escaping  ([Device]) -> ()) {
        let requestURL = configuration.wolkaboutURL + "/v3/points"
        
        let onSuccessConverter = { (responseData: Data?) in
            // Response data can be deserialized to JSON
            guard let responseData = responseData, let jsonArrayOfDict = try? JSONSerialization.jsonObject(with: responseData, options: []) as! [[String:AnyObject]] else {
                onFailure(.couldNotParseResponse)
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
    func signUp(_ firstName: String, lastName: String, email: String, password: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  () -> ()) {
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/signUp"
        let requestJson: [String:AnyObject] = ["firstName": firstName as AnyObject, "lastName": lastName as AnyObject, "email": email as AnyObject, "password": password as AnyObject]
        print(requestJson)
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestJson, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            onFailure(.invalidRequest)
            return
        }
        
        let onSuccessConverter = { (_: Data?) in onSuccess() }
        
        let signUpOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: false, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(signUpOperation)
    }
    
    
    //SIGN IN
    func signIn(_ username: String, password: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  () -> ()) {
        guard !username.isEmpty && !password.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/signIn"
        let requestJson: [String:AnyObject] = ["email": username as AnyObject, "password": password as AnyObject]
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestJson, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            onFailure(.invalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (responseData: Data?) in
            self.configuration.userCredentials.accessToken = ""
            // Response data can be deserialized to JSON
            guard let responseData = responseData, let credentials = try? JSONSerialization.jsonObject(with: responseData, options: []) as! [String:String] else {
                onFailure(.couldNotParseResponse)
                return
            }
            
            self.configuration.userCredentials.storeCredentials(credentials as NSDictionary)
            onSuccess()
        }
        
        let signInOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken:false, isResponseDataExpected: true, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(signInOperation)
    }
    
    // RESET PASSWORD
    func resetPassword(_ userEmail: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  () -> ()) {
        guard !userEmail.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/reset-password"
        let requestJson: [String:AnyObject] = ["email": userEmail as AnyObject]
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestJson, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            onFailure(.invalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (_: Data?) in onSuccess() }
        
        let verifyOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: false, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(verifyOperation)
    }
    
    // CHANGE PASSWORD
    func changePassword(oldPassword: String, newPassword: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  () -> ()) {
        guard !oldPassword.isEmpty && !newPassword.isEmpty else { onFailure(.invalidRequest); return }
        
        let requestURL = configuration.wolkaboutURL + "/v2/change-password"
        let requestJson: [String:AnyObject] = ["oldPassword": oldPassword as AnyObject, "newPassword": newPassword as AnyObject]
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestJson, options: JSONSerialization.WritingOptions.prettyPrinted) else {
            onFailure(.invalidRequest)
            return
        }
        
        
        let onSuccessConverter = { (_: Data?) in onSuccess() }
        
        let verifyOperation = WolkAboutWebRequest(webApi: self, requestURL: requestURL, queryString: nil, requestData: requestData, method: "POST", sendAuthorisationToken: true, isResponseDataExpected: false, isNetworkActivityIndicated: configuration.isNetworkActivityIndicated, onFailure: onFailure, onSuccess: onSuccessConverter)
        requestQueue.addOperation(verifyOperation)
    }
    
}

//MARK: - Private functions
extension WebAPI {
    
    //MARK:- WolkAboutWebRequest
    fileprivate class WolkAboutWebRequest: Operation {
        fileprivate unowned let webApi: WebAPI
        fileprivate let requestURL: String
        fileprivate let queryString: String?
        fileprivate let requestData: Data?
        fileprivate let method: String
        fileprivate let sendAuthorisationToken: Bool
        fileprivate let isResponseDataExpected: Bool
        fileprivate let isNetworkActivityIndicated: Bool
        fileprivate let failure: (Reason) -> ()
        fileprivate let success: (Data?) -> ()
        
        // Request/response vars
        fileprivate let requestURLPath: String
        fileprivate var request: NSMutableURLRequest!
        fileprivate var failureReason: Reason?
        fileprivate var result: Data?
        
        // Async task management
        fileprivate var responseSemaphore: NSCondition!
        fileprivate var responseReceived = false
        
        init (webApi: WebAPI, requestURL: String, queryString: String?, requestData: Data?, method: String, sendAuthorisationToken: Bool, isResponseDataExpected: Bool, isNetworkActivityIndicated: Bool, onFailure: @escaping (Reason) -> (), onSuccess: @escaping (Data?) -> ()) {
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
            guard !isCancelled else {
                failure(Reason.cancelled)
                return
            }
            
            // Bounce if access token expired
            if sendAuthorisationToken {
                guard webApi.checkAccessToken() else {
                    failure(.accessTokenExpired)
                    return
                }
            }
            
            // Bounce if cancelled
            guard !isCancelled else {
                failure(Reason.cancelled)
                return
            }
            request = webApi.createWebAPIRequest(requestURLPath, method: method, jsonData: requestData, sendAuthorisationToken: sendAuthorisationToken)
            
            // Bounce if cancelled
            guard !isCancelled else {
                failure(Reason.cancelled)
                return
            }
            responseSemaphore = NSCondition()
            
            if isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(true) }
            
            let task = webApi.configuration.session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                // Bounce if cancelled
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // There is no error
                guard error == nil else {
                    self.failureReason = .other(error! as NSError)
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // Response is valid
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.failureReason = .noData
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // Response status code is successful
                guard httpResponse.statusCode == self.webApi.HTTP_OK else {
                    // Sign up - duplicated email
                    // { "code": "USER_EMAIL_IS_NOT_UNIQUE", "message": "Data constraint error occurred with code" }
                    
                    // Sign in - wrong credentials
                    // { "code": "CREDENTIALS_ARE_INVALID", "message": "Unauthorized error occurred with code" }
                    
                    
                    print("!!!! HTTP status code = \(httpResponse.statusCode) for request \(self.method) \(self.requestURL)\(self.queryString ?? "")")
                    
                    var dataString: String? = nil
                    if let data = data {
                        dataString = String(data: data, encoding: .utf8)
                        print(dataString ?? "no data")
                    }
                    self.failureReason = .noSuccessStatusCode(statusCode: httpResponse.statusCode, data: dataString)
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
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
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // There is response data
                guard let responseData = data else {
                    self.failureReason = .noData
                    self.signalResponseReceived()
                    return
                }
                
                // Bounce if cancelled
                guard !self.isCancelled else {
                    self.failureReason = .cancelled
                    self.signalResponseReceived()
                    return
                }
                
                // signal that data task is done
                self.result = responseData
                self.signalResponseReceived()
                
            })
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
        
        fileprivate func signalResponseReceived() {
            // signal that data task is done
            responseSemaphore.lock()
            responseReceived = true
            responseSemaphore.signal()
            responseSemaphore.unlock()
        }
    }
    
    // Create REQUEST
    fileprivate func createWebAPIRequest(_ requestURLPath: String, method: String = "GET", jsonData: Data? = nil, sendAuthorisationToken: Bool = true) -> NSMutableURLRequest {
        let requestURLPathEscaped = requestURLPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        let requestURL: URL = URL(string: requestURLPathEscaped!)!
        let request = NSMutableURLRequest(url: requestURL)
        request.httpMethod = method
        
        if let data = jsonData {
            let postDataLengthString = "\(data.count)"
            request.setValue(postDataLengthString, forHTTPHeaderField: "Content-Length")
            request.httpBody = data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if let accessToken = configuration.userCredentials.accessToken, sendAuthorisationToken {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        print(request)
        return request
    }
    
    fileprivate func makeQueryString(_ dict: [String:String]) -> String {
        var keyValuePairs = ""
        for (k, v) in dict {
            keyValuePairs += "\(k)=\(v)&"
        }
        return keyValuePairs == "" ? "" : "?\(keyValuePairs[keyValuePairs.startIndex..<keyValuePairs.characters.index(before: keyValuePairs.endIndex)])"
    }
    
    fileprivate func checkAccessToken() -> Bool {
        
        if !(configuration.userCredentials.accessTokenExpires != nil && configuration.userCredentials.accessTokenExpires!.timeIntervalSinceNow < configuration.refreshTokenTimeout) {
            return true
        }
        
        let responseSemaphore: NSCondition = NSCondition()
        var responseReceived = false
        var accessTokenOk = false
        
        if configuration.userCredentials.accessTokenExpires != nil && configuration.userCredentials.accessTokenExpires!.timeIntervalSinceNow < configuration.refreshTokenTimeout {
            let content = String("{\"refreshToken\":\"\(configuration.userCredentials.refreshToken!)\"}");
            guard let jsonData = content?.data(using: String.Encoding.utf8) else {
                configuration.userCredentials.clearCredentials()
                return false
            }
            
            if configuration.isNetworkActivityIndicated { setNetworkActivityIndicatorVisible(true) }
            
            let refreshRequest = createWebAPIRequest(configuration.wolkaboutURL + "/refreshToken", method: "POST", jsonData: jsonData)
            configuration.session.dataTask(with: refreshRequest as URLRequest, completionHandler: { [unowned self] (data, response, error) in
                // Response is valid
                guard let httpResponse = response as? HTTPURLResponse else {
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
                
                guard let credentials = try? JSONSerialization.jsonObject(with: responseData, options: [.mutableContainers]) as! [String:String] else {
                    self.configuration.userCredentials.clearCredentials()
                    
                    // signal that data task is done
                    responseSemaphore.lock()
                    responseReceived = true
                    responseSemaphore.signal()
                    responseSemaphore.unlock()
                    return
                }
                
                
                self.configuration.userCredentials.storeCredentials(credentials as NSDictionary)
                accessTokenOk = true
                
                // signal that data task is done
                responseSemaphore.lock()
                responseReceived = true
                responseSemaphore.signal()
                responseSemaphore.unlock()
                
            }) .resume()
            
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
    
    fileprivate func getActivationStatusFromString(_ jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "activationStatus")
    }
    
    fileprivate func getSerialFromString(_ jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "serial")
    }
    
    fileprivate func getPointIdFromString(_ jsonString: String) -> Int? {
        return getIntFromJSON(jsonString, key: "pointId")
    }
    
    fileprivate func getPasswordFromString(_ jsonString: String) -> String {
        return getStringFromJSON(jsonString, key: "password")
    }
    
    fileprivate func getStringFromJSON(_ jsonString: String, key: String) -> String {
        do {
            if let data = jsonString.data(using: String.Encoding.utf8),
                let authenticationResponse = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? NSDictionary,
                let stringValue = authenticationResponse[key] as? String
            {
                return stringValue
            }
        }
        catch {
            return ""
        }
        
        return ""
    }
    
    fileprivate func getIntFromJSON(_ jsonString: String, key: String) -> Int? {
        do {
            if let data = jsonString.data(using: String.Encoding.utf8),
                let authenticationResponse = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? NSDictionary,
                let intValue = authenticationResponse[key] as? Int
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
