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
//  DataStore.swift
//

import Foundation

class DataStore {
    
    let webApi: WebAPI
    fileprivate let userCredentials: UserCredentials
    fileprivate let trackingDevice: TrackingDevice
    
    let concurrentDataStoreQueue = DispatchQueue(label: "com.wolkabout.DataStoreQueue", attributes: []) // synchronizes access to DataStore properties
    
    init(webApi: WebAPI, userCredentials: UserCredentials, trackingDevice: TrackingDevice) {
        self.webApi = webApi
        self.userCredentials = userCredentials
        self.trackingDevice = trackingDevice
    }
    
    func clearDataStore() {
        self.pointFeeds = []
        self.points = []
    }
    
    //MARK:- Properties
    
    fileprivate var _points: [Device] = []
    var points: [Device] {
        get {
            var pointsCopy: [Device]!
            concurrentDataStoreQueue.sync {
                pointsCopy = self._points
            }
            return pointsCopy
        }
        
        set (newPoints) {
            self.concurrentDataStoreQueue.sync(flags: .barrier, execute: {
                
                // devices
                self._points = newPoints
                
                // feeds
                var feeds = [Feed]()
                for point in newPoints {
                    if let enabledFeeds = point.enabledFeeds() {
                        feeds += enabledFeeds
                    }
                }
                self._pointFeeds = feeds
            })
        }
    }
    
    // CURRENT DEVICE POINT
    fileprivate var _currentDevicePoint: Device?
    var currentDevicePoint: Device? {
        get {
            var pointCopy: Device?
            concurrentDataStoreQueue.sync {
                pointCopy = self._currentDevicePoint
            }
            return pointCopy
        }
    }
    
    // FEEDS
    fileprivate var _pointFeeds: [Feed] = []
    var pointFeeds: [Feed] {
        get {
            var pointFeedsCopy: [Feed] = []
            concurrentDataStoreQueue.sync {
                pointFeedsCopy = self._pointFeeds
            }
            return pointFeedsCopy
        }
        
        set (newPointFeeds) {
            self.concurrentDataStoreQueue.sync(flags: .barrier, execute: {
                self._pointFeeds = newPointFeeds
            })
        }
    }
    
    func getDeviceNameForSerial(_ serial: String) -> String? {
        for point in self.points {
            if point.deviceSerial == serial {
                return point.name
            }
        }
        return nil
    }
    
}



//MARK:- Fetch points and fetch all (points + messages)
extension DataStore {
    
    // FETCH ALL
    internal func fetchAll(_ onFailure: @escaping (Reason) -> (), onSuccess: @escaping () -> ()) {
        // POINTS
        webApi.fetchPoints(onFailure) { dev in
            self.points = dev
            onSuccess()
        }
    }
}

//MARK:- Device management
extension DataStore {
    // GET ACTIVATION STATUS for serial
    func getActivationStatusForSerial(_ serial: String, onFailure: @escaping (Reason) -> (), onSuccess: @escaping  (_ activationStatus: String) -> ()) {
        // Check precondition
        guard !serial.isEmpty else {
            onSuccess("NOT_ACTIVATED")
            return
        }
        webApi.getDeviceActivationStatus(serial, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    
    // GET RANDOM SERIAL
    func getSerial(_ onFailure: @escaping (Reason) -> (), onSuccess: @escaping  (_ serial: String) -> ()) {
        webApi.getRandomSerial(onFailure, onSuccess:onSuccess)
    }
    
    // ACTIVATE
    internal func activateDeviceWithSerialAndName(_ deviceSerial: String, deviceName: String,  onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  (_ pointId: Int, _ password: String) -> ()) {
        // Check precondition
        guard !deviceSerial.isEmpty && !deviceName.isEmpty else {
            onFailure(.noData)
            return
        }
        
        webApi.activateDevice(deviceSerial, deviceName: deviceName, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    // DEACTIVATE
    internal func deactivateDevice(_ serialNumber: String, onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  () -> ()) {
        // Check precondition
        guard !serialNumber.isEmpty else {
            onFailure(.noData)
            return
        }
        
        webApi.deactivateDevice(serialNumber, onFailure: onFailure, onSuccess: onSuccess)
    }
    
}

//MARK:- User account management
extension DataStore {
    
    // SIGN UP
    internal func signUpWithAccount(_ account: Account, onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  () -> ()) {
        webApi.signUp(account.firstName, lastName: account.lastName, email: account.email, password: account.password, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    // SIGN IN
    internal func signInWithUsername(_ username: String, password: String, onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  () -> ()) {
        webApi.signIn(username, password: password, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    // RESET PASSWORD
    internal func resetPasswordForUserEmail(_ userEmail: String, onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  () -> ()) {
        webApi.resetPassword(userEmail, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    // CHANGE PASSWORD
    internal func changePasswordForUserEmail(oldPassword: String, newPassword:String, onFailure: @escaping  (Reason) -> (), onSuccess: @escaping  () -> ()) {
        webApi.changePassword(oldPassword: oldPassword, newPassword: newPassword, onFailure: onFailure, onSuccess: onSuccess)
    }
    
}
