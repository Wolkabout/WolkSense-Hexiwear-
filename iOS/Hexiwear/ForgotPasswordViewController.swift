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
        errorLabel.isHidden = true
    }
    
    override func toggleActivateButtonEnabled() {
        if let em = emailText.text, isValidEmailAddress(em) {
            actionButton.isEnabled = true
        }
        else {
            actionButton.isEnabled = false
        }
    }
    
    override func actionButtonAction() {
        dataStore.resetPasswordForUserEmail(emailText.text!,
                                            onFailure: handleResetFail(reason:),
                                            onSuccess: {
                                                showSimpleAlertWithTitle(applicationTitle, message: "Check your email for new password.", viewController: self, OKhandler: { _ in self.forgotPasswordDelegate?.didFinishResettingPassword()
                                                })
        }
        )
    }
    
    func handleResetFail(reason: Reason) {
        switch reason {
        case .noSuccessStatusCode(let statusCode, _):
            guard statusCode != BAD_REQUEST && statusCode != NOT_AUTHORIZED else {
                DispatchQueue.main.async {
                    showSimpleAlertWithTitle(applicationTitle, message: "There is no account registered with provided email.", viewController: self)
                    self.view.setNeedsDisplay()
                }
                return
            }
            
            fallthrough
        default:
            DispatchQueue.main.async {
                showSimpleAlertWithTitle(applicationTitle, message: "There was a problem resetting your password. Please try again or contact our support.", viewController: self)
                self.view.setNeedsDisplay()
            }
        }
    }
    
    override func skipButtonAction() {
        forgotPasswordDelegate?.didFinishResettingPassword()
    }
    
    @IBAction func emailChanged(_ sender: UITextField) {
        toggleActivateButtonEnabled()
        errorLabel.isHidden = true
        self.view.setNeedsDisplay()
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
