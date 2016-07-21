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
    let progressHUD = JGProgressHUD(style: .Dark)
    var isDemoUser = false

    override func viewWillAppear(animated: Bool) {
        userAccountLabel.text = trackingDevice.userAccount
        sendToCloudSwitch.on = !trackingDevice.trackingIsOff ?? true
        
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
    
    private func logOut() {
        let msg: String = "Sign out?"
        let alert = UIAlertController(title: applicationTitle, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        
        let remove = UIAlertAction(title: "Sign out", style: UIAlertActionStyle.Default) { action in
            self.delegate?.didSignOut()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) { action in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(remove)
        alert.addAction(cancel)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendToCloud(sender: AnyObject) {
        trackingDevice.trackingIsOff = !sendToCloudSwitch.on
        tableView.reloadData()
    }

    @IBAction func sendEveryChanged(sender: UISegmentedControl) {
        switch sendEvery.selectedSegmentIndex {
            case 0: trackingDevice.heartbeat = 5
            case 1: trackingDevice.heartbeat = 60
            case 2: trackingDevice.heartbeat = 300
            default: trackingDevice.heartbeat = 5
        }
    }
    
    @IBAction func doneAction(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0  && indexPath.row == 0 { // log out
            logOut()
        }
        else if indexPath.section == 0 && indexPath.row == 1 { // change password
            performSegueWithIdentifier("toChangePasswordBase", sender: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toChangePasswordBase" {
            if let vc = segue.destinationViewController as? ChangePasswordTableViewController {
                vc.dataStore = self.dataStore
                vc.userEmail = trackingDevice.userAccount
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Signed in"
        }
        else if section == 1 {
            return isDemoUser ? "" : "Cloud"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
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
    let progressHUD = JGProgressHUD(style: .Dark)

    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        batterySwitch.on = !trackingDevice.isBatteryOff ?? true
        temperatureSwitch.on = !trackingDevice.isTemperatureOff ?? true
        humiditySwitch.on = !trackingDevice.isHumidityOff ?? true
        pressureSwitch.on = !trackingDevice.isPressureOff ?? true
        lightSwitch.on = !trackingDevice.isLightOff ?? true
        acceleratorSwitch.on = !trackingDevice.isAcceleratorOff ?? true
        magnetometerSwitch.on = !trackingDevice.isMagnetometerOff ?? true
        gyroSwitch.on = !trackingDevice.isGyroOff ?? true
        stepsSwitch.on = !trackingDevice.isStepsOff ?? true
        caloriesSwitch.on = !trackingDevice.isCaloriesOff ?? true
        heartrateSwitch.on = !trackingDevice.isHeartRateOff ?? true
        manufacturerLabel.text = deviceInfo.manufacturer
        firmwareRevision.text = deviceInfo.firmwareRevision
        
        guard let mode = hexiwearMode else { return }
        
        availableReadings = HexiwearMode.getReadingsForMode(mode)
        
        batterySwitch.enabled = availableReadings.contains(.BATTERY)
        temperatureSwitch.enabled = availableReadings.contains(.TEMPERATURE)
        humiditySwitch.enabled = availableReadings.contains(.HUMIDITY)
        pressureSwitch.enabled = availableReadings.contains(.PRESSURE)
        lightSwitch.enabled = availableReadings.contains(.LIGHT)
        acceleratorSwitch.enabled = availableReadings.contains(.ACCELEROMETER)
        magnetometerSwitch.enabled = availableReadings.contains(.MAGNETOMETER)
        gyroSwitch.enabled = availableReadings.contains(.GYRO)
        stepsSwitch.enabled = availableReadings.contains(.PEDOMETER)
        caloriesSwitch.enabled = availableReadings.contains(.CALORIES)
        heartrateSwitch.enabled = availableReadings.contains(.HEARTRATE)
        
        batteryCellImageView?.image = UIImage(named: "battery")
        batteryCellImageView?.alpha = 0.6
        batteryCellImageView?.contentMode = .ScaleAspectFit
        temperatureCellImageView?.image = UIImage(named: "temperature")
        temperatureCellImageView?.alpha = 0.6
        temperatureCellImageView?.contentMode = .ScaleAspectFit
        humidityCellImageView?.image = UIImage(named: "humidity")
        humidityCellImageView?.alpha = 0.6
        humidityCellImageView?.contentMode = .ScaleAspectFit
        pressureCellImageView?.image = UIImage(named: "pressure")
        pressureCellImageView?.alpha = 0.6
        pressureCellImageView?.contentMode = .ScaleAspectFit
        lightCellImageView?.image = UIImage(named: "light_icon")
        lightCellImageView?.alpha = 0.6
        lightCellImageView?.contentMode = .ScaleAspectFit
        accCellImageView?.image = UIImage(named: "accelerometer")
        accCellImageView?.alpha = 0.6
        accCellImageView?.contentMode = .ScaleAspectFit
        magnetCellImageView?.image = UIImage(named: "magnet_icon")
        magnetCellImageView?.alpha = 0.6
        magnetCellImageView?.contentMode = .ScaleAspectFit
        gyroCellImageView?.image = UIImage(named: "gyroscope")
        gyroCellImageView?.alpha = 0.6
        gyroCellImageView?.contentMode = .ScaleAspectFit
        stepsCellImageView?.image = UIImage(named: "steps_icon")
        stepsCellImageView?.alpha = 0.6
        stepsCellImageView?.contentMode = .ScaleAspectFit
        caloriesImageView.image = UIImage(named: "calories")
        caloriesImageView.alpha = 0.6
        caloriesImageView.contentMode = .ScaleAspectFit
        heartrateImageView.image = UIImage(named: "heartbeat_icon")
        heartrateImageView.alpha = 0.6
        heartrateImageView.contentMode = .ScaleAspectFit

        tableView.reloadData()
    }
    
    @IBAction func doneAction(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func batterySwitchAction(sender: AnyObject) {
        trackingDevice.isBatteryOff = !batterySwitch.on
    }
    
    @IBAction func weatherSwitchAction(sender: AnyObject) {
        trackingDevice.isTemperatureOff = !temperatureSwitch.on
    }
    
    @IBAction func humiditySwitchAction(sender: UISwitch) {
        trackingDevice.isHumidityOff = !humiditySwitch.on
    }
    
    @IBAction func pressureSwitchAction(sender: UISwitch) {
        trackingDevice.isPressureOff = !pressureSwitch.on
    }
    
    @IBAction func lightSwitchAction(sender: UISwitch) {
        trackingDevice.isLightOff = !lightSwitch.on
    }
    
    @IBAction func acceleratorSwitchAction(sender: AnyObject) {
        trackingDevice.isAcceleratorOff = !acceleratorSwitch.on
    }
    
    @IBAction func magnetometerSwitchAction(sender: AnyObject) {
        trackingDevice.isMagnetometerOff = !magnetometerSwitch.on
    }
    
    @IBAction func gyroSwitchAction(sender: AnyObject) {
        trackingDevice.isGyroOff = !gyroSwitch.on
    }
    
    @IBAction func stepsSwitchAction(sender: AnyObject) {
        trackingDevice.isStepsOff = !stepsSwitch.on
    }
    
    @IBAction func caloriesSwitchAction(sender: UISwitch) {
        trackingDevice.isCaloriesOff = !caloriesSwitch.on
    }

    @IBAction func heartrateSwitchAction(sender: UISwitch) {
        trackingDevice.isHeartRateOff = !heartrateSwitch.on
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1  && indexPath.row == 0 { // set time
            setTime()
        }
    }
    
    private func setTime() {
        delegate?.didSetTime()
    }
    
}

extension HexiSettingsTableViewController: HexiwearTimeSettingDelegate {
    func didStartSettingTime() {
        let time = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        let datetimestring = formatter.stringFromDate(time)
        progressHUD.textLabel.text = "Setting time on HEXIWEAR to \(datetimestring)"
        progressHUD.showInView(self.view, animated: true)
        
    }
    
    func didFinishSettingTime(success: Bool) {
        delay(1.0) {
            if success {
                self.progressHUD.textLabel.text = "Time set successfully!"
            }
            else {
                self.progressHUD.textLabel.text = "Failure setting time!"
            }
        }
        delay(2.0) {
            self.progressHUD.dismiss()
        }
        
    }
}
