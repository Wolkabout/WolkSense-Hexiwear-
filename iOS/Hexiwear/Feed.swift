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
//  Feed.swift
//

import UIKit
import MapKit

public enum ReadingType: String {
    case TEMPERATURE = "T"
    case PRESSURE = "P"
    case HUMIDITY = "H"
    case GPS = "G"
    case BATTERY = "B"
    case MOTION = "M"
    case CONNECTION = "C"
    case ALARM = "A"
    case LIGHT = "LT"
    case ACCELEROMETER = "ACL"
    case MAGNETOMETER = "MAG"
    case GYROSCOPE = "GYR"
    case STEPS = "STP"
    case HEARTRATE = "BPM"
}

extension ReadingType: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}

struct Feed  {
    let device: Device
    let id: Int
    let readingType: ReadingType
    let currentValue: String
    let trend: String
    var enabled: Bool
    let order: Int
    let alarmState: String
    var alarmHigh: String
    var alarmHighEnabled: Bool
    var alarmLow: String
    var alarmLowEnabled: Bool
    
    init? (device: Device, id: Int, readingType: String, currentValue: String, trend: String, enabled: Bool, order: Int, alarmState: String, alarmHigh: String, alarmHighEnabled: Bool, alarmLow: String, alarmLowEnabled: Bool) {
        
        guard let feedType = ReadingType(rawValue: readingType) else { return nil }
        
        self.device = device
        self.id = id
        self.readingType = feedType
        self.currentValue = currentValue
        self.trend = trend
        self.enabled = enabled
        self.order = order
        self.alarmState = alarmState
        self.alarmHigh = alarmHigh
        self.alarmHighEnabled = alarmHighEnabled
        self.alarmLow = alarmLow
        self.alarmLowEnabled = alarmLowEnabled
    }
    
    static func parseFeedJSON(_ feedJson: [String:AnyObject], device: Device) -> Feed? {
        if let id = feedJson["id"] as? Int,
            let readingType = feedJson["readingType"] as? String,
            let currentValue = feedJson["currentValue"] as? String,
            let trend = feedJson["trend"] as? String,
            let enabled = feedJson["enabled"] as? Bool,
            let order = feedJson["order"] as? Int,
            let alarmState = feedJson["alarmState"] as? String,
            let alarmHigh = feedJson["alarmHigh"] as? String,
            let alarmHighEnabled = feedJson["alarmHighEnabled"] as? Bool,
            let alarmLow = feedJson["alarmLow"] as? String,
            let alarmLowEnabled = feedJson["alarmLowEnabled"] as? Bool {
            return Feed(device: device, id: id, readingType: readingType, currentValue: currentValue, trend: trend, enabled: enabled, order: order, alarmState: alarmState, alarmHigh: alarmHigh, alarmHighEnabled: alarmHighEnabled, alarmLow: alarmLow, alarmLowEnabled: alarmLowEnabled)
        }
        
        return nil
    }
}

extension Feed: CustomStringConvertible {
    internal var description: String {
        return "FEED {\n\t id:\(id),\n\t enabled:\(enabled),\n\t name:\(device.name),\n\t \n\t currentValue:\(currentValue)\n}\n"
    }
}


func ==(lhs: Feed, rhs: Feed) -> Bool {
    return lhs.id == rhs.id
}

extension Feed: Hashable {
    var hashValue: Int { return id }
}
