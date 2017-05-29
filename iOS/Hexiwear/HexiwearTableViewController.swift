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
import JGProgressHUD

protocol HexiwearPeripheralDelegate {
    func didUnwind()
    func didLoseBonding()
    func willDisconnectOnSignOut()
}

protocol HexiwearTimeSettingDelegate {
    func didStartSettingTime()
    func didFinishSettingTime(_ success: Bool)
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
    
    var readTimer: Timer!
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
        self.tableView.tableFooterView = UIView()
        
        // Know when MQTT has published data
        mqttAPI.setAuthorisationOptions(wolkSerialForHexiserial ?? "", password: wolkPasswordForHexiserial ?? "")
        mqttAPI.mqttDelegate = self
        
        // Setup polling timer
        readTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(HexiwearTableViewController.readCharacteristics), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        batteryIsOn = !trackingDevice.isBatteryOff
        temperatureIsOn = !trackingDevice.isTemperatureOff
        humidityIsOn = !trackingDevice.isHumidityOff
        pressureIsOn = !trackingDevice.isPressureOff
        lightIsOn = !trackingDevice.isLightOff
        acceleratorIsOn = !trackingDevice.isAcceleratorOff
        magnetometerIsOn = !trackingDevice.isMagnetometerOff
        gyroIsOn = !trackingDevice.isGyroOff
        stepsIsOn = !trackingDevice.isStepsOff
        caloriesIsOn = !trackingDevice.isCaloriesOff
        heartrateIsOn = !trackingDevice.isHeartRateOff
        sendToCloudIsOn = !trackingDevice.trackingIsOff
        
        tableView.reloadData()
        
        // Discover hexiwear services
        discoverHexiwearServices()
    }
    
    fileprivate func discoverHexiwearServices() {
        if shouldDiscoverServices && hexiwearPeripheral != nil {
            hexiwearPeripheral.delegate = self
            hexiwearPeripheral.discoverServices(nil)
            shouldDiscoverServices = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParentViewController {
            stopTheTimer()
            hexiwearDelegate?.didUnwind()
        }
    }
    
    fileprivate func stopTheTimer() {
        readTimer?.invalidate()
        readTimer = nil
    }
    
    @IBAction func goToSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "toSettings", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSettings" {
            if let nc = segue.destination as? BaseNavigationController,
                let vc = nc.topViewController as? HexiSettingsTableViewController {
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellRow = indexPath.row
        let cellHeight: CGFloat = 160.0
        
        if cellRow == 0 { // mode cell
            return isConnected && hexiwearReadings.hexiwearMode == .idle ? cellHeight : 0.0
        }
        else if cellRow == 1 { // disconnectedCell
            return isConnected == false ? cellHeight : 0.0
        }
        else if cellRow == 2 { // battery
            return isConnected && batteryIsOn && availableReadings.contains(.battery) ? cellHeight : 0.0
        }
        else if cellRow == 3 { // temperature
            return isConnected && temperatureIsOn && availableReadings.contains(.temperature) ? cellHeight : 0.0
        }
        else if cellRow == 4 { // humidity
            return isConnected && humidityIsOn && availableReadings.contains(.humidity) ? cellHeight : 0.0
        }
        else if cellRow == 5 { // pressure
            return isConnected && pressureIsOn && availableReadings.contains(.pressure) ? cellHeight : 0.0
        }
        else if cellRow == 6 { // light
            return isConnected && lightIsOn && availableReadings.contains(.light) ? cellHeight : 0.0
        }
        else if cellRow == 7 { // accel
            return isConnected && acceleratorIsOn && availableReadings.contains(.accelerometer) ? cellHeight : 0.0
        }
        else if cellRow == 8 { // magnet
            return isConnected && magnetometerIsOn && availableReadings.contains(.magnetometer) ? cellHeight : 0.0
        }
        else if cellRow == 9 { // gyro
            return isConnected && gyroIsOn && availableReadings.contains(.gyro) ? cellHeight : 0.0
        }
        else if cellRow == 10 { // steps
            return isConnected && stepsIsOn && availableReadings.contains(.pedometer) ? cellHeight : 0.0
        }
        else if cellRow == 11 { // calories
            return isConnected && caloriesIsOn && availableReadings.contains(.calories) ? cellHeight : 0.0
        }
        else { // heartrate
            return isConnected && heartrateIsOn && availableReadings.contains(.heartrate) ? cellHeight : 0.0
        }
    }
}

//MARK:- CBPeripheralDelegate
extension HexiwearTableViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("didDiscoverServices error: \(String(describing: error))")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        let progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = "Exploring services..."
        progressHUD?.show(in: self.view, animated: true)
        
        for service in services {
            let thisService = service as CBService
            if Hexiwear.validService(thisService, isOTAPEnabled: isOTAPEnabled) {
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
        progressHUD?.dismiss()
    }
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("didDiscoverCharacteristicsForService error: \(String(describing: error))")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        let progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = "Discovering characteristics..."
        progressHUD?.show(in: self.view, animated: true)
        
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            
            if Hexiwear.validDataCharacteristic(thisCharacteristic, isOTAPEnabled: isOTAPEnabled) {
                
                if thisCharacteristic.uuid == WeatherTemperatureUUID {
                    weatherTemperatureCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == WeatherHumidityUUID {
                    weatherHumidityCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == WeatherPressureUUID {
                    weatherPressureCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == WeatherLightUUID {
                    weatherLightCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == BatteryLevelUUID {
                    batteryCharacteristics = thisCharacteristic
                    peripheral.readValue(for: batteryCharacteristics!)
                    peripheral.setNotifyValue(true, for: batteryCharacteristics!)
                }
                else if thisCharacteristic.uuid == MotionAccelerometerUUID {
                    motionAccelCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == MotionMagnetometerUUID {
                    motionMagnetCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == MotionGyroUUID {
                    motionGyroCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == HealthHeartRateUUID {
                    healthHeartRateCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == HealthStepsUUID {
                    healthStepsCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == HealthCaloriesUUID {
                    healthCaloriesCharacteristics = thisCharacteristic
                }
                else if thisCharacteristic.uuid == SerialNumberUUID {
                    serialNumberCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.uuid == DIManufacturerUUID {
                    diManufacturerCharacteristics = thisCharacteristic
                    peripheral.readValue(for: diManufacturerCharacteristics!)
                }
                else if thisCharacteristic.uuid == DIHWRevisionUUID {
                    diHWRevisionCharacteristics = thisCharacteristic
                    peripheral.readValue(for: diHWRevisionCharacteristics!)
                }
                else if thisCharacteristic.uuid == DIFWRevisionUUID {
                    diFWRevisionCharacteristics = thisCharacteristic
                    peripheral.readValue(for: diFWRevisionCharacteristics!)
                }
                else if thisCharacteristic.uuid == HexiwearModeUUID {
                    hexiwearModeCharacteristic = thisCharacteristic
                    peripheral.readValue(for: hexiwearModeCharacteristic!)
                }
                else if thisCharacteristic.uuid == AlertINUUID {
                    alertInCharacteristic = thisCharacteristic
                    setTime()
                }
            }
        }
        progressHUD?.dismiss()
        
    }
    
    // Get data values when they are updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            print("didUpdateValueForCharacteristic error: \(String(describing: error))")
            // If authentication is lost, drop readings processing
            if error!._domain == CBATTErrorDomain {
                let authenticationError: Int = CBATTError.Code.insufficientAuthentication.rawValue
                if error!._code == authenticationError {
                    hexiwearDelegate?.didLoseBonding()
                }
            }
            return
        }
        
        let lastSensorReadingDate = Date()
        
        if characteristic.uuid == WeatherTemperatureUUID {
            hexiwearReadings.ambientTemperature = Hexiwear.getAmbientTemperature(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastTemperature = hexiwearReadings.ambientTemperature
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == WeatherHumidityUUID {
            hexiwearReadings.relativeHumidity = Hexiwear.getRelativeHumidity(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastAirHumidity = hexiwearReadings.relativeHumidity
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == WeatherPressureUUID {
            hexiwearReadings.airPressure = Hexiwear.getPressureData(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            trackingDevice.lastAirPressure = hexiwearReadings.airPressure
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == WeatherLightUUID {
            hexiwearReadings.ambientLight = Hexiwear.getAmbientLight(characteristic.value)
            hexiwearReadings.lastWeatherDate = lastSensorReadingDate
            trackingDevice.lastLight = hexiwearReadings.ambientLight
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == BatteryLevelUUID {
            isBatteryRead = true
            hexiwearReadings.batteryLevel = Hexiwear.getBatteryLevel(characteristic.value)
        }
        else if characteristic.uuid == MotionAccelerometerUUID {
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
        else if characteristic.uuid == MotionMagnetometerUUID {
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
        else if characteristic.uuid == MotionGyroUUID {
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
        else if characteristic.uuid == HealthHeartRateUUID {
            hexiwearReadings.heartRate = Hexiwear.getHeartRate(characteristic.value)
            hexiwearReadings.lastHeartRateDate = lastSensorReadingDate
            trackingDevice.lastHeartRate = hexiwearReadings.heartRate
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == HealthStepsUUID {
            hexiwearReadings.steps = Hexiwear.getSteps(characteristic.value)
            hexiwearReadings.lastStepsDate = lastSensorReadingDate
            trackingDevice.lastSteps = hexiwearReadings.steps
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
        else if characteristic.uuid == HealthCaloriesUUID {
            hexiwearReadings.calories = Hexiwear.getCalories(characteristic.value)
            hexiwearReadings.lastCaloriesDate = lastSensorReadingDate
            trackingDevice.lastCalories = hexiwearReadings.calories
            trackingDevice.lastSensorReadingDate = lastSensorReadingDate
            shouldPublishToMQTT = true
        }
            
        else if characteristic.uuid == DIManufacturerUUID {
            deviceInfo.manufacturer = Hexiwear.getManufacturer(characteristic.value) ?? ""
        }
        else if characteristic.uuid == DIFWRevisionUUID {
            deviceInfo.firmwareRevision = Hexiwear.getFirmwareRevision(characteristic.value) ?? ""
        }
        else if characteristic.uuid == HexiwearModeUUID {
            if let rawMode = Hexiwear.getHexiwearMode(characteristic.value),
                let mode = HexiwearMode(rawValue: rawMode) {
                hexiwearReadings.hexiwearMode = mode
            }
            else {
                hexiwearReadings.hexiwearMode = .idle
            }
            availableReadings = HexiwearMode.getReadingsForMode(hexiwearReadings.hexiwearMode)
            trackingDevice.lastHexiwearMode = hexiwearReadings.hexiwearMode.rawValue
            tableView.reloadData()
        }
        
        
        refreshReadingsLabels(hexiwearReadings)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error { print("didWriteValueForCharacteristic error: \(error)") }
        
        if characteristic.uuid == AlertINUUID {
            let success = error == nil
            timeSettingDelegate?.didFinishSettingTime(success)
            
            if !success {
                let message = "Insufficient authorisation error occured. Click OK to open Bluetooth settings and choose forget HEXIWEAR and try again."
                guard let topVC = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() else { return }
                showOKAndCancelAlertWithTitle(applicationTitle, message: message, viewController: topVC, OKhandler: {_ in
                    UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!);
                })
            }
        }
    }
    
    
    fileprivate func refreshReadingsLabels(_ readings: HexiwearReadings) {
        
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
        
        if let batteryChar = batteryCharacteristics, !isBatteryRead && batteryIsOn && availableReadings.contains(.battery) {
            hexiwearPeripheral.readValue(for: batteryChar)
        }
        
        if let motionAccel = motionAccelCharacteristics, acceleratorIsOn && availableReadings.contains(.accelerometer) {
            hexiwearPeripheral.readValue(for: motionAccel)
        }
        
        if let motionMagnet = motionMagnetCharacteristics, magnetometerIsOn && availableReadings.contains(.magnetometer) {
            hexiwearPeripheral.readValue(for: motionMagnet)
        }
        
        if let motionGyro = motionGyroCharacteristics, gyroIsOn && availableReadings.contains(.gyro){
            hexiwearPeripheral.readValue(for: motionGyro)
        }
        
        if let weatherLight = weatherLightCharacteristics, lightIsOn && availableReadings.contains(.light) {
            hexiwearPeripheral.readValue(for: weatherLight)
        }
        
        if let weatherTemperature = weatherTemperatureCharacteristics, temperatureIsOn && availableReadings.contains(.temperature){
            hexiwearPeripheral.readValue(for: weatherTemperature)
        }
        
        if let weatherHumidity = weatherHumidityCharacteristics, humidityIsOn && availableReadings.contains(.humidity) {
            hexiwearPeripheral.readValue(for: weatherHumidity)
        }
        
        if let weatherPressure = weatherPressureCharacteristics, pressureIsOn && availableReadings.contains(.pressure) {
            hexiwearPeripheral.readValue(for: weatherPressure)
        }
        
        if let healthHeartRate = healthHeartRateCharacteristics, heartrateIsOn && availableReadings.contains(.heartrate) {
            hexiwearPeripheral.readValue(for: healthHeartRate)
        }
        
        if let healthSteps = healthStepsCharacteristics, stepsIsOn && availableReadings.contains(.pedometer) {
            hexiwearPeripheral.readValue(for: healthSteps)
        }
        
        if let healthCalories = healthCaloriesCharacteristics, caloriesIsOn && availableReadings.contains(.calories) {
            hexiwearPeripheral.readValue(for: healthCalories)
        }
        
        if let hexiwearMode = hexiwearModeCharacteristic {
            hexiwearPeripheral.readValue(for: hexiwearMode)
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
                lastHexiwearMode = HexiwearMode(rawValue: mode) ?? .idle
            }
            else {
                lastHexiwearMode = .idle
            }
            
            let hexiwearReadings = HexiwearReadings(batteryLevel: nil, temperature: lastTemperature, pressure: lastPressure, humidity: lastHumidity, accelX: lastAccelX, accelY: lastAccelY, accelZ: lastAccelZ, gyroX: lastGyroX, gyroY: lastGyroY, gyroZ: lastGyroZ, magnetX: lastMagnetX, magnetY: lastMagnetY, magnetZ: lastMagnetZ, steps: lastSteps, calories: lastCalories, heartRate: lastHeartRate, ambientLight: lastLight, hexiwearMode: lastHexiwearMode)
            
            mqttAPI.publishHexiwearReadings(hexiwearReadings, forSerial: wolkSerialForHexiserial ?? "")
        }
    }
}

extension HexiwearTableViewController : MQTTAPIProtocol {
    
    func didPublishReadings() {
        DispatchQueue.main.async {
            self.trackingDevice.lastPublished = Date()
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
        guard let alertIn = alertInCharacteristic, let hexiwearPeripheral = self.hexiwearPeripheral else { return }
        let newTimeBinary = Hexiwear.getCurrentTimestampForHexiwear(true)
        let newTimeData = Data(bytes: UnsafePointer<UInt8>(newTimeBinary), count: newTimeBinary.count)
        hexiwearPeripheral.writeValue(newTimeData, for: alertIn, type: CBCharacteristicWriteType.withResponse)
    }
}

extension HexiwearTableViewController : HexiwearReconnection {
    func didReconnectPeripheral(_ peripheral: CBPeripheral) {
        isConnected = true
        let progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = "Reconnecting..."
        progressHUD?.show(in: self.view, animated: true)
        progressHUD?.dismiss(afterDelay: 1.0, animated: true)
        tableView.reloadData()
        
        hexiwearPeripheral = peripheral
        shouldDiscoverServices = true
        discoverHexiwearServices()
    }
    
    func didDisconnectPeripheral() {
        isConnected = false
        let progressHUD = JGProgressHUD(style: .dark)
        progressHUD?.textLabel.text = "Hexiwear disconnected!"
        progressHUD?.show(in: self.view, animated: true)
        progressHUD?.dismiss(afterDelay: 2.0, animated: true)
        tableView.reloadData()
    }
}


