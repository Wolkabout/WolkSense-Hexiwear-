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
//  ChangePasswordTableViewController.swift
//

import UIKit

class ChangePasswordTableViewController: UITableViewController {

    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var newPassword: UITextField!
    @IBOutlet weak var confirmNewPassword: UITextField!
    @IBOutlet weak var buttons: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dataStore: DataStore!
    var userEmail: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        oldPassword.delegate = self
        newPassword.delegate = self
        confirmNewPassword.delegate = self
        title = "Change password"
    }
    
    override func viewDidAppear(animated: Bool) {
        if isMovingToParentViewController() {
            oldPassword.becomeFirstResponder()
        }
    }

    @IBAction func closeAction(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func hideButtons() {
        buttons.hidden = true
        activityIndicator.startAnimating()
    }
    
    private func showButtons() {
        buttons.hidden = false
        activityIndicator.stopAnimating()
    }

    func checkAllFieldsSet() -> Bool {
        guard let oldPass = oldPassword.text, newPass = newPassword.text, conf = confirmNewPassword.text else {
            return false
        }
        return !oldPass.isEmpty && !newPass.isEmpty && !conf.isEmpty

    }
    
    @IBAction func changeAction(sender: AnyObject) {
        hideButtons()
        
        if !checkAllFieldsSet() {
            showSimpleAlertWithTitle(applicationTitle, message: "All fields are mandatory!", viewController: self)
            showButtons()
            return
        }
        
        
        let passwordsMatch = newPassword.text == confirmNewPassword.text
        if !passwordsMatch {
            showSimpleAlertWithTitle(applicationTitle, message: "Passwords do not match!", viewController: self)
            showButtons()
            return
        }
        
        dataStore.changePasswordForUserEmail(userEmail, oldPassword: oldPassword.text ?? "", newPassword: newPassword.text ?? "",
            onFailure:{ _ in
                dispatch_async(dispatch_get_main_queue()) {
                    showSimpleAlertWithTitle(applicationTitle, message: "Error changing password!", viewController: self)
                    self.showButtons()
                }
            },
            onSuccess: {
                dispatch_async(dispatch_get_main_queue()) {
                    showSimpleAlertWithTitle(applicationTitle, message: "Password has been changed!", viewController: self, OKhandler: { _ in
                        self.dismissViewControllerAnimated(true, completion: nil) })
                }
            }
        )
        
    }
    
}

extension ChangePasswordTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == oldPassword {
            newPassword.becomeFirstResponder()
            return true
        }
        
        if textField == newPassword {
            confirmNewPassword.becomeFirstResponder()
            return true
        }
        
        textField.resignFirstResponder()
        return true
    }
}