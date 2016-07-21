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

    let preferences = NSUserDefaults.standardUserDefaults()
    
    
    // Account specific properties
    var userAccount: String = "" {
        didSet {
            print("Tracking device account: \(userAccount)")
        }
    }
    
    //example: "hexi1,wolk1|hexi2,wolk2|hexi3,wolk3|hexi4,wolk4"
    var hexiAndWolkSerials: String {
        get {
            if let hi  = preferences.objectForKey("\(userAccount)-hexiAndWolkSerials") as? String {
                return hi
            }
            return ""
        }
        set (newHI) {
            preferences.setObject(newHI, forKey: "\(userAccount)-hexiAndWolkSerials")
            preferences.synchronize()
        }
    }
    
    // Account agnostic properties
    
    var trackingIsOff: Bool {
        get {
            return preferences.boolForKey("trackingIsOff")
        }
        set (newTracking) {
            preferences.setBool(newTracking, forKey: "trackingIsOff")
            preferences.synchronize()
        }
    }

    var lastPublished: NSDate? {
        get {
            if let lp = preferences.objectForKey("deviceLastPublished") as? NSDate {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.setObject(newLP, forKey: "deviceLastPublished")
            preferences.synchronize()
        }
    }

/* HEXI  start*/
    var lastSensorReadingDate: NSDate? {
        get {
            if let lp = preferences.objectForKey("lastSensorReadingDate") as? NSDate {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.setObject(newLP, forKey: "lastSensorReadingDate")
            preferences.synchronize()
        }
    }

    var lastTemperature: Double? {
        get {
            if let lp = preferences.objectForKey("lastTemperature") as? Double {
                return lp
            }
            return nil
        }
        set (newLT) {
            preferences.setObject(newLT, forKey: "lastTemperature")
            preferences.synchronize()
        }
    }

    var lastAirPressure: Double? {
        get {
            if let lp = preferences.objectForKey("lastAirPressure") as? Double {
                return lp
            }
            return nil
        }
        set (newLP) {
            preferences.setObject(newLP, forKey: "lastAirPressure")
            preferences.synchronize()
        }
    }
    
    var lastAirHumidity: Double? {
        get {
            if let lp = preferences.objectForKey("lastAirHumidity") as? Double {
                return lp
            }
            return nil
        }
        set (newLAH) {
            preferences.setObject(newLAH, forKey: "lastAirHumidity")
            preferences.synchronize()
        }
    }

    var lastLight: Double? {
        get {
            if let lp = preferences.objectForKey("lastLight") as? Double {
                return lp
            }
            return nil
        }
        set (newLAH) {
            preferences.setObject(newLAH, forKey: "lastLight")
             preferences.synchronize()
        }
    }
    
    var lastAccelerationX: Double? {
        get {
            if let lp = preferences.objectForKey("lastAccelerationX") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.setObject(newLAC, forKey: "lastAccelerationX")
            preferences.synchronize()
        }
    }

    var lastAccelerationY: Double? {
        get {
            if let lp = preferences.objectForKey("lastAccelerationY") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.setObject(newLAC, forKey: "lastAccelerationY")
            preferences.synchronize()
        }
    }
    
    var lastAccelerationZ: Double? {
        get {
            if let lp = preferences.objectForKey("lastAccelerationZ") as? Double {
                return lp
            }
            return nil
        }
        set (newLAC) {
            preferences.setObject(newLAC, forKey: "lastAccelerationZ")
            preferences.synchronize()
        }
    }

    var lastGyroX: Double? {
        get {
            if let lp = preferences.objectForKey("lastGyroX") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.setObject(newLAG, forKey: "lastGyroX")
            preferences.synchronize()
        }
    }
    
    var lastGyroY: Double? {
        get {
            if let lp = preferences.objectForKey("lastGyroY") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.setObject(newLAG, forKey: "lastGyroY")
            preferences.synchronize()
        }
    }
    
    var lastGyroZ: Double? {
        get {
            if let lp = preferences.objectForKey("lastGyroZ") as? Double {
                return lp
            }
            return nil
        }
        set (newLAG) {
            preferences.setObject(newLAG, forKey: "lastGyroZ")
            preferences.synchronize()
        }
    }

    var lastMagnetX: Double? {
        get {
            if let lp = preferences.objectForKey("lastMagnetX") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.setObject(newMAG, forKey: "lastMagnetX")
            preferences.synchronize()
        }
    }
    
    var lastMagnetY: Double? {
        get {
            if let lp = preferences.objectForKey("lastMagnetY") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.setObject(newMAG, forKey: "lastMagnetY")
            preferences.synchronize()
        }
    }
    
    var lastMagnetZ: Double? {
        get {
            if let lp = preferences.objectForKey("lastMagnetZ") as? Double {
                return lp
            }
            return nil
        }
        set (newMAG) {
            preferences.setObject(newMAG, forKey: "lastMagnetZ")
            preferences.synchronize()
        }
    }
    
    var lastSteps: Int? {
        get {
            if let lp = preferences.objectForKey("lastSteps") as? Int {
                return lp
            }
            return nil
        }
        set (newSteps) {
            preferences.setObject(newSteps, forKey: "lastSteps")
            preferences.synchronize()
        }
    }

    var lastCalories: Int? {
        get {
            if let lp = preferences.objectForKey("lastCalories") as? Int {
                return lp
            }
            return nil
        }
        set (newCalories) {
            preferences.setObject(newCalories, forKey: "lastCalories")
            preferences.synchronize()
        }
    }

    var lastHeartRate: Int? {
        get {
            if let lp = preferences.objectForKey("lastHeartRate") as? Int {
                return lp
            }
            return nil
        }
        set (newHR) {
            preferences.setObject(newHR, forKey: "lastHeartRate")
            preferences.synchronize()
        }
    }

    var lastHexiwearMode: Int? {
        get {
            if let lp = preferences.objectForKey("lastHexiwearMode") as? Int {
                return lp
            }
            return nil
        }
        set (newHR) {
            preferences.setObject(newHR, forKey: "lastHexiwearMode")
            preferences.synchronize()
        }
    }
    

    var isBatteryOff: Bool {
        get {
            return preferences.boolForKey("isBatteryOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isBatteryOff")
            preferences.synchronize()
        }
    }

    var isTemperatureOff: Bool {
        get {
            return preferences.boolForKey("isTemperatureOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isTemperatureOff")
            preferences.synchronize()
        }
    }

    var isHumidityOff: Bool {
        get {
            return preferences.boolForKey("isHumidityOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isHumidityOff")
            preferences.synchronize()
        }
    }
    
    var isPressureOff: Bool {
        get {
            return preferences.boolForKey("isPressureOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isPressureOff")
            preferences.synchronize()
        }
    }
    
    var isLightOff: Bool {
        get {
            return preferences.boolForKey("isLightOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isLightOff")
            preferences.synchronize()
        }
    }
    
    var isAcceleratorOff: Bool {
        get {
            return preferences.boolForKey("isAcceleratorOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isAcceleratorOff")
            preferences.synchronize()
        }
    }
    
    var isMagnetometerOff: Bool {
        get {
            return preferences.boolForKey("isMagnetometerOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isMagnetometerOff")
            preferences.synchronize()
        }
    }
    
    var isGyroOff: Bool {
        get {
            return preferences.boolForKey("isGyroOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isGyroOff")
            preferences.synchronize()
        }
    }
    
    var isStepsOff: Bool {
        get {
            return preferences.boolForKey("isStepsOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isStepsOff")
            preferences.synchronize()
        }
    }

    var isCaloriesOff: Bool {
        get {
            return preferences.boolForKey("isCaloriesOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isCaloriesOff")
            preferences.synchronize()
        }
    }

    var isHeartRateOff: Bool {
        get {
            return preferences.boolForKey("isHeartRateOff")
        }
        set (newValue) {
            preferences.setBool(newValue, forKey: "isHeartRateOff")
            preferences.synchronize()
        }
    }
    
    var heartbeat: Int {
        get {
            return preferences.integerForKey("heartbeat")
        }
        set (newValue) {
            preferences.setInteger(newValue, forKey: "heartbeat")
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
    func serialsStringToHexiAndWolkCombination(serialsString: String) -> [SerialMapping] {
        guard serialsString.characters.count > 0 else { return [] }
        
        let serials = serialsString.componentsSeparatedByString("|")
        let serialsMapping = serials.map { serialsJoined -> SerialMapping in
            let twoSerialsAndPassword = serialsJoined.componentsSeparatedByString(",")
            return SerialMapping(hexiSerial: twoSerialsAndPassword[0], wolkSerial: twoSerialsAndPassword[1], wolkPassword: twoSerialsAndPassword[2])
        }
        
        return serialsMapping
    }

    // Convert array of mappings to string of mappings
    func hexiAndWolkCombinationToString(hexiAndWolk: [SerialMapping]) -> String {
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
    func findHexiAndWolkCombination(hexiToFind: String, hexiAndWolkSerials: [SerialMapping]) -> String? {
        guard hexiToFind.characters.count > 0 else { print("no hexi"); return nil }
        
        for mapping in hexiAndWolkSerials {
            if hexiToFind == mapping.hexiSerial { return mapping.wolkSerial }
        }
        return nil
    }

    // Find hexi serial in list of mappings and return wolk serial and password
    func findWolkCredentials(hexiToFind: String, hexiAndWolkSerials: [SerialMapping]) -> (String?, String?) {
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
