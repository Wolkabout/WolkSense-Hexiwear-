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
//  Util.swift
//

import UIKit
import MapKit

// HEXIWEAR CONSTANTS

let signUpURL = "https://wolksense.com"
let privacyPolicyURL = "https://wolksense.com/documents/privacypolicy.html"
let termsAndConditionsURL = "https://wolksense.com/documents/termsofservice.html"
let NOT_AUTHORIZED = 401
let FORBIDDEN = 403
let NOT_FOUND = 404
let CONFLICT = 409

let applicationTitle = "Hexiwear"
let demoAccount = "demo"
let wolkaboutBlueColor = UIColor(red: 0.0, green: 128.0/255.0, blue: 1.0, alpha: 1.0)

// NOTIFICATIONS
let HexiwearDidSignOut = "HexiwearDidSignOut"

// TopMostViewController extensions
extension UIViewController {
    func topMostViewController() -> UIViewController {
        // Handling Modal views
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }
        
        // Handling UIViewController's added as subviews to some other views.
        for view in self.view.subviews
        {
            // Key property which most of us are unaware of / rarely use.
            if let subViewController = view.nextResponder() {
                if subViewController is UIViewController {
                    let viewController = subViewController as! UIViewController
                    return viewController.topMostViewController()
                }
            }
        }
        return self
    }
}

extension UITabBarController {
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }
}

extension UINavigationController {
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController!.topMostViewController()
    }
}



// Global misc functions

func isValidEmailAddress(email: String) -> Bool {
    let regExPattern = "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}"
    do {
        let regEx = try NSRegularExpression(pattern: regExPattern, options: .CaseInsensitive)
        let regExMatches = regEx.numberOfMatchesInString(email, options: [], range: NSMakeRange(0, email.characters.count))
        return regExMatches == 0 ? false : true
    }
    catch {
        return false
    }
}

func getPrivateDocumentsDirectory() -> String? {
    
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    if paths.count == 0 { print("No private directory"); return nil }
    var documentsDirectory = paths[0]
    documentsDirectory = (documentsDirectory as NSString).stringByAppendingPathComponent("Private Documents")
    if let _ = try? NSFileManager.defaultManager().createDirectoryAtPath(documentsDirectory, withIntermediateDirectories: true, attributes: nil) {
        return documentsDirectory
    }
    return nil
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func showSimpleAlertWithTitle(title: String!, message: String, viewController: UIViewController, OKhandler: ((UIAlertAction!) -> Void)? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Cancel, handler: OKhandler)
        alert.addAction(action)
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
}

func showOKAndCancelAlertWithTitle(title: String!, message: String, viewController: UIViewController, OKhandler: ((UIAlertAction!) -> Void)? = nil) {
    dispatch_async(dispatch_get_main_queue()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let OKaction = UIAlertAction(title: "OK", style: .Default, handler: OKhandler)
        alert.addAction(OKaction)
        let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(CancelAction)
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
}