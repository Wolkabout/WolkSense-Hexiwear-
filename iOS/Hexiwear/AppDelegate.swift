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
//  AppDelegate.swift
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var userCredentials: UserCredentials!
    var webApi: WebAPI!
    var dataStore: DataStore!
    var device: TrackingDevice!
    var mqttAPI: MQTTAPI!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        userCredentials = UserCredentials()
        let userAccount = userCredentials.email ?? ""
        device = TrackingDevice()
        device.userAccount = userAccount
        webApi = WebAPI.sharedWebAPI
        dataStore = DataStore(webApi: webApi, userCredentials: userCredentials, trackingDevice: device)
        mqttAPI = MQTTAPI()
        
        return true
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        if url.isFileURL {
            guard let privateDocsDir = getPrivateDocumentsDirectory()  else { return false }
            guard let _ = try? FileManager.default.contentsOfDirectory(atPath: privateDocsDir) else { return false }
            let fullFileName = (privateDocsDir as NSString).appendingPathComponent(url.lastPathComponent)
            
            // write
            guard let urlData = try? Data(contentsOf: url) else { print("NOT valid URL data"); return false}
            let filePath = fullFileName
            
            if !FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil) {  print("Failure creating file"); return false }
            
            let fileWrapper = FileWrapper(regularFileWithContents: urlData)
            
            let fileURL = URL(fileURLWithPath: filePath)
            
            guard let _ = try? fileWrapper.write(to: fileURL, options: .atomic, originalContentsURL: nil) else { print("Error writting to file"); return false }
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

