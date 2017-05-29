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
//  SettingsTableViewController.swift
//

import UIKit
import JGProgressHUD

protocol HexiwearSettingsDelegate {
    func didSignOut()
    func didSetTime()
}

class SettingaBaseTableViewController: UITableViewController {
    @IBOutlet weak var userAccountLabel: UILabel!
    @IBOutlet weak var sendToCloudSwitch: UISwitch!
    @IBOutlet weak var sendEvery: UISegmentedControl!
    
    var delegate: HexiwearSettingsDelegate?
    var trackingDevice: TrackingDevice!
    var dataStore: DataStore!
    let progressHUD = JGProgressHUD(style: .dark)
    var isDemoUser = false
    
    override func viewWillAppear(_ animated: Bool) {
        userAccountLabel.text = trackingDevice.userAccount
        sendToCloudSwitch.isOn = !trackingDevice.trackingIsOff
        
        let heartbeat = trackingDevice.heartbeat
        if heartbeat == 5 {
            sendEvery.selectedSegmentIndex = 0
        }
        else if heartbeat == 60 {
            sendEvery.selectedSegmentIndex = 1
        }
        else if heartbeat == 300 {
            sendEvery.selectedSegmentIndex = 2
        }
        else {
            sendEvery.selectedSegmentIndex = 0
        }
        
    }
    
    fileprivate func logOut() {
        let msg: String = "Sign out?"
        let alert = UIAlertController(title: applicationTitle, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        
        let remove = UIAlertAction(title: "Sign out", style: .destructive) { action in
            self.delegate?.didSignOut()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(remove)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendToCloud(_ sender: AnyObject) {
        trackingDevice.trackingIsOff = !sendToCloudSwitch.isOn
        tableView.reloadData()
    }
    
    @IBAction func sendEveryChanged(_ sender: UISegmentedControl) {
        switch sendEvery.selectedSegmentIndex {
        case 0: trackingDevice.heartbeat = 5
        case 1: trackingDevice.heartbeat = 60
        case 2: trackingDevice.heartbeat = 300
        default: trackingDevice.heartbeat = 5
        }
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0  && indexPath.row == 0 { // log out
            logOut()
        }
        else if indexPath.section == 0 && indexPath.row == 1 { // change password
            performSegue(withIdentifier: "toChangePasswordBase", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChangePasswordBase" {
            if let vc = segue.destination as? ChangePasswordTableViewController {
                vc.dataStore = self.dataStore
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // only show user account for demo user
        if isDemoUser {
            if indexPath.section == 0 && indexPath.row == 0 {
                return 44.0
            }
            return 0.0
        }
        
        
        if indexPath.section == 1 && indexPath.row == 1 { // send every
            return trackingDevice.trackingIsOff ? 0.0 : 44.0
        }
        
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Signed in"
        }
        else if section == 1 {
            return isDemoUser ? "" : "Cloud"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tap on email to sign out"
        }
        else if section == 1 {
            return isDemoUser ? "" : "When ON, readings will be sent to the cloud"
        }
        return nil
    }
    
}

class HexiSettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var batterySwitch: UISwitch!
    @IBOutlet weak var temperatureSwitch: UISwitch!
    @IBOutlet weak var humiditySwitch: UISwitch!
    @IBOutlet weak var pressureSwitch: UISwitch!
    @IBOutlet weak var lightSwitch: UISwitch!
    @IBOutlet weak var acceleratorSwitch: UISwitch!
    @IBOutlet weak var gyroSwitch: UISwitch!
    @IBOutlet weak var magnetometerSwitch: UISwitch!
    @IBOutlet weak var stepsSwitch: UISwitch!
    @IBOutlet weak var caloriesSwitch: UISwitch!
    @IBOutlet weak var heartrateSwitch: UISwitch!
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var firmwareRevision: UILabel!
    
    @IBOutlet weak var batteryCell: UITableViewCell!
    @IBOutlet weak var temperatureCell: UITableViewCell!
    @IBOutlet weak var humidityCell: UITableViewCell!
    @IBOutlet weak var pressureCell: UITableViewCell!
    @IBOutlet weak var lightCell: UITableViewCell!
    @IBOutlet weak var accCell: UITableViewCell!
    @IBOutlet weak var magnetCell: UITableViewCell!
    @IBOutlet weak var gyroCell: UITableViewCell!
    @IBOutlet weak var stepsCell: UITableViewCell!
    @IBOutlet weak var caloriesCell: UITableViewCell!
    @IBOutlet weak var heartrateCell: UITableViewCell!
    
    
    
    @IBOutlet weak var batteryCellImageView: UIImageView!
    @IBOutlet weak var temperatureCellImageView: UIImageView!
    @IBOutlet weak var humidityCellImageView: UIImageView!
    @IBOutlet weak var pressureCellImageView: UIImageView!
    @IBOutlet weak var lightCellImageView: UIImageView!
    @IBOutlet weak var accCellImageView: UIImageView!
    @IBOutlet weak var magnetCellImageView: UIImageView!
    @IBOutlet weak var gyroCellImageView: UIImageView!
    @IBOutlet weak var stepsCellImageView: UIImageView!
    @IBOutlet weak var caloriesImageView: UIImageView!
    @IBOutlet weak var heartrateImageView: UIImageView!
    
    
    var deviceInfo: DeviceInfo!
    var hexiwearMode: HexiwearMode!
    var availableReadings: [HexiwearReading] = []
    
    var delegate: HexiwearSettingsDelegate?
    var trackingDevice: TrackingDevice!
    var dataStore: DataStore!
    let progressHUD = JGProgressHUD(style: .dark)
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        batterySwitch.isOn = !trackingDevice.isBatteryOff
        temperatureSwitch.isOn = !trackingDevice.isTemperatureOff
        humiditySwitch.isOn = !trackingDevice.isHumidityOff
        pressureSwitch.isOn = !trackingDevice.isPressureOff
        lightSwitch.isOn = !trackingDevice.isLightOff
        acceleratorSwitch.isOn = !trackingDevice.isAcceleratorOff
        magnetometerSwitch.isOn = !trackingDevice.isMagnetometerOff
        gyroSwitch.isOn = !trackingDevice.isGyroOff
        stepsSwitch.isOn = !trackingDevice.isStepsOff
        caloriesSwitch.isOn = !trackingDevice.isCaloriesOff
        heartrateSwitch.isOn = !trackingDevice.isHeartRateOff
        manufacturerLabel.text = deviceInfo.manufacturer
        firmwareRevision.text = deviceInfo.firmwareRevision
        
        guard let mode = hexiwearMode else { return }
        
        availableReadings = HexiwearMode.getReadingsForMode(mode)
        
        batterySwitch.isEnabled = availableReadings.contains(.battery)
        temperatureSwitch.isEnabled = availableReadings.contains(.temperature)
        humiditySwitch.isEnabled = availableReadings.contains(.humidity)
        pressureSwitch.isEnabled = availableReadings.contains(.pressure)
        lightSwitch.isEnabled = availableReadings.contains(.light)
        acceleratorSwitch.isEnabled = availableReadings.contains(.accelerometer)
        magnetometerSwitch.isEnabled = availableReadings.contains(.magnetometer)
        gyroSwitch.isEnabled = availableReadings.contains(.gyro)
        stepsSwitch.isEnabled = availableReadings.contains(.pedometer)
        caloriesSwitch.isEnabled = availableReadings.contains(.calories)
        heartrateSwitch.isEnabled = availableReadings.contains(.heartrate)
        
        batteryCellImageView?.image = UIImage(named: "battery")
        batteryCellImageView?.alpha = 0.6
        batteryCellImageView?.contentMode = .scaleAspectFit
        temperatureCellImageView?.image = UIImage(named: "temperature")
        temperatureCellImageView?.alpha = 0.6
        temperatureCellImageView?.contentMode = .scaleAspectFit
        humidityCellImageView?.image = UIImage(named: "humidity")
        humidityCellImageView?.alpha = 0.6
        humidityCellImageView?.contentMode = .scaleAspectFit
        pressureCellImageView?.image = UIImage(named: "pressure")
        pressureCellImageView?.alpha = 0.6
        pressureCellImageView?.contentMode = .scaleAspectFit
        lightCellImageView?.image = UIImage(named: "light_icon")
        lightCellImageView?.alpha = 0.6
        lightCellImageView?.contentMode = .scaleAspectFit
        accCellImageView?.image = UIImage(named: "accelerometer")
        accCellImageView?.alpha = 0.6
        accCellImageView?.contentMode = .scaleAspectFit
        magnetCellImageView?.image = UIImage(named: "magnet_icon")
        magnetCellImageView?.alpha = 0.6
        magnetCellImageView?.contentMode = .scaleAspectFit
        gyroCellImageView?.image = UIImage(named: "gyroscope")
        gyroCellImageView?.alpha = 0.6
        gyroCellImageView?.contentMode = .scaleAspectFit
        stepsCellImageView?.image = UIImage(named: "steps_icon")
        stepsCellImageView?.alpha = 0.6
        stepsCellImageView?.contentMode = .scaleAspectFit
        caloriesImageView.image = UIImage(named: "calories")
        caloriesImageView.alpha = 0.6
        caloriesImageView.contentMode = .scaleAspectFit
        heartrateImageView.image = UIImage(named: "heartbeat_icon")
        heartrateImageView.alpha = 0.6
        heartrateImageView.contentMode = .scaleAspectFit
        
        tableView.reloadData()
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func batterySwitchAction(_ sender: AnyObject) {
        trackingDevice.isBatteryOff = !batterySwitch.isOn
    }
    
    @IBAction func weatherSwitchAction(_ sender: AnyObject) {
        trackingDevice.isTemperatureOff = !temperatureSwitch.isOn
    }
    
    @IBAction func humiditySwitchAction(_ sender: UISwitch) {
        trackingDevice.isHumidityOff = !humiditySwitch.isOn
    }
    
    @IBAction func pressureSwitchAction(_ sender: UISwitch) {
        trackingDevice.isPressureOff = !pressureSwitch.isOn
    }
    
    @IBAction func lightSwitchAction(_ sender: UISwitch) {
        trackingDevice.isLightOff = !lightSwitch.isOn
    }
    
    @IBAction func acceleratorSwitchAction(_ sender: AnyObject) {
        trackingDevice.isAcceleratorOff = !acceleratorSwitch.isOn
    }
    
    @IBAction func magnetometerSwitchAction(_ sender: AnyObject) {
        trackingDevice.isMagnetometerOff = !magnetometerSwitch.isOn
    }
    
    @IBAction func gyroSwitchAction(_ sender: AnyObject) {
        trackingDevice.isGyroOff = !gyroSwitch.isOn
    }
    
    @IBAction func stepsSwitchAction(_ sender: AnyObject) {
        trackingDevice.isStepsOff = !stepsSwitch.isOn
    }
    
    @IBAction func caloriesSwitchAction(_ sender: UISwitch) {
        trackingDevice.isCaloriesOff = !caloriesSwitch.isOn
    }
    
    @IBAction func heartrateSwitchAction(_ sender: UISwitch) {
        trackingDevice.isHeartRateOff = !heartrateSwitch.isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1  && indexPath.row == 0 { // set time
            setTime()
        }
    }
    
    fileprivate func setTime() {
        delegate?.didSetTime()
    }
    
}

extension HexiSettingsTableViewController: HexiwearTimeSettingDelegate {
    func didStartSettingTime() {
        let time = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        let datetimestring = formatter.string(from: time)
        progressHUD?.textLabel.text = "Setting time on HEXIWEAR to \(datetimestring)"
        progressHUD?.show(in: self.view, animated: true)
        
    }
    
    func didFinishSettingTime(_ success: Bool) {
        delay(1.0) {
            if success {
                self.progressHUD?.textLabel.text = "Time set successfully!"
            }
            else {
                self.progressHUD?.textLabel.text = "Failure setting time!"
            }
        }
        delay(2.0) {
            self.progressHUD?.dismiss()
        }
        
    }
}
