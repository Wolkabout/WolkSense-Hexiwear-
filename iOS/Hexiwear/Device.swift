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
//  Device.swift
//

import Foundation
import UIKit

public struct Device {
    let id: Int
    var name: String = ""
    let deviceSerial: String
    let activationTimestamp: Double
    let deviceState: String
    let batteryState: Int
    var heartbeat: Int = 0
    let lastReportTimestamp: Double
    let owner: String
    var feeds: [Feed]?
    
    init (id: Int, name: String, deviceSerial: String, activationTimestamp: Double, deviceState: String, batteryState: Int, heartbeat: Int, lastReportTimestamp: Double, owner: String, feeds: [Feed]?) {
        self.id = id
        self.name = name
        self.deviceSerial = deviceSerial
        self.activationTimestamp = activationTimestamp
        self.deviceState = deviceState
        self.batteryState = batteryState
        self.heartbeat = heartbeat
        self.lastReportTimestamp = lastReportTimestamp
        self.owner = owner
        self.feeds = feeds
    }
    
    static func parseDeviceJSON(_ deviceJson: [String:AnyObject]) -> Device? {
        var device: Device?
        if let id = deviceJson["id"] as? Int,
            let name = deviceJson["name"] as? String,
            let deviceSerial = deviceJson["deviceSerial"] as? String,
            let activationTimestamp = deviceJson["activationTimestamp"] as? Double,
            let deviceState = deviceJson["deviceState"] as? String,
            let batteryState = deviceJson["batteryState"] as? Int,
            let heartbeat = deviceJson["heartbeat"] as? Int,
            let lastReportTimestamp = deviceJson["lastReportTimestamp"] as? Double,
            let owner = deviceJson["owner"] as? String {
            
            device = Device(id: id, name: name, deviceSerial: deviceSerial, activationTimestamp: activationTimestamp / 1000.0, deviceState: deviceState, batteryState: batteryState, heartbeat: heartbeat, lastReportTimestamp: lastReportTimestamp / 1000.0, owner: owner, feeds: nil)
            
            // feeds
            if let feeds = deviceJson["feeds"] as? [[String:AnyObject]] {
                var feedArray: [Feed] = []
                feedArray = feeds.reduce([]) { (accum, elem) in
                    var accum = accum
                    if let feed = Feed.parseFeedJSON(elem, device: device!) {
                        accum.append(feed)
                    }
                    return accum
                }
                device!.feeds = feedArray
            }
        }
        
        return device
    }
    
    func isHexiwear() -> Bool {
        guard deviceSerial.characters.count == 16 else { return false }
        
        let range = deviceSerial.characters.index(deviceSerial.startIndex, offsetBy: 4) ..< deviceSerial.characters.index(deviceSerial.startIndex, offsetBy: 6)
        let substring = deviceSerial[range]
        
        return substring == "HX"
    }
    
}

extension Device: CustomStringConvertible {
    public var description: String {
        return "DEVICE {\n\t id:\(id),\n\t name:\(name),\n\t activationTimestamp:\(activationTimestamp),\n\t deviceState:\(deviceState),\n\t batteryState:\(batteryState),\n\t heartbeat:\(heartbeat),\n\t lastReportTimestamp:\(lastReportTimestamp),\n\t owner:\(owner),\n\t feeds:\(feeds?.count ?? 0)\n}"
    }
}

extension Device {
    func enabledFeeds() -> [Feed]? {
        return self.feeds
    }
}

