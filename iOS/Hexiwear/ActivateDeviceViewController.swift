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

protocol DeviceActivationDelegate {
    func didActivateDevice(pointId: Int, serials: SerialMapping)
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
        skipButton = UIBarButtonItem(title: "Skip", style: .Plain, target: self, action: #selector(SingleTextViewController.skipButtonAction))
        navigationItem.leftBarButtonItems = [skipButton]
        actionButton = UIBarButtonItem(title: "Activate", style: .Plain, target: self, action: #selector(SingleTextViewController.actionButtonAction))
        actionButton.enabled = false
        navigationItem.rightBarButtonItems = [actionButton]
        
        if selectedPeripheral != nil {
            selectedPeripheralSerial = selectedPeripheral!.identifier.UUIDString
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
        errorLabel.hidden = true
        
        selectableDevices = dataStore.points
            .filter { $0.owner.uppercaseString == "SELF" && $0.isHexiwear() }
            .sort   { $0.name.uppercaseString < $1.name.uppercaseString }
        registerWithUsedName.enabled = selectableDevices.count > 0
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toAlreadyRegisteredNames" {
            if let vc = segue.destinationViewController as? ShowDevicesTableViewController {
                vc.selectableDevices = selectableDevices
                vc.activatedDeviceDelegate = self
            }
        }
    }
    
    override func toggleActivateButtonEnabled() {
        if let dn = deviceName.text where dn.isEmpty == false {
            actionButton.enabled = true
        }
        else {
            actionButton.enabled = false
        }
    }

    override func actionButtonAction() {
        
        guard selectedPeripheralSerial != "" else {
            errorLabel.text = "Error activating HEXIWEAR. Missing serial number."
            errorLabel.hidden = false
            view.setNeedsDisplay()
            return
        }
        
        let progressHUD = JGProgressHUD(style: .Dark)
        progressHUD.textLabel.text = "Activating..."
        progressHUD.showInView(self.view, animated: true)
        
        dataStore.getSerial(
            // get serial failure
            { _ in self.activationErrorHandler(progressHUD) },

            // get serial success
            onSuccess: { serial in
                let deviceName = self.deviceName.text!
                print("ACTI -- device: " + deviceName)
                
                // If there is no device selected to continue with...
                guard self.selectedDeviceSerial.characters.count > 0 else {
                    // ... just activate new device
                    print("ACTI -- no old serial, just activate new one")
                    self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD)
                    return
                }
                
                // check if already selected device serial is activated
                if self.selectedDeviceSerial.characters.count > 0 {
                    self.dataStore.getActivationStatusForSerial( self.selectedDeviceSerial,
                        onFailure: { _ in self.activationErrorHandler(progressHUD) },
                        onSuccess: { activationStatus in
                        dispatch_async(dispatch_get_main_queue()) {

                            // ... if it is activated then first deactivate device with old serial number
                            if activationStatus == "ACTIVATED" {
                                print("ACTI -- old serial ACTIVATED")
                                self.dataStore.deactivateDevice(self.selectedDeviceSerial,
                                    onFailure: { _ in self.activationErrorHandler(progressHUD) },
                                    onSuccess: {
                                        print("ACTI -- old serial deactivated, proceeding with new serial activation")
                            
                                        // ... and activate device with new serial number
                                        self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD)
                                    }
                                )
                            }
                            else {
                                // ... if it is not activated then activate device with new serial number
                                print("ACTI -- old serial NOT ACTIVATED, proceeding with new serial activation")
                                self.activateDeviceWithSerial(serial, deviceName: deviceName, progressHUD: progressHUD)
                            }
                        }
                    }
                    )
                }
            }
        )
    }
    
    private func activationErrorHandler(progressHUD: JGProgressHUD) {
        dispatch_async(dispatch_get_main_queue()) {
            progressHUD.dismiss()
            self.errorLabel.text = "Error activating device!"
            self.errorLabel.hidden = false
            self.view.setNeedsDisplay()
        }
    }
    
    private func activateDeviceWithSerial(serial: String, deviceName: String, progressHUD: JGProgressHUD) {
        dataStore.activateDeviceWithSerialAndName(serial, deviceName: deviceName,
            // activate failure
            onFailure: { reason in
                dispatch_async(dispatch_get_main_queue()) {
                    progressHUD.dismiss()
                    var messageText = ""
                    switch reason {
                    case .NoSuccessStatusCode(let statusCode):
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
                    self.errorLabel.hidden = false
                    self.view.setNeedsDisplay()
                }
            },
            
            // activate success
            onSuccess: { pointId, password in
                dispatch_async(dispatch_get_main_queue()) {
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

    @IBAction func deviceNameChanged(sender: UITextField) {
        toggleActivateButtonEnabled()
        selectedDeviceSerial = ""
        errorLabel.hidden = true
        self.view.setNeedsDisplay()
    }
}

extension ActivateDeviceViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ActivateDeviceViewController: ActivatedDeviceDelegate {
    func didSelectAlreadyActivatedName(name: String, serial: String) {
        navigationController?.popViewControllerAnimated(true)
        deviceName.text = name
        selectedDeviceSerial = serial
        toggleActivateButtonEnabled()
    }
}

