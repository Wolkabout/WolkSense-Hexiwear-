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
    private let userCredentials: UserCredentials
    private let trackingDevice: TrackingDevice
    
    let concurrentDataStoreQueue = dispatch_queue_create("com.wolkabout.DataStoreQueue", DISPATCH_QUEUE_SERIAL) // synchronizes access to DataStore properties
    
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

    private var _points: [Device] = []
    var points: [Device] {
        get {
            var pointsCopy: [Device]!
            dispatch_sync(concurrentDataStoreQueue) {
                pointsCopy = self._points
            }
            return pointsCopy
        }
        
        set (newPoints) {
            dispatch_barrier_sync(self.concurrentDataStoreQueue) {

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
            }
        }
    }

    // CURRENT DEVICE POINT
    private var _currentDevicePoint: Device?
    var currentDevicePoint: Device? {
        get {
            var pointCopy: Device?
            dispatch_sync(concurrentDataStoreQueue) {
                pointCopy = self._currentDevicePoint
            }
            return pointCopy
        }
    }
    
    // FEEDS
    private var _pointFeeds: [Feed] = []
    var pointFeeds: [Feed] {
        get {
            var pointFeedsCopy: [Feed] = []
            dispatch_sync(concurrentDataStoreQueue) {
                pointFeedsCopy = self._pointFeeds
            }
            return pointFeedsCopy
        }
        
        set (newPointFeeds) {
            dispatch_barrier_sync(self.concurrentDataStoreQueue) {
                self._pointFeeds = newPointFeeds
            }
        }
    }
    
    func getDeviceNameForSerial(serial: String) -> String? {
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
    internal func fetchAll(onFailure:(Reason) -> (), onSuccess:() -> ()) {
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
    func getActivationStatusForSerial(serial: String, onFailure:(Reason) -> (), onSuccess: (activationStatus: String) -> ()) {
        // Check precondition
        guard !serial.isEmpty else {
            onSuccess(activationStatus: "NOT_ACTIVATED")
            return
        }
        webApi.getDeviceActivationStatus(serial, onFailure: onFailure, onSuccess: onSuccess)
    }

    
    // GET RANDOM SERIAL
    func getSerial(onFailure:(Reason) -> (), onSuccess: (serial: String) -> ()) {
        webApi.getRandomSerial(onFailure, onSuccess:onSuccess)
    }
    
    // ACTIVATE
    internal func activateDeviceWithSerialAndName(deviceSerial: String, deviceName: String,  onFailure: (Reason) -> (), onSuccess: (pointId: Int, password: String) -> ()) {
        // Check precondition
        guard !deviceSerial.isEmpty && !deviceName.isEmpty else {
            onFailure(.NoData)
            return
        }
        
        webApi.activateDevice(deviceSerial, deviceName: deviceName, onFailure: onFailure, onSuccess: onSuccess)
    }

    // DEACTIVATE
    internal func deactivateDevice(serialNumber: String, onFailure: (Reason) -> (), onSuccess: () -> ()) {
        // Check precondition
        guard !serialNumber.isEmpty else {
            onFailure(.NoData)
            return
        }
        
        webApi.deactivateDevice(serialNumber, onFailure: onFailure, onSuccess: onSuccess)
    }

}

//MARK:- User account management
extension DataStore {
    
    // SIGN UP
    internal func signUpWithAccount(account: Account, onFailure: (Reason) -> (), onSuccess: () -> ()) {
        webApi.signUp(account.firstName, lastName: account.lastName, email: account.email, password: account.password, onFailure: onFailure, onSuccess: onSuccess)
    }

    // SIGN IN
    internal func signInWithUsername(username: String, password: String, onFailure: (Reason) -> (), onSuccess: () -> ()) {
        webApi.signIn(username, password: password, onFailure: onFailure, onSuccess: onSuccess)
    }
    
    // RESET PASSWORD
    internal func resetPasswordForUserEmail(userEmail: String, onFailure: (Reason) -> (), onSuccess: () -> ()) {
        webApi.resetPassword(userEmail, onFailure: onFailure, onSuccess: onSuccess)
    }

    // CHANGE PASSWORD
    internal func changePasswordForUserEmail(userEmail: String, oldPassword: String, newPassword:String, onFailure: (Reason) -> (), onSuccess: () -> ()) {
        webApi.changePassword(userEmail, oldPassword: oldPassword, newPassword: newPassword, onFailure: onFailure, onSuccess: onSuccess)
    }

}
