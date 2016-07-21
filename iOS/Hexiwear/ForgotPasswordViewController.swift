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
//  ForgotPasswordViewController.swift
//

import UIKit

protocol ForgotPasswordDelegate {
    func didFinishResettingPassword()
}

class ForgotPasswordViewController: SingleTextViewController {

    var forgotPasswordDelegate: ForgotPasswordDelegate?
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skipButton.title = "Done"
        actionButton.title = "Reset"
        emailText.delegate = self
        emailText.text = ""
        title = "Reset password"
        errorLabel.hidden = true
    }
    
    override func toggleActivateButtonEnabled() {
        if let em = emailText.text where isValidEmailAddress(em) {
            actionButton.enabled = true
        }
        else {
            actionButton.enabled = false
        }
    }
    
    override func actionButtonAction() {
        dataStore.resetPasswordForUserEmail(emailText.text!,
            onFailure: { _ in
                dispatch_async(dispatch_get_main_queue()) {
                    self.errorLabel.hidden = false
                    self.view.setNeedsDisplay()
                }
            },
            onSuccess: {
                showSimpleAlertWithTitle(applicationTitle, message: "Check your email for new password.", viewController: self, OKhandler: { _ in self.forgotPasswordDelegate?.didFinishResettingPassword()
                })
            }
        )
    }
    
    override func skipButtonAction() {
        forgotPasswordDelegate?.didFinishResettingPassword()
    }
    
    @IBAction func emailChanged(sender: UITextField) {
        toggleActivateButtonEnabled()
        errorLabel.hidden = true
        self.view.setNeedsDisplay()
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
