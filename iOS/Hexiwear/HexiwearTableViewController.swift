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
//  HexiwearTableViewController.swift
//

import UIKit
import CoreBluetooth

protocol HexiwearPeripheralDelegate {
    func didUnwind()
    func didLoseBonding()
    func willDisconnectOnSignOut()
}

protocol HexiwearTimeSettingDelegate {
    func didStartSettingTime()
    func didFinishSettingTime(success: Bool)
}

class HexiwearTableViewController: UITableViewController {

    @IBOutlet weak var modeCell: WeatherTableViewCell!
    @IBOutlet weak var disconnectedCell: WeatherTableViewCell!
    @IBOutlet weak var batteryCell: WeatherTableViewCell!
    @IBOutlet weak var temperatureCell: WeatherTableViewCell!
    @IBOutlet weak var humidityCell: WeatherTableViewCell!
    @IBOutlet weak var pressureCell: WeatherTableViewCell!
    @IBOutlet weak var acceleratorCell: AcceleratorTableViewCell!
    @IBOutlet weak var gyroCell: GyroTableViewCell!
    @IBOutlet weak var magnetometerCell: AcceleratorTableViewCell!
    @IBOutlet weak var stepsCell: WeatherTableViewCell!
    @IBOutlet weak var caloriesCell: WeatherTableViewCell!
    @IBOutlet weak var heartRateCell: WeatherTableViewCell!
    @IBOutlet weak var lightCell: WeatherTableViewCell!
    
    var dataStore: DataStore!

    // BLE
    var hexiwearPeripheral : CBPeripheral!
    var hexiwearReadings = HexiwearReadings()
    var availableReadings: [HexiwearReading] = []
    var deviceInfo = DeviceInfo()
    
    var batteryCharacteristics: CBCharacteristic?
    var motionAccelCharacteristics: CBCharacteristic?
    var motionMagnetCharacteristics: CBCharacteristic?
    var motionGyroCharacteristics: CBCharacteristic?
    var weatherLightCharacteristics: CBCharacteristic?
    var weatherTemperatureCharacteristics: CBCharacteristic?
    var weatherHumidityCharacteristics: CBCharacteristic?
    var weatherPressureCharacteristics: CBCharacteristic?
    var healthHeartRateCharacteristics: CBCharacteristic?
    var healthStepsCharacteristics: CBCharacteristic?
    var healthCaloriesCharacteristics: CBCharacteristic?
    
    var diManufacturerCharacteristics: CBCharacteristic?
    var diHWRevisionCharacteristics: CBCharacteristic?
    var diFWRevisionCharacteristics: CBCharacteristic?
    
    var serialNumberCharacteristic: CBCharacteristic?
    var hexiwearModeCharacteristic: CBCharacteristic?
    
    var alertInCharacteristic: CBCharacteristic?
    
    var readTimer: NSTimer!
    var isBatteryRead = false
    var shouldPublishToMQTT = false

    var isDemoAccount = true

    // OTAP vars
    var isOTAPEnabled         = false // if hexiware is in OTAP mode this will be true
    
    // Tracking device
    var trackingDevice: TrackingDevice!
    var mqttAPI: MQTTAPI!
    var wolkSerialForHexiserial: String?
    var wolkPasswordForHexiserial: String?
    
    var timeSettingDelegate: HexiwearTimeSettingDelegate?
    
    var batteryIsOn = true
    var temperatureIsOn = true
    var humidityIsOn = true
    var pressureIsOn = true
    var lightIsOn = true
    var acceleratorIsOn = true
    var magnetometerIsOn = true
    var gyroIsOn = true
    var stepsIsOn = true
    var caloriesIsOn = true
    var heartrateIsOn = true
    var sendToCloudIsOn = true
    
    var shouldDiscoverServices = true
    var isConnected = true
    
    // Delegate
    var hexiwearDelegate: HexiwearPeripheralDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Know when MQTT has published data
        mqttAPI.setAuthorisationOptions(wolkSerialForHexiserial ?? "", password: wolkPasswordForHexiserial ?? "")
        mqttAPI.mqttDelegate = self
        
        // Setup polling timer
        readTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(HexiwearTableViewController.readCharacteristics), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        batteryIsOn = !trackingDevice.isBatteryOff ?? true
        temperatureIsOn = !trackingDevice.isTemperatureOff ?? true
        humidityIsOn = !trackingDevice.isHumidityOff ?? true
        pressureIsOn = !trackingDevice.isPressureOff ?? true
        lightIsOn = !trackingDevice.isLightOff ?? true
        acceleratorIsOn = !trackingDevice.isAcceleratorOff ?? true
        magnetometerIsOn = !trackingDevice.isMagnetometerOff ?? true
        gyroIsOn = !trackingDevice.isGyroOff ?? true
        stepsIsOn = !trackingDevice.isStepsOff ?? true
        caloriesIsOn = !trackingDevice.isCaloriesOff ?? true
        heartrateIsOn = !trackingDevice.isHeartRateOff ?? true
        sendToCloudIsOn = !trackingDevice.trackingIsOff ?? true

        tableView.reloadData()
        
        // Discover hexiwear services
        discoverHexiwearServices()
    }
    
    private func discoverHexiwearServices() {
        if shouldDiscoverServices && hexiwearPeripheral != nil {
            hexiwearPeripheral.delegate = self
            hexiwearPeripheral.discoverServices(nil)
            shouldDiscoverServices = false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if isMovingFromParentViewController() {
            stopTheTimer()
            hexiwearDelegate?.didUnwind()
        }
    }
    
    private func stopTheTimer() {
        readTimer.invalidate()
        readTimer = nil
    }

    @IBAction func goToSettings(sender: UIBarButtonItem) {
        performSegueWithIdentifier("toSettings", sender: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toSettings" {
            if let nc = segue.destinationViewController as? BaseNavigationController,
                vc = nc.topViewController as? HexiSettingsTableViewController {
                    vc.title = "Hexiwear settings"
                    vc.dataStore = self.dataStore
                    vc.trackingDevice = self.trackingDevice
                    vc.deviceInfo = self.deviceInfo
                    vc.hexiwearMode = self.hexiwearReadings.hexiwearMode
                    vc.delegate = self
                    self.timeSettingDelegate = vc
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cellRow = indexPath.row
        let cellHeight: CGFloat = 160.0
        
        if cellRow == 0 { // mode cell
            return isConnected && hexiwearReadings.hexiwearMode == .IDLE ? cellHeight : 0.0
        }
        else if cellRow == 1 { // disconnectedCell
            return isConnected == false ? cellHeight : 0.0
        }
        else if cellRow == 2 { // battery
            return isConnected && batteryIsOn && availableReadings.contains(.BATTERY) ? cellHeight : 0.0
        }
        else if cellRow == 3 { // temperature
            return isConnected && temperatureIsOn && availableReadings.contains(.TEMPERATURE) ? cellHeight : 0.0
        }
        else if cellRow == 4 { // humidity
            return isConnected && humidityIsOn && availableReadings.contains(.HUMIDITY) ? cellHeight : 0.0
        }
        else if cellRow == 5 { // pressure
            return isConnected && pressureIsOn && availableReadings.contains(.PRESSURE) ? cellHeight : 0.0
        }
        else if cellRow == 6 { // light
            return isConnected && lightIsOn && availableReadings.contains(.LIGHT) ? cellHeight : 0.0
        }
        else if cellRow == 7 { // accel
            return isConnected && acceleratorIsOn && availableReadings.contains(.ACCELEROMETER) ? cellHeight : 0.0
        }
        else if cellRow == 8 { // magnet
            return isConnected && magnetometerIsOn && availableReadings.contains(.MAGNETOMETER) ? cellHeight : 0.0
        }
        else if cellRow == 9 { // gyro
            return isConnected && gyroIsOn && availableReadings.contains(.GYRO) ? cellHeight : 0.0
        }
        else if cellRow == 10 { // steps
            return isConnected && stepsIsOn && availableReadings.contains(.PEDOMETER) ? cellHeight : 0.0
        }
        else if cellRow == 11 { // calories
            return isConnected && caloriesIsOn && availableReadings.contains(.CALORIES) ? cellHeight : 0.0
        }
        else { // heartrate
            return isConnected && heartrateIsOn && availableReadings.contains(.HEARTRATE) ? cellHeight : 0.0
        }
    }
}

//MARK:- CBPeripheralDelegate
extension HexiwearTableViewController: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        guard error == Optional.None else {
            print("didDiscoverServices error: \(error)")
            return
        }

        guard let services = peripheral.services else { return }
        
        let progressHUD = JGProgressHUD(style: .Dark)
        progressHUD.textLabel.text = "Exploring services..."
        progressHUD.showInView(self.view, animated: true)

        for service in services {
            let thisService = service as CBService
            if Hexiwear.validService(thisService, isOTAPEnabled: isOTAPEnabled) {
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
        }
        progressHUD.dismiss()
    }
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard error == Optional.None else {
            print("didDiscoverCharacteristicsForService error: \(error)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }

        let progressHUD = JGProgressHUD(style: .Dark)
        progressHUD.textLabel.text = "Discovering characteristics..."
        progressHUD.showInView(self.view, animated: true)
        
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            
            if Hexiwear.validDataCharacteristic(thisCharacteristic, isOTAPEnabled: isOTAPEnabled) {

                if thisCharacteristic.UUID == WeatherTemperatureUUID {
                    weatherTemperatureCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == WeatherHumidityUUID {
                    weatherHumidityCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == WeatherPressureUUID {
                    weatherPressureCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == WeatherLightUUID {
                    weatherLightCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == BatteryLevelUUID {
                    batteryCharacteristics = thisCharacteristic
                    peripheral.readValueForCharacteristic(batteryCharacteristics!)
                    peripheral.setNotifyValue(true, forCharacteristic: batteryCharacteristics!)
                }
                else if thisCharacteristic.UUID == MotionAccelerometerUUID {
                    motionAccelCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == MotionMagnetometerUUID {
                    motionMagnetCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == MotionGyroUUID {
                    motionGyroCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == HealthHeartRateUUID {
                    healthHeartRateCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == HealthStepsUUID {
                    healthStepsCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == HealthCaloriesUUID {
                    healthCaloriesCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.UUID == SerialNumberUUID {
                    serialNumberCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.UUID == DIManufacturerUUID {
                    diManufacturerCharacteristics = thisCharacteristic
                    peripheral.readValueForCharacteristic(diManufacturerCharacteristics!)
                }
                else if thisCharacteristic.UUID == DIHWRevisionUUID {
                    diHWRevisionCharacteristics = thisCharacteristic
                    peripheral.readValueForCharacteristic(diHWRevisionCharacteristics!)
                }
                else if thisCharacteristic.UUID == DIFWRevisionUUID {
                    diFWRevisionCharacteristics = thisCharacteristic
                    peripheral.readValueForCharacteristic(diFWRevisionCharacteristics!)
                }
                else if thisCharacteristic.UUID == HexiwearModeUUID {
                    hexiwearModeCharacteristic = thisCharacteristic
                    peripheral.readValueForCharacteristic(hexiwearModeCharacteristic!)
                }
                else if thisCharacteristic.UUID == AlertINUUID {
                    alertInCharacteristic = thisCharacteristic
                    setTime()
                }
            }
        }
        progressHUD.dismiss()

    }
    
    // Get data values when they are updated
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guard error == Optional.None else {
            print("didUpdateValueForCharacteristic error: \(error)")
            // If authentication is lost, drop readings processing
            if error!.domain == CBATTErrorDomain {
                let authenticationError: Int = CBATTError.InsufficientAuthentication.rawValue
                if error!.code == authenticationError {
                    hexiwearDelegate?.didLoseBonding()
                }
            }
            return
        }

        let lastSensorReadingDate = NSDate()
        
        if characteristic.UUID == WeatherTemperatureUUID {
            hexiwearReadings.ambientTemperature = Hexiwear.getAmbientTemperature(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastTemperature = hexiwearReadings.ambientTemperature
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == WeatherHumidityUUID {
            hexiwearReadings.relativeHumidity = Hexiwear.getRelativeHumidity(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastAirHumidity = hexiwearReadings.relativeHumidity
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == WeatherPressureUUID {
            hexiwearReadings.airPressure = Hexiwear.getPressureData(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastAirPressure = hexiwearReadings.airPressure
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == WeatherLightUUID {
            hexiwearReadings.ambientLight = Hexiwear.getAmbientLight(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastLight = hexiwearReadings.ambientLight
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == BatteryLevelUUID {
            isBatteryRead = true
            hexiwearReadings.batteryLevel = Hexiwear.getBatteryLevel(characteristic.value)
        }
        else if characteristic.UUID == MotionAccelerometerUUID {
            if let accel = Hexiwear.getMotionAccelerometerValues(characteristic.value) {
                hexiwearReadings.motionAccelX = accel.x
                hexiwearReadings.motionAccelY = accel.y
                hexiwearReadings.motionAccelZ = accel.z
                hexiwearReadings.lastAccelDate = lastSensorReadingDate
                trackingDevice.lastAccelerationX = accel.x
                trackingDevice.lastAccelerationY = accel.y
                trackingDevice.lastAccelerationZ = accel.z
                trackingDevice.lastSensorReadingDate = lastSensorReadingDate
                shouldPublishToMQTT = true
            }
        }
        else if characteristic.UUID == MotionMagnetometerUUID {
            if let magnet = Hexiwear.getMotionMagnetometerValues(characteristic.value) {
                hexiwearReadings.motionMagnetX = magnet.x
                hexiwearReadings.motionMagnetY = magnet.y
                hexiwearReadings.motionMagnetZ = magnet.z
                hexiwearReadings.lastMagnetDate = lastSensorReadingDate
                trackingDevice.lastMagnetX = magnet.x
                trackingDevice.lastMagnetY = magnet.y
                trackingDevice.lastMagnetZ = magnet.z
                trackingDevice.lastSensorReadingDate = lastSensorReadingDate
                shouldPublishToMQTT = true
            }
        }
        else if characteristic.UUID == MotionGyroUUID {
            if let gyro = Hexiwear.getMotionGyroValues(characteristic.value) {
                hexiwearReadings.motionGyroX = gyro.x
                hexiwearReadings.motionGyroY = gyro.y
                hexiwearReadings.motionGyroZ = gyro.z
                hexiwearReadings.lastGyroDate = lastSensorReadingDate
                trackingDevice.lastGyroX = gyro.x
                trackingDevice.lastGyroY = gyro.y
                trackingDevice.lastGyroZ = gyro.z
                trackingDevice.lastSensorReadingDate = lastSensorReadingDate
                shouldPublishToMQTT = true
            }
        }
        else if characteristic.UUID == HealthHeartRateUUID {
            hexiwearReadings.heartRate = Hexiwear.getHeartRate(characteristic.value)
            hexiwearReadings.lastHeartRateDate = lastSensorReadingDate
            trackingDevice.lastHeartRate = hexiwearReadings.heartRate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == HealthStepsUUID {
            hexiwearReadings.steps = Hexiwear.getSteps(characteristic.value)
            hexiwearReadings.lastStepsDate = lastSensorReadingDate
            trackingDevice.lastSteps = hexiwearReadings.steps
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.UUID == HealthCaloriesUUID {
            hexiwearReadings.calories = Hexiwear.getCalories(characteristic.value)
            hexiwearReadings.lastCaloriesDate = lastSensorReadingDate
            trackingDevice.lastCalories = hexiwearReadings.calories
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }

        else if characteristic.UUID == DIManufacturerUUID {
            deviceInfo.manufacturer = Hexiwear.getManufacturer(characteristic.value) ?? ""
        }
        else if characteristic.UUID == DIFWRevisionUUID {
            deviceInfo.firmwareRevision = Hexiwear.getFirmwareRevision(characteristic.value) ?? ""
        }
        else if characteristic.UUID == HexiwearModeUUID {
            if let rawMode = Hexiwear.getHexiwearMode(characteristic.value),
                   mode = HexiwearMode(rawValue: rawMode) {
                    hexiwearReadings.hexiwearMode = mode
            }
            else {
                hexiwearReadings.hexiwearMode = .IDLE
            }
            availableReadings = HexiwearMode.getReadingsForMode(hexiwearReadings.hexiwearMode)
            trackingDevice.lastHexiwearMode = hexiwearReadings.hexiwearMode.rawValue
            tableView.reloadData()
        }
        
        
        refreshReadingsLabels(hexiwearReadings)
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if let error = error { print("didWriteValueForCharacteristic error: \(error)") }

        if characteristic.UUID == AlertINUUID {
            let success = error == nil
            timeSettingDelegate?.didFinishSettingTime(success)

            if !success {
                let message = "Insufficient authorisation error occured. Click OK to open Bluetooth settings and choose forget HEXIWEAR and try again."
                guard let topVC = UIApplication.sharedApplication().keyWindow?.rootViewController?.topMostViewController() else { return }
                showOKAndCancelAlertWithTitle(applicationTitle, message: message, viewController: topVC, OKhandler: {_ in
                    UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!);
                })
            }
        }
    }
    
    
    private func refreshReadingsLabels(readings: HexiwearReadings) {
        
        // battery cell
        batteryCell.topText = ""
        batteryCell.middleText = readings.batteryLevelAsString()
        batteryCell.bottomText = ""

        // temperature cell
        temperatureCell.topText = ""
        temperatureCell.middleText = readings.ambientTemperatureAsString()
        temperatureCell.bottomText = ""
        
        // humidity cell
        humidityCell.topText = ""
        humidityCell.middleText = readings.relativeHumidityAsString()
        humidityCell.bottomText = ""
        
        // pressure cell
        pressureCell.topText = ""
        pressureCell.middleText = readings.airPressureAsString()
        pressureCell.bottomText = ""
        
        // Light cell
        lightCell.topText = ""
        lightCell.middleText = readings.ambientLightAsString()
        lightCell.bottomText = ""

        // Acceleration cell
        acceleratorCell.xValue = readings.motionAccelXAsString()
        acceleratorCell.yValue = readings.motionAccelYAsString()
        acceleratorCell.zValue = readings.motionAccelZAsString()

        // Gyro cell
        gyroCell.xValue = readings.motionGyroXAsString()
        gyroCell.yValue = readings.motionGyroYAsString()
        gyroCell.zValue = readings.motionGyroZAsString()
        
        // Magnetometer cell
        magnetometerCell.xValue = readings.motionMagnetXAsString()
        magnetometerCell.yValue = readings.motionMagnetYAsString()
        magnetometerCell.zValue = readings.motionMagnetZAsString()
        
        // Steps cell
        stepsCell.topText = ""
        stepsCell.middleText = readings.stepsAsString()
        stepsCell.bottomText = ""
        
        // Calories cell
        caloriesCell.topText = ""
        caloriesCell.middleText = readings.caloriesAsString()
        caloriesCell.bottomText = ""
        
        // Heart rate cell
        heartRateCell.topText = ""
        heartRateCell.middleText = readings.heartRateAsString()
        heartRateCell.bottomText = ""
    }
    
    func readCharacteristics() {
        
        guard let hexiwearPeripheral = self.hexiwearPeripheral else { return }
        
        if let batteryChar = batteryCharacteristics where !isBatteryRead && batteryIsOn && availableReadings.contains(.BATTERY) {
            hexiwearPeripheral.readValueForCharacteristic(batteryChar)
        }

        if let motionAccel = motionAccelCharacteristics where acceleratorIsOn && availableReadings.contains(.ACCELEROMETER) {
            hexiwearPeripheral.readValueForCharacteristic(motionAccel)
        }
        
        if let motionMagnet = motionMagnetCharacteristics where magnetometerIsOn && availableReadings.contains(.MAGNETOMETER) {
            hexiwearPeripheral.readValueForCharacteristic(motionMagnet)
        }
        
        if let motionGyro = motionGyroCharacteristics where gyroIsOn && availableReadings.contains(.GYRO){
            hexiwearPeripheral.readValueForCharacteristic(motionGyro)
        }
        
        if let weatherLight = weatherLightCharacteristics where lightIsOn && availableReadings.contains(.LIGHT) {
            hexiwearPeripheral.readValueForCharacteristic(weatherLight)
        }
        
        if let weatherTemperature = weatherTemperatureCharacteristics where temperatureIsOn && availableReadings.contains(.TEMPERATURE){
            hexiwearPeripheral.readValueForCharacteristic(weatherTemperature)
        }
        
        if let weatherHumidity = weatherHumidityCharacteristics where humidityIsOn && availableReadings.contains(.HUMIDITY) {
            hexiwearPeripheral.readValueForCharacteristic(weatherHumidity)
        }
        
        if let weatherPressure = weatherPressureCharacteristics where pressureIsOn && availableReadings.contains(.PRESSURE) {
            hexiwearPeripheral.readValueForCharacteristic(weatherPressure)
        }
        
        if let healthHeartRate = healthHeartRateCharacteristics where heartrateIsOn && availableReadings.contains(.HEARTRATE) {
            hexiwearPeripheral.readValueForCharacteristic(healthHeartRate)
        }
        
        if let healthSteps = healthStepsCharacteristics where stepsIsOn && availableReadings.contains(.PEDOMETER) {
            hexiwearPeripheral.readValueForCharacteristic(healthSteps)
        }

        if let healthCalories = healthCaloriesCharacteristics where caloriesIsOn && availableReadings.contains(.CALORIES) {
            hexiwearPeripheral.readValueForCharacteristic(healthCalories)
        }

        if let hexiwearMode = hexiwearModeCharacteristic {
            hexiwearPeripheral.readValueForCharacteristic(hexiwearMode)
        }

        if sendToCloudIsOn && shouldPublishToMQTT { publishToMQTT() }
    }
    
    func publishToMQTT() {
        // Drop any mqtt for demo user
        guard isDemoAccount == false else { return }

        // Transmit to MQTT server if necessary
        let shouldTransmit = sendToCloudIsOn
        let heartbeatElapsed = trackingDevice.isHeartbeatIntervalReached()
        if shouldTransmit && heartbeatElapsed {
            let lastTemperature = trackingDevice.lastTemperature
            let lastPressure = trackingDevice.lastAirPressure
            let lastHumidity = trackingDevice.lastAirHumidity
            let lastAccelX = trackingDevice.lastAccelerationX
            let lastAccelY = trackingDevice.lastAccelerationY
            let lastAccelZ = trackingDevice.lastAccelerationZ
            let lastGyroX = trackingDevice.lastGyroX
            let lastGyroY = trackingDevice.lastGyroY
            let lastGyroZ = trackingDevice.lastGyroZ
            let lastMagnetX = trackingDevice.lastMagnetX
            let lastMagnetY = trackingDevice.lastMagnetY
            let lastMagnetZ = trackingDevice.lastMagnetZ
            let lastSteps = trackingDevice.lastSteps
            let lastCalories = trackingDevice.lastCalories
            let lastHeartRate = trackingDevice.lastHeartRate
            let lastLight = trackingDevice.lastLight
            
            let lastHexiwearMode: HexiwearMode
            if let mode = trackingDevice.lastHexiwearMode {
                lastHexiwearMode = HexiwearMode(rawValue: mode) ?? .IDLE
            }
            else {
                lastHexiwearMode = .IDLE
            }

            let hexiwearReadings = HexiwearReadings(batteryLevel: nil, temperature: lastTemperature, pressure: lastPressure, humidity: lastHumidity, accelX: lastAccelX, accelY: lastAccelY, accelZ: lastAccelZ, gyroX: lastGyroX, gyroY: lastGyroY, gyroZ: lastGyroZ, magnetX: lastMagnetX, magnetY: lastMagnetY, magnetZ: lastMagnetZ, steps: lastSteps, calories: lastCalories, heartRate: lastHeartRate, ambientLight: lastLight, hexiwearMode: lastHexiwearMode)
                        
            mqttAPI.publishHexiwearReadings(hexiwearReadings, forSerial: wolkSerialForHexiserial ?? "")
        }
    }
}

extension HexiwearTableViewController : MQTTAPIProtocol {
    
    func didPublishReadings() {
        dispatch_async(dispatch_get_main_queue()) {
            self.trackingDevice.lastPublished = NSDate()
            self.trackingDevice.lastTemperature = nil
            self.trackingDevice.lastAirPressure = nil
            self.trackingDevice.lastAirHumidity = nil
            self.trackingDevice.lastAccelerationX = nil
            self.trackingDevice.lastAccelerationY = nil
            self.trackingDevice.lastAccelerationZ = nil
            self.trackingDevice.lastGyroX = nil
            self.trackingDevice.lastGyroY = nil
            self.trackingDevice.lastGyroZ = nil
            self.trackingDevice.lastMagnetX = nil
            self.trackingDevice.lastMagnetY = nil
            self.trackingDevice.lastMagnetZ = nil
            self.trackingDevice.lastSteps = nil
            self.trackingDevice.lastCalories = nil
            self.trackingDevice.lastHeartRate = nil
            self.trackingDevice.lastLight = nil            
        }
    }
}

extension HexiwearTableViewController : HexiwearSettingsDelegate {
    func didSignOut() {
        stopTheTimer()
        hexiwearDelegate?.willDisconnectOnSignOut()
    }
    
    func didSetTime() {
        timeSettingDelegate?.didStartSettingTime()
        guard let _ = alertInCharacteristic else { timeSettingDelegate?.didFinishSettingTime(false); return }
        
        setTime()
    }
    
    func setTime() {
        guard let alertIn = alertInCharacteristic, hexiwearPeripheral = self.hexiwearPeripheral else { return }
        let newTimeBinary = Hexiwear.getCurrentTimestampForHexiwear(true)
        let newTimeData = NSData(bytes: newTimeBinary, length: newTimeBinary.count)
        hexiwearPeripheral.writeValue(newTimeData, forCharacteristic: alertIn, type: CBCharacteristicWriteType.WithResponse)
    }
}

extension HexiwearTableViewController : HexiwearReconnection {
    func didReconnectPeripheral(peripheral: CBPeripheral) {
        isConnected = true
        let progressHUD = JGProgressHUD(style: .Dark)
        progressHUD.textLabel.text = "Reconnecting..."
        progressHUD.showInView(self.view, animated: true)
        progressHUD.dismissAfterDelay(1.0, animated: true)
        tableView.reloadData()

        hexiwearPeripheral = peripheral
        shouldDiscoverServices = true
        discoverHexiwearServices()
    }
    
    func didDisconnectPeripheral() {
        isConnected = false
        let progressHUD = JGProgressHUD(style: .Dark)
        progressHUD.textLabel.text = "Hexiwear disconnected!"
        progressHUD.showInView(self.view, animated: true)
        progressHUD.dismissAfterDelay(2.0, animated: true)
        tableView.reloadData()
    }
}

