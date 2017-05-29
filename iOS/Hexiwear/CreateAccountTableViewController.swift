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
        signUpButton.isEnabled = false
    }
    
    func didActivateSuccessfully() {
        showSimpleAlertWithTitle(applicationTitle, message: "Activation successfull.", viewController: self)
    }
    
    func didFailActivation() {
        showSimpleAlertWithTitle(applicationTitle, message: "Activation failed.", viewController: self)
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func hideButtons() {
        buttons.isHidden = true
        activityIndicator.startAnimating()
    }
    
    fileprivate func showButtons() {
        buttons.isHidden = false
        activityIndicator.stopAnimating()
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        signUpButton.isEnabled = policySwitch.isOn
    }
    
    func checkAllFieldsSet() -> Bool {
        guard let fn = firstName.text, let ln = lastName.text, let em = email.text, let pass = password.text, let conf = confirmPassword.text else {
            return false
        }
        return !fn.isEmpty && !ln.isEmpty && !em.isEmpty && !pass.isEmpty && !conf.isEmpty
    }
    
    @IBAction func createAccount(_ sender: UIButton) {
        hideButtons()
        
        if !checkAllFieldsSet() {
            showSimpleAlertWithTitle(applicationTitle, message: "All fields are mandatory!", viewController: self)
            showButtons()
            return
        }
        
        if let em = email.text, !isValidEmailAddress(em) {
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
        
        guard let pass = password.text, let conf = confirmPassword.text, (pass.characters.count >= 8) && (conf.characters.count >= 8)  else {
            showSimpleAlertWithTitle(applicationTitle, message: "Password must be at least 8 characters long!", viewController: self)
            showButtons()
            return
        }
        
        if !policySwitch.isOn {
            showSimpleAlertWithTitle(applicationTitle, message: "Please agree with privacy policy and terms and conditions", viewController: self)
            showButtons()
            return
        }
        
        
        let account = Account(firstName: firstName.text ?? "", lastName: lastName.text ?? "", email: email.text ?? "", password: password.text ?? "")
        dataStore.signUpWithAccount(account,
                                    onFailure: handleSignupFail(reason:),
                                    onSuccess: {
                                        DispatchQueue.main.async {
                                            showSimpleAlertWithTitle(applicationTitle, message: "Thank you for signing up! A verification email has been sent to your email address. Please check your Inbox and follow the instructions.", viewController: self, OKhandler: { _ in
                                                self.dismiss(animated: true, completion: nil) })
                                            self.userCredentials.email = self.email.text
                                            
                                        }
        }
        )
    }
    
    func handleSignupFail(reason: Reason) {
        switch reason {
        case .noSuccessStatusCode(let statusCode, let data):
            guard !(statusCode == BAD_REQUEST && data?.contains("USER_EMAIL_IS_NOT_UNIQUE") ?? false) else {
                DispatchQueue.main.async {
                    showSimpleAlertWithTitle(applicationTitle, message: "Account with provided email address already exists.", viewController: self)
                    self.showButtons()
                }
                return
            }
            
            fallthrough
        default:
            DispatchQueue.main.async {
                showSimpleAlertWithTitle(applicationTitle, message: "There was a problem creating your account. Please try again or contact our support.", viewController: self)
                self.showButtons()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTerms" {
            if let vc = segue.destination as? BaseNavigationController,
                let termsVC = vc.topViewController as? StaticViewController {
                termsVC.staticDelegate = self
                termsVC.url = URL(string: termsAndConditionsURL)
            }
        }
        else if segue.identifier == "toPolicy" {
            if let vc = segue.destination as? BaseNavigationController,
                let termsVC = vc.topViewController as? StaticViewController {
                termsVC.staticDelegate = self
                termsVC.url = URL(string: privacyPolicyURL)
            }
        }
    }
}

extension CreateAccountTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        dismiss(animated: true, completion: nil)
    }
}
