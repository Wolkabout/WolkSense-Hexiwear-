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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        userCredentials = appDelegate.userCredentials
        device = appDelegate.device
        dataStore = appDelegate.dataStore
        mqttAPI = appDelegate.mqttAPI
        
        username.delegate = self
        userPassword.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.didSignOut), name: NSNotification.Name(rawValue: HexiwearDidSignOut), object: nil)
        
        let tapBackground = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.resignLogin))
        tapBackground.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapBackground)
        
        let scrollContentSize = CGSize(width: 320, height: 345);
        self.scrollView.contentSize = scrollContentSize;
    }
    
    
    func resignLogin() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(_ n: Notification) {
        if let userInfo = n.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
                let contentInsets = UIEdgeInsetsMake(-100.0, 0.0, keyboardSize.height, 0.0)
                scrollView.contentInset = contentInsets
                scrollView.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    func keyboardWillHide(_ n: Notification) {
        let contentInsets = UIEdgeInsets.zero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    func didSignOut() {
        DispatchQueue.main.async {
            self.userCredentials.clearCredentials()
            self.dataStore.clearDataStore()
            self.isAlreadyPresented = false
            self.showSignIn()
            self.presentedViewController?.dismiss(animated: false, completion: nil)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.view.endEditing(true)
    }
    
    //MARK: - Actions
    @IBAction func signIn(_ sender: UIButton) {
        UIView.transition(from: signInElementsView, to: signInProgressView, duration: 0.5, options: .showHideTransitionViews, completion: nil)
        showSigningIn()
        
        // if user is logging with demo account, skip cloud connection
        guard let usr = username.text, let pass = userPassword.text, usr != demoAccount || pass != demoAccount else {
            userCredentials.clearCredentials()
            userCredentials.email = demoAccount
            detectHexiwear()
            return
        }
        
        dataStore.signInWithUsername(username.text ?? "", password: userPassword.text ?? "",
                                     onFailure: handleLoginFailure(reason:),
                                     onSuccess: {
                                        if self.userCredentials.accessToken != nil && !self.userCredentials.accessToken!.isEmpty {
                                            self.fetchDataAndProceedToDetectionScreen()
                                        }
        }
        )
    }
    
    
    func handleLoginFailure(reason: Reason) {
        switch reason {
        case .noSuccessStatusCode(let statusCode, _):
            guard statusCode != NOT_AUTHORIZED else {
                DispatchQueue.main.async {
                    showSimpleAlertWithTitle(applicationTitle, message: "The email address or password you entered did not match our records. Please enter valid credentials.", viewController: self)
                    self.showSignIn()
                }
                return
            }
            
            fallthrough
        default:
            DispatchQueue.main.async {
                showSimpleAlertWithTitle(applicationTitle, message: "There was a problem signing you in. Please try again or contact our support.", viewController: self)
                self.showSignIn()
            }
        }
    }
    
    @IBAction func tryLoginAgain(_ sender: UIButton) {
        showSigningIn()
        fetchDataAndProceedToDetectionScreen()
    }
    
    func loginFailureHandler(_ failureReason: Reason) {
        switch failureReason {
        case .accessTokenExpired, .noSuccessStatusCode(_):
            DispatchQueue.main.async { [unowned self] in self.showSignIn() }
        case .other(let err):
            print("Other error \(err.description)")
        default:
            DispatchQueue.main.async { [unowned self] in self.showConnectivityProblem() }
        }
    }
    
    fileprivate func fetchDataAndProceedToDetectionScreen() {
        showSigningIn()
        
        if !indicatorView.isAnimating {
            DispatchQueue.main.async { self.indicatorView.startAnimating() }
        }
        
        // Connect currently logged in user with the device
        setTrackingDeviceOwner()
        
        dataStore.fetchAll(loginFailureHandler) {
            self.detectHexiwear()
            return
        }
    }
    
    fileprivate func detectHexiwear() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toDetectHexiwear", sender: self)
        }
    }
    
    fileprivate func showSignIn() {
        indicatorView.stopAnimating()
        signInProgressView.isHidden = true
        signInElementsView.isHidden = false
        connectivityProblemView.isHidden = true
        forgotPasswordAndSignup.isHidden = false
        username.becomeFirstResponder()
    }
    
    fileprivate func showSigningIn() {
        signInProgressView.isHidden = false
        signInElementsView.isHidden = true
        connectivityProblemView.isHidden = true
        forgotPasswordAndSignup.isHidden = true
        indicatorView.startAnimating()
    }
    
    fileprivate func showConnectivityProblem() {
        indicatorView.stopAnimating()
        signInProgressView.isHidden = true
        signInElementsView.isHidden = true
        forgotPasswordAndSignup.isHidden = true
        connectivityProblemView.isHidden = false
    }
    
    func setTrackingDeviceOwner() {
        let userAccount = userCredentials.email ?? ""
        self.device.userAccount = userAccount
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Link device with the currnet loged in user (on the client side)
        setTrackingDeviceOwner()
        
        if segue.identifier == "toDetectHexiwear" {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            
            if let vc = segue.destination as? BaseNavigationController,
                let detectHexiwearTableViewController = vc.topViewController as? DetectHexiwearTableViewController {
                detectHexiwearTableViewController.dataStore = self.dataStore
                detectHexiwearTableViewController.userCredentials = self.userCredentials
                detectHexiwearTableViewController.device = self.device
                detectHexiwearTableViewController.mqttAPI = self.mqttAPI
            }
        }
        else if segue.identifier == "toSignUp" {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            
            if let vc = segue.destination as? CreateAccountTableViewController {
                vc.dataStore = self.dataStore
                vc.userCredentials = self.userCredentials
            }
        }
        else if segue.identifier == "toForgotPassword" {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
            
            if let vc = segue.destination as? BaseNavigationController,
                let fpc = vc.topViewController as? ForgotPasswordViewController {
                fpc.dataStore = self.dataStore
                fpc.forgotPasswordDelegate = self
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
