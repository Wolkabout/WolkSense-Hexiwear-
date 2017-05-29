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
//  ActivateDeviceViewController.swift
//

import UIKit
import CoreBluetooth
import JGProgressHUD

protocol DeviceActivationDelegate {
    func didActivateDevice(_ pointId: Int, serials: SerialMapping)
    func didSkipActivation()
}

class SingleTextViewController: UIViewController {
    
    var skipButton: UIBarButtonItem!
    var actionButton: UIBarButtonItem!
    
    var dataStore: DataStore!
    var selectedPeripheral: CBPeripheral!
    var selectedPeripheralSerial: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        skipButton = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(SingleTextViewController.skipButtonAction))
        navigationItem.leftBarButtonItems = [skipButton]
        actionButton = UIBarButtonItem(title: "Activate", style: .plain, target: self, action: #selector(SingleTextViewController.actionButtonAction))
        actionButton.isEnabled = false
        navigationItem.rightBarButtonItems = [actionButton]
        
        if selectedPeripheral != nil {
            selectedPeripheralSerial = selectedPeripheral!.identifier.uuidString
        }
        
    }
    
    func toggleActivateButtonEnabled() {
        print("Override in subclass")
    }
    
    func actionButtonAction() {
        print("Override in subclass")
    }
    
    func skipButtonAction() {
        print("Override in subclass")
    }
    
    
}

class ActivateDeviceViewController : SingleTextViewController {
    
    @IBOutlet weak var deviceName: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var registerWithUsedName: UIButton!
    
    var deviceActivationDelegate: DeviceActivationDelegate?
    var selectableDevices: [Device] = []
    var selectedDeviceSerial: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        skipButton.title = "Skip"
        actionButton.title = "Activate"
        deviceName.delegate = self
        title = "Activate hexiwear"
        errorLabel.isHidden = true
        
        selectableDevices = dataStore.points
            .filter { $0.owner.uppercased() == "SELF" && $0.isHexiwear() }
            .sorted   { $0.name.uppercased() < $1.name.uppercased() }
        registerWithUsedName.isEnabled = selectableDevices.count > 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAlreadyRegisteredNames" {
            if let vc = segue.destination as? ShowDevicesTableViewController {
                vc.selectableDevices = selectableDevices
                vc.activatedDeviceDelegate = self
            }
        }
    }
    
    override func toggleActivateButtonEnabled() {
        if let dn = deviceName.text, dn.isEmpty == false {
            actionButton.isEnabled = true
        }
        else {
            actionButton.isEnabled = false
        }
    }
    
    override func actionButtonAction() {
        
        guard selectedPeripheralSerial != "" else {
            errorLabel.text = "Error activating HEXIWEAR. Missing serial number."
            errorLabel.isHidden = false
            view.setNeedsDisplay()
            return
        }
        
        let progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = "Activating..."
        progressHUD?.show(in: self.view, animated: true)
        
        dataStore.getSerial(
            // get serial failure
            { _ in self.activationErrorHandler(progressHUD!) },
            
            // get serial success
            onSuccess: { serial in
                let deviceName = self.deviceName.text!
                print("ACTI -- device: " + deviceName)
                
                // If there is no device selected to continue with...
                guard self.selectedDeviceSerial.characters.count > 0 else {
                    // ... just activate new device
                    print("ACTI -- no old serial, just activate new one")
                    self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD!)
                    return
                }
                
                // check if already selected device serial is activated
                if self.selectedDeviceSerial.characters.count > 0 {
                    self.dataStore.getActivationStatusForSerial( self.selectedDeviceSerial,
                                                                 onFailure: { _ in self.activationErrorHandler(progressHUD!) },
                                                                 onSuccess: { activationStatus in
                                                                    DispatchQueue.main.async() {
                                                                        
                                                                        // ... if it is activated then first deactivate device with old serial number
                                                                        if activationStatus == "ACTIVATED" {
                                                                            print("ACTI -- old serial ACTIVATED")
                                                                            self.dataStore.deactivateDevice(self.selectedDeviceSerial,
                                                                                                            onFailure: { _ in self.activationErrorHandler(progressHUD!) },
                                                                                                            onSuccess: {
                                                                                                                print("ACTI -- old serial deactivated, proceeding with new serial activation")
                                                                                                                
                                                                                                                // ... and activate device with new serial number
                                                                                                                self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD!)
                                                                            }
                                                                            )
                                                                        }
                                                                        else {
                                                                            // ... if it is not activated then activate device with new serial number
                                                                            print("ACTI -- old serial NOT ACTIVATED, proceeding with new serial activation")
                                                                            self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD!)
                                                                        }
                                                                    }
                    }
                    )
                }
        }
        )
    }
    
    fileprivate func activationErrorHandler(_ progressHUD: JGProgressHUD) {
        DispatchQueue.main.async {
            progressHUD.dismiss()
            self.errorLabel.text = "Error activating device!"
            self.errorLabel.isHidden = false
            self.view.setNeedsDisplay()
        }
    }
    
    fileprivate func activateDeviceWithSerial(_ serial: String, deviceName: String, progressHUD: JGProgressHUD) {
        dataStore.activateDeviceWithSerialAndName(serial, deviceName: deviceName,
                                                  // activate failure
            onFailure: { reason in
                DispatchQueue.main.async {
                    progressHUD.dismiss()
                    var messageText = ""
                    switch reason {
                    case .noSuccessStatusCode(let statusCode, _):
                        if statusCode == CONFLICT {
                            messageText = "Device name is already used! Try with different name or tap on 'Continue existing device'"
                        }
                        else {
                            messageText = "Error activating device!"
                        }
                    default:
                        messageText = "Error activating device!"
                    }
                    self.errorLabel.text = messageText
                    self.errorLabel.isHidden = false
                    self.view.setNeedsDisplay()
                }
        },
            
            // activate success
            onSuccess: { pointId, password in
                DispatchQueue.main.async {
                    progressHUD.dismiss()
                }
                print("ACTI -- Activated \(serial) with pointId: \(pointId)")
                let serialMapping = SerialMapping(hexiSerial: self.selectedPeripheralSerial, wolkSerial: serial, wolkPassword: password)
                self.dataStore.fetchAll(
                    { _ in
                        self.deviceActivationDelegate?.didActivateDevice(pointId, serials: serialMapping)
                },
                    onSuccess: {
                        self.deviceActivationDelegate?.didActivateDevice(pointId, serials: serialMapping)
                }
                )
        }
        )
    }
    
    override func skipButtonAction() {
        deviceActivationDelegate?.didSkipActivation()
    }
    
    @IBAction func deviceNameChanged(_ sender: UITextField) {
        toggleActivateButtonEnabled()
        selectedDeviceSerial = ""
        errorLabel.isHidden = true
        self.view.setNeedsDisplay()
    }
}

extension ActivateDeviceViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ActivateDeviceViewController: ActivatedDeviceDelegate {
    func didSelectAlreadyActivatedName(_ name: String, serial: String) {
        navigationController?.popViewController(animated: true)
        deviceName.text = name
        selectedDeviceSerial = serial
        toggleActivateButtonEnabled()
    }
}

