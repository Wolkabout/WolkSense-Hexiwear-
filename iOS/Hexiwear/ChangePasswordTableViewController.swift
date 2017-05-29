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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        oldPassword.delegate = self
        newPassword.delegate = self
        confirmNewPassword.delegate = self
        title = "Change password"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isMovingToParentViewController {
            oldPassword.becomeFirstResponder()
        }
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func hideButtons() {
        buttons.isHidden = true
        activityIndicator.startAnimating()
    }
    
    fileprivate func showButtons() {
        buttons.isHidden = false
        activityIndicator.stopAnimating()
    }
    
    func checkAllFieldsSet() -> Bool {
        guard let oldPass = oldPassword.text, let newPass = newPassword.text, let conf = confirmNewPassword.text else {
            return false
        }
        return !oldPass.isEmpty && !newPass.isEmpty && !conf.isEmpty
        
    }
    
    @IBAction func changeAction(_ sender: AnyObject) {
        hideButtons()
        
        if !checkAllFieldsSet() {
            showSimpleAlertWithTitle(applicationTitle, message: "All fields are mandatory!", viewController: self)
            showButtons()
            return
        }
        
        guard let pass = newPassword.text, let conf = confirmNewPassword.text, (pass.characters.count >= 8) && (conf.characters.count >= 8)  else {
            showSimpleAlertWithTitle(applicationTitle, message: "Password must be at least 8 characters long!", viewController: self)
            showButtons()
            return
        }
        
        let passwordsMatch = newPassword.text == confirmNewPassword.text
        if !passwordsMatch {
            showSimpleAlertWithTitle(applicationTitle, message: "Passwords do not match!", viewController: self)
            showButtons()
            return
        }
        
        dataStore.changePasswordForUserEmail(oldPassword: oldPassword.text ?? "", newPassword: newPassword.text ?? "",
                                             onFailure: handleChangePasswordFail(reason:),
                                             onSuccess: {
                                                DispatchQueue.main.async {
                                                    showSimpleAlertWithTitle(applicationTitle, message: "Password has been changed!", viewController: self, OKhandler: { _ in
                                                        self.dismiss(animated: true, completion: nil) })
                                                }
        }
        )
    }
    
    func handleChangePasswordFail(reason: Reason) {
        switch reason {
        case .noSuccessStatusCode(let statusCode, _):
            guard statusCode != BAD_REQUEST && statusCode != NOT_AUTHORIZED else {
                DispatchQueue.main.async {
                    showSimpleAlertWithTitle(applicationTitle, message: "Please enter a valid old password and try again.", viewController: self)
                    self.showButtons()
                }
                return
            }
            
            fallthrough
        default:
            DispatchQueue.main.async {
                showSimpleAlertWithTitle(applicationTitle, message: "There was a problem changing your password. Please try again or contact our support.", viewController: self)
                self.showButtons()
            }
        }
    }
    
}

extension ChangePasswordTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
