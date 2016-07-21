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
//  LoginViewController.swift
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var signInElementsView: UIView!
    @IBOutlet weak var signInProgressView: UIView!
    @IBOutlet weak var connectivityProblemView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var forgotPasswordAndSignup: UIView!
    
    var responseStatusCode = 0
    var userCredentials: UserCredentials!
    var dataStore: DataStore!
    var device: TrackingDevice!
    var mqttAPI: MQTTAPI!

    var isAlreadyPresented = false
    
    
    //MARK:- Init
    init?(_ coder: NSCoder? = nil) {
        
        if let coder = coder {
            super.init(coder: coder)
        } else {
            super.init(nibName: nil, bundle:nil)
        }
    }
    
    required convenience init?(coder: NSCoder) {
        self.init(coder)
    }
    
    //MARK:- Other methods
    override func viewDidLoad() {
        // Init properties
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        userCredentials = appDelegate.userCredentials
        device = appDelegate.device
        dataStore = appDelegate.dataStore
        mqttAPI = appDelegate.mqttAPI

        username.delegate = self
        userPassword.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.didSignOut), name: HexiwearDidSignOut, object: nil)

        let tapBackground = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.resignLogin))
        tapBackground.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapBackground)
        
        let scrollContentSize = CGSizeMake(320, 345);
        self.scrollView.contentSize = scrollContentSize;
    }
    

    func resignLogin() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(n: NSNotification) {
        if let userInfo = n.userInfo {
            if let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size {
                let contentInsets = UIEdgeInsetsMake(-100.0, 0.0, keyboardSize.height, 0.0)
                scrollView.contentInset = contentInsets
                scrollView.scrollIndicatorInsets = contentInsets
            }
        }
    }

    func keyboardWillHide(n: NSNotification) {
        let contentInsets = UIEdgeInsetsZero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    func didSignOut() {
        dispatch_async(dispatch_get_main_queue()) {
            self.userCredentials.clearCredentials()
            self.dataStore.clearDataStore()
            self.isAlreadyPresented = false
            self.showSignIn()
            self.presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
            self.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: self.view.window)

        self.view.endEditing(true)
        self.username.text = userCredentials.email ?? ""
        if self.username.text == demoAccount {
            self.username.text = ""
        }
        self.userPassword.text = ""
        
        setTrackingDeviceOwner()

        if isAlreadyPresented { return }
        isAlreadyPresented = true
        
        if userCredentials.accessToken != nil && userCredentials.accessTokenExpires != nil {
            fetchDataAndProceedToDetectionScreen()
        }
        else {
            showSignIn()
            userCredentials.clearCredentials()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.endEditing(true)
    }
    
//MARK: - Actions
    @IBAction func signIn(sender: UIButton) {
        UIView.transitionFromView(signInElementsView, toView: signInProgressView, duration: 0.5, options: .ShowHideTransitionViews, completion: nil)
        showSigningIn()

        // if user is logging with demo account, skip cloud connection
        guard let usr = username.text, pass = userPassword.text where usr != demoAccount || pass != demoAccount else {
            userCredentials.clearCredentials()
            userCredentials.email = demoAccount
            detectHexiwear()
            return
        }
        
        dataStore.signInWithUsername(username.text ?? "", password: userPassword.text ?? "",
            onFailure: { reason in
                switch reason {
                case .AccessTokenExpired:
                    dispatch_async(dispatch_get_main_queue()) {
                        showSimpleAlertWithTitle(applicationTitle, message: "Email/password authentication failed. Please try again.", viewController: self)
                        self.showSignIn()
                    }
                case .NoSuccessStatusCode(let statusCode):
                    if statusCode == FORBIDDEN || statusCode == NOT_AUTHORIZED {
                        dispatch_async(dispatch_get_main_queue()) {
                            showSimpleAlertWithTitle(applicationTitle, message: "Sign in failed. Email/password not recognized.", viewController: self)
                            self.showSignIn()
                        }
                    }
                default:
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showConnectivityProblem()
                    }
                }
                
            },
            onSuccess: {
                if self.userCredentials.accessToken != nil && !self.userCredentials.accessToken!.isEmpty {
                    self.fetchDataAndProceedToDetectionScreen()
                }
            }
        )
    }
    
    @IBAction func tryLoginAgain(sender: UIButton) {
        showSigningIn()
        fetchDataAndProceedToDetectionScreen()
    }
    
    func loginFailureHandler(failureReason: Reason) {
        switch failureReason {
        case .AccessTokenExpired, .NoSuccessStatusCode(_):
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in self.showSignIn() }
        case .Other(let err):
            print("Other error \(err.description)")
        default:
            dispatch_async(dispatch_get_main_queue()) { [unowned self] in self.showConnectivityProblem() }
        }
    }

    private func fetchDataAndProceedToDetectionScreen() {
        showSigningIn()
        
        if !indicatorView.isAnimating() {
            dispatch_async(dispatch_get_main_queue()) { self.indicatorView.startAnimating() }
        }
        
        // Connect currently logged in user with the device
        setTrackingDeviceOwner()
        
        dataStore.fetchAll(loginFailureHandler) {
            self.detectHexiwear()
            return
        }
    }
    
    private func detectHexiwear() {
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toDetectHexiwear", sender: self)
        }
    }
    
    private func showSignIn() {
        indicatorView.stopAnimating()
        signInProgressView.hidden = true
        signInElementsView.hidden = false
        connectivityProblemView.hidden = true
        forgotPasswordAndSignup.hidden = false
        username.becomeFirstResponder()
    }

    private func showSigningIn() {
        signInProgressView.hidden = false
        signInElementsView.hidden = true
        connectivityProblemView.hidden = true
        forgotPasswordAndSignup.hidden = true
        indicatorView.startAnimating()
    }
    
    private func showConnectivityProblem() {
        indicatorView.stopAnimating()
        signInProgressView.hidden = true
        signInElementsView.hidden = true
        forgotPasswordAndSignup.hidden = true
        connectivityProblemView.hidden = false
    }
    
    func setTrackingDeviceOwner() {
        let userAccount = userCredentials.email ?? ""
        self.device.userAccount = userAccount
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Link device with the currnet loged in user (on the client side)
        setTrackingDeviceOwner()

        if segue.identifier == "toDetectHexiwear" {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

            if let vc = segue.destinationViewController as? BaseNavigationController,
                detectHexiwearTableViewController = vc.topViewController as? DetectHexiwearTableViewController {
                detectHexiwearTableViewController.dataStore = self.dataStore
                detectHexiwearTableViewController.userCredentials = self.userCredentials
                detectHexiwearTableViewController.device = self.device
                detectHexiwearTableViewController.mqttAPI = self.mqttAPI
            }
        }
        else if segue.identifier == "toSignUp" {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

            if let vc = segue.destinationViewController as? CreateAccountTableViewController {
                vc.dataStore = self.dataStore
                vc.userCredentials = self.userCredentials
            }
        }
        else if segue.identifier == "toForgotPassword" {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)

            if let vc = segue.destinationViewController as? BaseNavigationController,
                fpc = vc.topViewController as? ForgotPasswordViewController {
                    fpc.dataStore = self.dataStore
                    fpc.forgotPasswordDelegate = self
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == username {
            userPassword.becomeFirstResponder()
            return true
        }

        textField.resignFirstResponder()
        signIn(UIButton())
        return true
    }
}

// MARK: - ForgotPasswordDelegate
extension LoginViewController: ForgotPasswordDelegate {
    func didFinishResettingPassword() {
        presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
