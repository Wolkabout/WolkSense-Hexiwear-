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
//  TrackingDevice.swift
//

import Foundation
import CoreLocation

class TrackingDevice {
    
    let preferences = UserDefaults.standard
    
    
    // Account specific properties
    var userAccount: String = "" {
        didSet {
            print("Tracking device account: \(userAccount)")
        }
    }
    
    //example: "hexi1,wolk1|hexi2,wolk2|hexi3,wolk3|hexi4,wolk4"
    var hexiAndWolkSerials: String {
        get {
            if let hi  = preferences.object(forKey: "\(userAccount)-hexiAndWolkSerials") as? String {
                return hi
            }
            return ""
        }
        set (newHI) {
            preferences.set(newHI, forKey: "\(userAccount)-hexiAndWolkSerials")
            preferences.synchronize()
        }
    }
    
    // Account agnostic properties
    
    var trackingIsOff: Bool {
        get {
            return preferences.bool(forKey: "trackingIsOff")
        }
        set (newTracking) {
            preferences.set(newTracking, forKey: "trackingIsOff")
            preferences.synchronize()
        }
    }
    
    var lastPublished: Date? {
        get {
            if let lp = preferences.object(forKey: "deviceLastPublished") as? Date {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.set(newLP, forKey: "deviceLastPublished")
            preferences.synchronize()
        }
    }
    
    /* HEXI  start*/
    var lastSensorReadingDate: Date? {
        get {
            if let lp = preferences.object(forKey: "lastSensorReadingDate") as? Date {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.set(newLP, forKey: "lastSensorReadingDate")
            preferences.synchronize()
        }
    }
    
    var lastTemperature: Double? {
        get {
            if let lp = preferences.object(forKey: "lastTemperature") as? Double {
                return lp
            }
            return nil
        }
        set (newLT) {
            preferences.set(newLT, forKey: "lastTemperature")
            preferences.synchronize()
        }
    }
    
    var lastAirPressure: Double? {
        get {
            if let lp = preferences.object(forKey: "lastAirPressure") as? Double {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.set(newLP, forKey: "lastAirPressure")
            preferences.synchronize()
        }
    }
    
    var lastAirHumidity: Double? {
        get {
            if let lp = preferences.object(forKey: "lastAirHumidity") as? Double {
                return lp
            }
            return nil
        }
        set (newLAH) {
            preferences.set(newLAH, forKey: "lastAirHumidity")
            preferences.synchronize()
        }
    }
    
    var lastLight: Double? {
        get {
            if let lp = preferences.object(forKey: "lastLight") as? Double {
                return lp
            }
            return nil
        }
        set (newLAH) {
            preferences.set(newLAH, forKey: "lastLight")
            preferences.synchronize()
        }
    }
    
    var lastAccelerationX: Double? {
        get {
            if let lp = preferences.object(forKey: "lastAccelerationX") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.set(newLAC, forKey: "lastAccelerationX")
            preferences.synchronize()
        }
    }
    
    var lastAccelerationY: Double? {
        get {
            if let lp = preferences.object(forKey: "lastAccelerationY") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.set(newLAC, forKey: "lastAccelerationY")
            preferences.synchronize()
        }
    }
    
    var lastAccelerationZ: Double? {
        get {
            if let lp = preferences.object(forKey: "lastAccelerationZ") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.set(newLAC, forKey: "lastAccelerationZ")
            preferences.synchronize()
        }
    }
    
    var lastGyroX: Double? {
        get {
            if let lp = preferences.object(forKey: "lastGyroX") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.set(newLAG, forKey: "lastGyroX")
            preferences.synchronize()
        }
    }
    
    var lastGyroY: Double? {
        get {
            if let lp = preferences.object(forKey: "lastGyroY") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.set(newLAG, forKey: "lastGyroY")
            preferences.synchronize()
        }
    }
    
    var lastGyroZ: Double? {
        get {
            if let lp = preferences.object(forKey: "lastGyroZ") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.set(newLAG, forKey: "lastGyroZ")
            preferences.synchronize()
        }
    }
    
    var lastMagnetX: Double? {
        get {
            if let lp = preferences.object(forKey: "lastMagnetX") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.set(newMAG, forKey: "lastMagnetX")
            preferences.synchronize()
        }
    }
    
    var lastMagnetY: Double? {
        get {
            if let lp = preferences.object(forKey: "lastMagnetY") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.set(newMAG, forKey: "lastMagnetY")
            preferences.synchronize()
        }
    }
    
    var lastMagnetZ: Double? {
        get {
            if let lp = preferences.object(forKey: "lastMagnetZ") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.set(newMAG, forKey: "lastMagnetZ")
            preferences.synchronize()
        }
    }
    
    var lastSteps: Int? {
        get {
            if let lp = preferences.object(forKey: "lastSteps") as? Int {
                return lp
            }
            return nil
        }
        set (newSteps) {
            preferences.set(newSteps, forKey: "lastSteps")
            preferences.synchronize()
        }
    }
    
    var lastCalories: Int? {
        get {
            if let lp = preferences.object(forKey: "lastCalories") as? Int {
                return lp
            }
            return nil
        }
        set (newCalories) {
            preferences.set(newCalories, forKey: "lastCalories")
            preferences.synchronize()
        }
    }
    
    var lastHeartRate: Int? {
        get {
            if let lp = preferences.object(forKey: "lastHeartRate") as? Int {
                return lp
            }
            return nil
        }
        set (newHR) {
            preferences.set(newHR, forKey: "lastHeartRate")
            preferences.synchronize()
        }
    }
    
    var lastHexiwearMode: Int? {
        get {
            if let lp = preferences.object(forKey: "lastHexiwearMode") as? Int {
                return lp
            }
            return nil
        }
        set (newHR) {
            preferences.set(newHR, forKey: "lastHexiwearMode")
            preferences.synchronize()
        }
    }
    
    
    var isBatteryOff: Bool {
        get {
            return preferences.bool(forKey: "isBatteryOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isBatteryOff")
            preferences.synchronize()
        }
    }
    
    var isTemperatureOff: Bool {
        get {
            return preferences.bool(forKey: "isTemperatureOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isTemperatureOff")
            preferences.synchronize()
        }
    }
    
    var isHumidityOff: Bool {
        get {
            return preferences.bool(forKey: "isHumidityOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isHumidityOff")
            preferences.synchronize()
        }
    }
    
    var isPressureOff: Bool {
        get {
            return preferences.bool(forKey: "isPressureOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isPressureOff")
            preferences.synchronize()
        }
    }
    
    var isLightOff: Bool {
        get {
            return preferences.bool(forKey: "isLightOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isLightOff")
            preferences.synchronize()
        }
    }
    
    var isAcceleratorOff: Bool {
        get {
            return preferences.bool(forKey: "isAcceleratorOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isAcceleratorOff")
            preferences.synchronize()
        }
    }
    
    var isMagnetometerOff: Bool {
        get {
            return preferences.bool(forKey: "isMagnetometerOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isMagnetometerOff")
            preferences.synchronize()
        }
    }
    
    var isGyroOff: Bool {
        get {
            return preferences.bool(forKey: "isGyroOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isGyroOff")
            preferences.synchronize()
        }
    }
    
    var isStepsOff: Bool {
        get {
            return preferences.bool(forKey: "isStepsOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isStepsOff")
            preferences.synchronize()
        }
    }
    
    var isCaloriesOff: Bool {
        get {
            return preferences.bool(forKey: "isCaloriesOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isCaloriesOff")
            preferences.synchronize()
        }
    }
    
    var isHeartRateOff: Bool {
        get {
            return preferences.bool(forKey: "isHeartRateOff")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "isHeartRateOff")
            preferences.synchronize()
        }
    }
    
    var heartbeat: Int {
        get {
            return preferences.integer(forKey: "heartbeat")
        }
        set (newValue) {
            preferences.set(newValue, forKey: "heartbeat")
            preferences.synchronize()
        }
    }
    
    
    /* HEXI  end*/
    
    func clear() {
        lastPublished = nil
        lastSensorReadingDate = nil
        trackingIsOff = true
        preferences.synchronize()
    }
    
    
    func isHeartbeatIntervalReached() -> Bool {
        guard let lastPublished = lastPublished else { return true }
        
        let lastPublishedTimeInterval = lastPublished.timeIntervalSinceNow
        let timeSinceUpdate = (-1 * lastPublishedTimeInterval)
        var timeTrigger = Double(heartbeat)
        
        if timeTrigger < 5.0 {
            timeTrigger = 5.0
        }
        
        return timeSinceUpdate >= timeTrigger
        
    }
    
    
    // Convert string of mappings to array of mappings
    //example: serialsString = "hexi1,wolk1|hexi2,wolk2|hexi3,wolk3|hexi4,wolk4"
    // to [{hexi1,wolk1},{hexi2,wolk2}...]
    func serialsStringToHexiAndWolkCombination(_ serialsString: String) -> [SerialMapping] {
        guard serialsString.characters.count > 0 else { return [] }
        
        let serials = serialsString.components(separatedBy: "|")
        let serialsMapping = serials.map { serialsJoined -> SerialMapping in
            let twoSerialsAndPassword = serialsJoined.components(separatedBy: ",")
            return SerialMapping(hexiSerial: twoSerialsAndPassword[0], wolkSerial: twoSerialsAndPassword[1], wolkPassword: twoSerialsAndPassword[2])
        }
        
        return serialsMapping
    }
    
    // Convert array of mappings to string of mappings
    func hexiAndWolkCombinationToString(_ hexiAndWolk: [SerialMapping]) -> String {
        guard hexiAndWolk.count > 0 else { return "" }
        
        let start = ""
        let serialsArrayAsString = hexiAndWolk.reduce(start) { $0 + "\($1.hexiSerial),\($1.wolkSerial),\($1.wolkPassword)|" }
        if serialsArrayAsString.characters.count > 0 {
            let finalArray = String(serialsArrayAsString.characters.dropLast())
            return finalArray
        }
        return ""
    }
    
    // Find hexi serial in list of mappings and return wolk serial
    func findHexiAndWolkCombination(_ hexiToFind: String, hexiAndWolkSerials: [SerialMapping]) -> String? {
        guard hexiToFind.characters.count > 0 else { print("no hexi"); return nil }
        
        for mapping in hexiAndWolkSerials {
            if hexiToFind == mapping.hexiSerial { return mapping.wolkSerial }
        }
        return nil
    }
    
    // Find hexi serial in list of mappings and return wolk serial and password
    func findWolkCredentials(_ hexiToFind: String, hexiAndWolkSerials: [SerialMapping]) -> (String?, String?) {
        guard hexiToFind.characters.count > 0 else { print("no hexi"); return (nil,nil) }
        
        for mapping in hexiAndWolkSerials {
            if hexiToFind == mapping.hexiSerial { return (mapping.wolkSerial, mapping.wolkPassword) }
        }
        return (nil, nil)
    }
    
}

// Mapping structure
struct SerialMapping {
    let hexiSerial:   String
    let wolkSerial:   String
    let wolkPassword: String
}
