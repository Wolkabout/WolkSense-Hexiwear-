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
//  UserCredentials.swift
//

import Foundation

class UserCredentials {
    
    let preferences = UserDefaults.standard
    
    var accessTokenExpires: Date? {
        get {
            let token = preferences.object(forKey: "accessTokenExpires") as? Date
            return token
        }
        set (newToken) {
            preferences.set(newToken, forKey: "accessTokenExpires")
            preferences.synchronize()
        }
    }
    
    var accessToken: String? {
        get {
            let token = preferences.object(forKey: "accessToken") as? String
            return token
        }
        set (newToken) {
            preferences.set(newToken, forKey: "accessToken")
            preferences.synchronize()
        }
    }
    
    var refreshToken: String? {
        get {
            let token = preferences.object(forKey: "refreshToken") as? String
            return token
        }
        set (newToken) {
            preferences.set(newToken, forKey: "refreshToken")
            preferences.synchronize()
        }
    }
    
    var email: String? {
        get {
            let email = preferences.object(forKey: "email") as? String
            return email
        }
        set (newToken) {
            preferences.set(newToken, forKey: "email")
            preferences.synchronize()
        }
    }
    
    func isDemoUser() -> Bool {
        if let userEmail = self.email, userEmail == demoAccount {
            return true
        }
        return false
    }
    
    func clearCredentials() {
        accessTokenExpires = nil
        accessToken = nil
        refreshToken = nil
        email = nil
        preferences.synchronize()
    }
    
    internal func storeCredentials(_ credentials: NSDictionary) {
        if let accessToken = credentials["accessToken"] as? String,
            let accessTokenExpires = credentials["accessTokenExpires"] as? String,
            let refreshToken = credentials["refreshToken"] as? String,
            let email = credentials["email"] as? String {
            print("store credentials accessToken: \(accessToken), email: \(email)")
            self.accessToken = accessToken
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            self.accessTokenExpires = dateFormat.date(from: accessTokenExpires)
            self.refreshToken = refreshToken
            self.email = email
        }
    }
}
