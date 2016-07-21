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
//  CreateAccountTableViewController.swift
//

import UIKit

class CreateAccountTableViewController: UITableViewController {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var buttons: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var policySwitch: UISwitch!
    @IBOutlet weak var signUpButton: UIButton!
    
    
    var dataStore: DataStore!
    var userCredentials: UserCredentials!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
        confirmPassword.delegate = self
        signUpButton.enabled = false
    }
    
    func didActivateSuccessfully() {
        showSimpleAlertWithTitle(applicationTitle, message: "Activation successfull.", viewController: self)
    }
    
    func didFailActivation() {
        showSimpleAlertWithTitle(applicationTitle, message: "Activation failed.", viewController: self)
    }
    
    @IBAction func cancel(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    private func hideButtons() {
        buttons.hidden = true
        activityIndicator.startAnimating()
    }
    
    private func showButtons() {
        buttons.hidden = false
        activityIndicator.stopAnimating()
    }
    
    @IBAction func switchChanged(sender: UISwitch) {
        signUpButton.enabled = policySwitch.on
    }
    
    func checkAllFieldsSet() -> Bool {
        guard let fn = firstName.text, ln = lastName.text, em = email.text, pass = password.text, conf = confirmPassword.text else {
            return false
        }
        return !fn.isEmpty && !ln.isEmpty && !em.isEmpty && !pass.isEmpty && !conf.isEmpty
    }
    
    @IBAction func createAccount(sender: UIButton) {
        hideButtons()
        
        if !checkAllFieldsSet() {
            showSimpleAlertWithTitle(applicationTitle, message: "All fields are mandatory!", viewController: self)
            showButtons()
            return
        }

        if let em = email.text where !isValidEmailAddress(em) {
            showSimpleAlertWithTitle(applicationTitle, message: "Invalid email!", viewController: self)
            showButtons()
            return
        }
        
        let passwordsMatch = password.text == confirmPassword.text
        if !passwordsMatch {
            showSimpleAlertWithTitle(applicationTitle, message: "Passwords do not match!", viewController: self)
            showButtons()
            return
        }
        
        guard let pass = password.text, conf = confirmPassword.text where (pass.characters.count >= 8) && (conf.characters.count >= 8)  else {
            showSimpleAlertWithTitle(applicationTitle, message: "Password should be at least 8 characters long!", viewController: self)
            showButtons()
            return
        }

        if !policySwitch.on {
            showSimpleAlertWithTitle(applicationTitle, message: "Please agree with privacy policy and terms and conditions", viewController: self)
            showButtons()
            return
        }
        
        
        let account = Account(firstName: firstName.text ?? "", lastName: lastName.text ?? "", email: email.text ?? "", password: password.text ?? "")
        dataStore.signUpWithAccount(account,
            onFailure: { _ in
                dispatch_async(dispatch_get_main_queue()) {
                    showSimpleAlertWithTitle(applicationTitle, message: "Error creating account!", viewController: self)
                    self.showButtons()
                }

            },
            onSuccess: {
                dispatch_async(dispatch_get_main_queue()) {
                    showSimpleAlertWithTitle(applicationTitle, message: "Thank you for signing up! A verification email has been sent to your email address. Please check your Inbox and follow the instructions.", viewController: self, OKhandler: { _ in
                        self.dismissViewControllerAnimated(true, completion: nil) })
                    self.userCredentials.email = self.email.text
                    
                }
            }
        )        
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toTerms" {
            if let vc = segue.destinationViewController as? BaseNavigationController,
                termsVC = vc.topViewController as? StaticViewController {
                    termsVC.staticDelegate = self
                    termsVC.url = NSURL(string: termsAndConditionsURL)
            }
        }
        else if segue.identifier == "toPolicy" {
            if let vc = segue.destinationViewController as? BaseNavigationController,
                termsVC = vc.topViewController as? StaticViewController {
                    termsVC.staticDelegate = self
                    termsVC.url = NSURL(string: privacyPolicyURL)
            }
        }
    }
}

extension CreateAccountTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == firstName {
            lastName.becomeFirstResponder()
            return true
        }
        
        if textField == lastName {
            email.becomeFirstResponder()
            return true
        }
        
        if textField == email {
            password.becomeFirstResponder()
            return true
        }
        
        if textField == password {
            confirmPassword.becomeFirstResponder()
            return true
        }
        
        textField.resignFirstResponder()
        return true
    }

}

extension CreateAccountTableViewController: StaticViewDelegate {
    func willClose() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

