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
let BAD_REQUEST = 400
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
            if let subViewController = view.next {
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

func isValidEmailAddress(_ email: String) -> Bool {
    let regExPattern = "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}"
    do {
        let regEx = try NSRegularExpression(pattern: regExPattern, options: .caseInsensitive)
        let regExMatches = regEx.numberOfMatches(in: email, options: [], range: NSMakeRange(0, email.characters.count))
        return regExMatches == 0 ? false : true
    }
    catch {
        return false
    }
}

func getPrivateDocumentsDirectory() -> String? {
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    if paths.count == 0 { print("No private directory"); return nil }
    var documentsDirectory = paths[0]
    documentsDirectory = (documentsDirectory as NSString).appendingPathComponent("Private Documents")
    if let _ = try? FileManager.default.createDirectory(atPath: documentsDirectory, withIntermediateDirectories: true, attributes: nil) {
        return documentsDirectory
    }
    return nil
}

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func showSimpleAlertWithTitle(_ title: String!, message: String, viewController: UIViewController, OKhandler: ((UIAlertAction?) -> Void)? = nil) {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: OKhandler)
        alert.addAction(action)
        viewController.present(alert, animated: true, completion: nil)
    }
}

func showOKAndCancelAlertWithTitle(_ title: String!, message: String, viewController: UIViewController, OKhandler: ((UIAlertAction?) -> Void)? = nil) {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKaction = UIAlertAction(title: "OK", style: .default, handler: OKhandler)
        alert.addAction(OKaction)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(CancelAction)
        viewController.present(alert, animated: true, completion: nil)
    }
}
