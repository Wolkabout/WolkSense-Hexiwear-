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
//  Hexiwear.swift
//

import Foundation
import CoreBluetooth

let deviceName         = "HEXIWEAR"
let deviceNameLong     = "HEXIWEAR"
let deviceNameOtap     = "HEXIOTAP"
let deviceNameLongOtap = "HEXIOTAP"

// Service UUIDs
let GAServiceUUID      = CBUUID(string: "1800")  // Generic Access
let DIServiceUUID      = CBUUID(string: "180A")  // Device Information
let BatteryServiceUUID = CBUUID(string: "180F")  // Battery service

// HEXIWEAR Custom Service UUIDs
let MotionServiceUUID       = CBUUID(string: "2000")
let WeatherServiceUUID      = CBUUID(string: "2010")
let HealthServiceUUID       = CBUUID(string: "2020")
let AlertServiceUUID        = CBUUID(string: "2030")
let HexiwearModeServiceUUID = CBUUID(string: "2040")
let OTAPServiceUUID         = CBUUID(string: "01FF5550-BA5E-F4EE-5CA1-EB1E5E4B1CE0")

// Characteristic UUIDs

// General Access
let GADeviceNameUUID   = CBUUID(string: "2A00")  // UTF8 string
let GAAppearanceUUID   = CBUUID(string: "2A01")  // 16bit?
let GAPPConnParamsUUID = CBUUID(string: "2A04")  // uint16[4] - some suitable values

let SerialNumberUUID = CBUUID(string: "2A25")


// Device information
let DIManufacturerUUID = CBUUID(string: "2A29") // UTF8 string
let DIHWRevisionUUID   = CBUUID(string: "2A27") // UTF8 string
let DIFWRevisionUUID   = CBUUID(string: "2A26") // UTF8 string

// Battery level
let BatteryLevelUUID   = CBUUID(string: "2A19")   // uint8 - battery level in %

// Motion
let MotionAccelerometerUUID = CBUUID(string: "2001")  // int16[3] x, y, z in +/- 4g. Multiplied by 100
let MotionMagnetometerUUID  = CBUUID(string: "2003")  // int16[3] x, y, z magnet in uT. Multiplied by 100
let MotionGyroUUID          = CBUUID(string: "2002")  // int16[3] x, y, z +/- 256 deg/sec. Multiplied by 100

// Weather
let WeatherLightUUID       = CBUUID(string: "2011")  // uint8 light level in %
let WeatherTemperatureUUID = CBUUID(string: "2012")  // int16 temperature in Celsius. Multiplied by 100
let WeatherHumidityUUID    = CBUUID(string: "2013")  // uint16 relative humidity in %. Multiplied by 100
let WeatherPressureUUID    = CBUUID(string: "2014")  // uint16 in Pascals. Multiplied by 100

// Health
let HealthHeartRateUUID = CBUUID(string: "2021")  // uint8 beats per minute
let HealthStepsUUID     = CBUUID(string: "2022")  // uint16 number of steps
let HealthCaloriesUUID  = CBUUID(string: "2023")  // uint16 value of kcal

// Alert
let AlertINUUID  = CBUUID(string: "2031")  // uint8[20] Alerts and commands from Phone TO Watch
let AlertOUTUUID = CBUUID(string: "2032")  // uint8[20] Alerts and commands from Watch TO Phone

// Hexiwear mode
let HexiwearModeUUID = CBUUID(string: "2041")  // UInt8


// OTAP
let OTAPControlPointUUID = CBUUID(string: "01FF5551-BA5E-F4EE-5CA1-EB1E5E4B1CE0")
let OTAPDataUUID         = CBUUID(string: "01FF5552-BA5E-F4EE-5CA1-EB1E5E4B1CE0")
let OTAPStateUUID        = CBUUID(string: "01FF5553-BA5E-F4EE-5CA1-EB1E5E4B1CE0") // 0 - no otap, 1 - KW40, 2 - MK64


//MARK:- Watch readings
struct DeviceInfo {
    var manufacturer: String
    var firmwareRevision: String
    
    init() {
        manufacturer = ""
        firmwareRevision = ""
    }
}

public enum HexiwearMode: Int {
    case IDLE = 0              // All sensors off
    case WATCH = 1             // temp and battery
    case SENSOR_TAG = 2        // All sensors on
    case WEATHER_STATION = 3   // Temperature, humidity, pressure data available
    case MOTION_CONTROL = 4    // Accel
    case HEARTRATE = 5         // heart rate data available
    case PEDOMETER = 6         // Pedometer data available
    case COMPASS = 7           // ?
    
    static func getReadingsForMode(mode: HexiwearMode) -> [HexiwearReading] {
        switch mode {
            case .SENSOR_TAG: return [.BATTERY, .ACCELEROMETER, .MAGNETOMETER, .GYRO, .TEMPERATURE, .HUMIDITY, .PRESSURE, .LIGHT]
            case .PEDOMETER: return [.PEDOMETER, .CALORIES]
            case .HEARTRATE: return [.HEARTRATE]
            default: return []
        }
    }
}

public enum HexiwearReading: Int {
    case BATTERY = 0
    case ACCELEROMETER = 1
    case MAGNETOMETER = 2
    case GYRO = 3
    case TEMPERATURE = 4
    case HUMIDITY = 5
    case PRESSURE = 6
    case LIGHT = 7
    case PEDOMETER = 8
    case HEARTRATE = 9
    case CALORIES = 10
}

public enum OtapState: UInt8 {
    case NO_OTAP = 0
    case KW40 = 1
    case MK64 = 2
}

struct HexiwearReadings {
    var batteryLevel: Double?
    var motionAccelX: Double?
    var motionAccelY: Double?
    var motionAccelZ: Double?
    var motionMagnetX: Double?
    var motionMagnetY: Double?
    var motionMagnetZ: Double?
    var motionGyroX: Double?
    var motionGyroY: Double?
    var motionGyroZ: Double?
    var ambientLight: Double?
    var ambientTemperature: Double?
    var relativeHumidity: Double?
    var airPressure: Double?
    var heartRate: Int?
    var steps: Int?
    var calories: Int?
    var lastWeatherDate: NSDate?
    var lastGyroDate: NSDate?
    var lastAccelDate: NSDate?
    var lastMagnetDate: NSDate?
    var lastStepsDate: NSDate?
    var lastCaloriesDate: NSDate?
    var lastHeartRateDate: NSDate?
    var hexiwearMode: HexiwearMode

    private let nf = NSNumberFormatter()
    private let mqttNF = NSNumberFormatter()
    private let mqttValueNF = NSNumberFormatter()
    
    init() {
        nf.numberStyle = .NoStyle
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        nf.minimumIntegerDigits = 1
        
        mqttNF.numberStyle = .NoStyle
        mqttNF.minimumFractionDigits = 0
        mqttNF.maximumFractionDigits = 0
        mqttNF.minimumIntegerDigits = 1
        
        
        mqttValueNF.numberStyle = .NoStyle
        mqttValueNF.minimumFractionDigits = 1
        mqttValueNF.maximumFractionDigits = 1
        mqttValueNF.minimumIntegerDigits = 1
        mqttValueNF.minusSign = ""
        mqttValueNF.decimalSeparator = ""
        
        hexiwearMode = .IDLE
    }
    
    init(batteryLevel: Double?, temperature: Double?, pressure: Double?, humidity: Double?, accelX: Double?, accelY: Double?, accelZ: Double?, gyroX: Double?, gyroY: Double?, gyroZ: Double?, magnetX: Double?, magnetY: Double?, magnetZ: Double?, steps: Int?, calories: Int?, heartRate: Int?, ambientLight: Double?, hexiwearMode: HexiwearMode) {
        self.init()
        self.batteryLevel = batteryLevel
        self.ambientTemperature = temperature
        self.airPressure = pressure
        self.relativeHumidity = humidity
        self.motionAccelX = accelX
        self.motionAccelY = accelY
        self.motionAccelZ = accelZ
        self.motionGyroX = gyroX
        self.motionGyroY = gyroY
        self.motionGyroZ = gyroZ
        self.motionMagnetX = magnetX
        self.motionMagnetY = magnetY
        self.motionMagnetZ = magnetZ
        self.steps = steps
        self.calories = calories
        self.heartRate = heartRate
        self.ambientLight = ambientLight
        self.hexiwearMode = hexiwearMode
    }
    
    func batteryLevelAsString() -> String {
        return stringFromReading(batteryLevel)
    }

    func motionAccelXAsString() -> String {
        return stringFromReading(motionAccelX)
    }

    func motionAccelYAsString() -> String {
        return stringFromReading(motionAccelY)
    }
    
    func motionAccelZAsString() -> String {
        return stringFromReading(motionAccelZ)
    }

    func motionMagnetXAsString() -> String {
        return stringFromReading(motionMagnetX)
    }

    func motionMagnetYAsString() -> String {
        return stringFromReading(motionMagnetY)
    }

    func motionMagnetZAsString() -> String {
        return stringFromReading(motionMagnetZ)
    }

    func motionGyroXAsString() -> String {
        return stringFromReading(motionGyroX)
    }

    func motionGyroYAsString() -> String {
        return stringFromReading(motionGyroY)
    }

    func motionGyroZAsString() -> String {
        return stringFromReading(motionGyroZ)
    }

    func ambientLightAsString() -> String {
        return stringFromReading(ambientLight)
    }

    func ambientTemperatureAsString() -> String {
        return stringFromReading(ambientTemperature)
    }
    
    func relativeHumidityAsString() -> String {
        return stringFromReading(relativeHumidity)
    }
    
    func airPressureAsString() -> String {
        return stringFromReading(airPressure)
    }

    func heartRateAsString() -> String {
        return stringFromReading(heartRate)
    }

    func stepsAsString() -> String {
        return stringFromReading(steps)
    }

    func caloriesAsString() -> String {
        return stringFromReading(calories)
    }

    //MARK:- Readings private helpers
    
    private func stringFromReading(readingValue: Double?) -> String {
        guard let readingValue = readingValue else { return "--" }
        return nf.stringFromNumber(readingValue) ?? "--"
    }

    private func stringFromReading(readingValue: Int?) -> String {
        guard let readingValue = readingValue else { return "--" }
        return mqttNF.stringFromNumber(readingValue) ?? "--"
    }
    
    private func ambientTemperatureAsMQTTString() -> String? {
        guard let temperature = ambientTemperature else { return nil }
        if let temp = mqttNF.stringFromNumber(temperature * 10.0) {
            return "T:\(temp)"
        }
        return nil
    }
    
    private func relativeHumidityAsMQTTString() -> String? {
        guard let humidity = relativeHumidity else { return nil }
        if let temp = mqttNF.stringFromNumber(humidity * 10.0) {
            return "H:\(temp)"
        }
        return nil
    }
    
    private func airPressureAsMQTTString() -> String? {
        guard let pressure = airPressure else { return nil }
        if let temp = mqttNF.stringFromNumber(pressure * 10.0) {
            return "P:\(temp)"
        }
        return nil
    }

    
    private func MQTTValue(doubleValue: Double) -> String? {
        let sign = doubleValue >= 0.0 ? "+" : "-"
        guard let stringValue = mqttValueNF.stringFromNumber(doubleValue) else {
            return nil
        }
        return sign + stringValue
    }
    
    private func ambientLightAsMQTTString() -> String? {
        guard let light = ambientLight else { return nil }
        
        guard let lightValue = MQTTValue(light) else { return nil }

        return "LT:\(lightValue)"
    }
    
    private func accelAsMQTTString() -> String? {
        guard let x = motionAccelX,
                y = motionAccelY,
                z = motionAccelZ else { return nil }
        guard let ax = MQTTValue(x) else { return nil }
        guard let ay = MQTTValue(y) else { return nil }
        guard let az = MQTTValue(z) else { return nil }
        return "ACL:\(ax)\(ay)\(az)"
    }

    private func gyroAsMQTTString() -> String? {
        guard let x = motionGyroX,
            y = motionGyroY,
            z = motionGyroZ else { return nil }
        guard let gx = MQTTValue(x) else { return nil }
        guard let gy = MQTTValue(y) else { return nil }
        guard let gz = MQTTValue(z) else { return nil }
        return "GYR:\(gx)\(gy)\(gz)"
    }

    private func magnetAsMQTTString() -> String? {
        guard let x = motionMagnetX,
            y = motionMagnetY,
            z = motionMagnetZ else { return nil }
        guard let mx = MQTTValue(x) else { return nil }
        guard let my = MQTTValue(y) else { return nil }
        guard let mz = MQTTValue(z) else { return nil }
        return "MAG:\(mx)\(my)\(mz)"
    }
    
    private func stepsAsMQTTString() -> String? {
        guard let s = steps else { return nil }
        
        return "STP:\(s)"
    }

    private func caloriesAsMQTTString() -> String? {
        guard let c = calories else { return nil }
        
        return "KCAL:\(c)"
    }

    private func heartRateAsMQTTString() -> String? {
        guard let h = heartRate else { return nil }
        
        return "BPM:\(h)"
    }

    private func arrayOfReadingsToMQTT(readings: [String]) -> String? {
        guard readings.count > 0 else { return nil }
        let rtcTimestamp = Int64(NSDate().timeIntervalSince1970)
        let readingsMQTT = "RTC \(rtcTimestamp);READINGS "
        
        var readingsMQTTTail = ""
        
        for item in readings {
            readingsMQTTTail += (item + ",")
        }
        
        if readingsMQTTTail.isEmpty {
            return nil
        }
        
        return readingsMQTT + "R:\(rtcTimestamp)," + String(readingsMQTTTail.characters.dropLast()) + ";"
    }
    

    
    func asMQTTMessage() -> String? {
        let mqttPressure = airPressureAsMQTTString()
        let mqttTemperature = ambientTemperatureAsMQTTString()
        let mqttHumidity = relativeHumidityAsMQTTString()
        let mqttLight = ambientLightAsMQTTString()
        let mqttAccel = accelAsMQTTString()
        let mqttGyro = gyroAsMQTTString()
        let mqttMagnet = magnetAsMQTTString()
        let mqttSteps = stepsAsMQTTString()
        let mqttCalories = caloriesAsMQTTString()
        let mqttHeartRate = heartRateAsMQTTString()
        
        let readings = [mqttPressure, mqttTemperature, mqttHumidity, mqttLight, mqttAccel, mqttGyro, mqttMagnet, mqttSteps, mqttCalories, mqttHeartRate]
        let filteredReadings = readings.filter { return $0 != nil }.map { return $0!}
        
        return arrayOfReadingsToMQTT(filteredReadings)
    }

}

class Hexiwear {
    
    
    //MARK:- BLE checks and validations
    // Check name of device from advertisement data
    class func hexiwearFound (advertisementData: [NSObject : AnyObject]!) -> Bool {
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString
        return (nameOfDeviceFound == deviceName || nameOfDeviceFound == deviceNameLong)
    }

    
    // Check name of device from advertisement data
    class func hexiotapFound (advertisementData: [NSObject : AnyObject]!) -> Bool {
        let otapServices = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataServiceUUIDsKey) as? [CBUUID]
    
        if let otapServiceAdvertised = otapServices {
            return otapServiceAdvertised.contains(OTAPServiceUUID)
        }
        return false
    }

    // Check if the service has a valid UUID
    class func validService (service : CBService, isOTAPEnabled: Bool) -> Bool {
        if isOTAPEnabled {
            return service.UUID == OTAPServiceUUID
        }
        
        return service.UUID == BatteryServiceUUID
            || service.UUID == MotionServiceUUID
            || service.UUID == WeatherServiceUUID
            || service.UUID == HealthServiceUUID
            || service.UUID == OTAPServiceUUID
            || service.UUID == DIServiceUUID
            || service.UUID == HexiwearModeServiceUUID
            || service.UUID == AlertServiceUUID
    }
    
    // Check if the characteristic has a valid data UUID
    class func validDataCharacteristic (characteristic : CBCharacteristic, isOTAPEnabled: Bool) -> Bool {
        
        if isOTAPEnabled {
            return characteristic.UUID == OTAPControlPointUUID
                || characteristic.UUID == OTAPDataUUID
                || characteristic.UUID == OTAPStateUUID
        }
        
        return characteristic.UUID == BatteryLevelUUID
            || characteristic.UUID == MotionAccelerometerUUID
            || characteristic.UUID == MotionMagnetometerUUID
            || characteristic.UUID == MotionGyroUUID
            || characteristic.UUID == WeatherLightUUID
            || characteristic.UUID == WeatherTemperatureUUID
            || characteristic.UUID == WeatherHumidityUUID
            || characteristic.UUID == WeatherPressureUUID
            || characteristic.UUID == HealthHeartRateUUID
            || characteristic.UUID == HealthStepsUUID
            || characteristic.UUID == HealthCaloriesUUID
            || characteristic.UUID == OTAPControlPointUUID
            || characteristic.UUID == OTAPDataUUID
            || characteristic.UUID == SerialNumberUUID
            || characteristic.UUID == DIManufacturerUUID
            || characteristic.UUID == DIHWRevisionUUID
            || characteristic.UUID == DIFWRevisionUUID
            || characteristic.UUID == HexiwearModeUUID
            || characteristic.UUID == AlertINUUID
        
    }
    
    //MARK:- Characteristics value parsing

    // Get battery level value
    class func getBatteryLevel(value : NSData?) -> Double? {
        guard let value = value else { return nil }
        
        let dataFromSensor: [UInt8] = dataToIntegerArray(value)
        let batteryLevel = Double(dataFromSensor[0])
        return batteryLevel
    }

    // Get motion accelerometer values
    class func getMotionAccelerometerValues(value : NSData?) -> (x: Double, y: Double, z: Double)? {
        return getXYZValues(value, divideBy: 100.0)
    }

    // Get motion magnetometer values
    class func getMotionMagnetometerValues(value : NSData?) -> (x: Double, y: Double, z: Double)? {
        return getXYZValues(value, divideBy: 100.0)
    }

    // Get motion gyro values
    class func getMotionGyroValues(value : NSData?) -> (x: Double, y: Double, z: Double)? {
        return getXYZValues(value, divideBy: 1.0)
    }

    // Get ambient light value
    class func getAmbientLight(value : NSData?) -> Double? {
        guard let value = value else { return nil }
        
        let dataFromSensor: [UInt8] = dataToIntegerArray(value)
        let ambientLight = Double(dataFromSensor[0])
        return ambientLight
    }
    
    // Get ambient temperature value
    class func getAmbientTemperature(value : NSData?) -> Double? {
        guard let value = value else { return nil }
        
        let dataFromSensor: [Int16] = dataToIntegerArray(value)
        let ambientTemperature = Double(dataFromSensor[0])/100
        return ambientTemperature
    }
    
    // Get relative Humidity
    class func getRelativeHumidity(value: NSData?) -> Double? {
        guard let value = value else { return nil }
        
        let dataFromSensor: [UInt16] = dataToIntegerArray(value)
        let humidity = Double(dataFromSensor[0])/100
        
        return humidity
    }
    
    // Get pressure value
    class func getPressureData(value: NSData?) -> Double? {
        guard let value = value else { return nil }
        let dataFromSensor: [UInt16] = dataToIntegerArray(value)
        let pressure = Double(dataFromSensor[0])/10

        return pressure
    }

    // Get heart rate
    class func getHeartRate(value: NSData?) -> Int? {
        guard let value = value else { return nil }
        let dataFromSensor: [UInt8] = dataToIntegerArray(value)
        let heartRate = Int(dataFromSensor[0])
        return heartRate
    }

    // Get steps
    class func getSteps(value: NSData?) -> Int? {
        guard let value = value else { return nil }
        let dataFromSensor: [UInt16] = dataToIntegerArray(value)
        let steps = Int(dataFromSensor[0])
        return steps
    }

    // Get calories
    class func getCalories(value: NSData?) -> Int? {
        guard let value = value else { return nil }
        let dataFromSensor: [UInt16] = dataToIntegerArray(value)
        let calories = Int(dataFromSensor[0])
        return calories
    }

    // Get hexiwear mode
    class func getHexiwearMode(value: NSData?) -> Int? {
        guard let value = value else { return nil }
        let dataFromSensor: [UInt8] = dataToIntegerArray(value)
        let mode = Int(dataFromSensor[0])
        return mode
    }
    
    // Get otap status
    class func getOtapState(value: NSData?) -> OtapState {
        guard let value = value else { return OtapState.NO_OTAP }
        let dataFromSensor: [UInt8] = dataToIntegerArray(value)
        guard dataFromSensor.count > 0 else { return .NO_OTAP }
        let state = OtapState(rawValue: dataFromSensor[0]) ?? OtapState.NO_OTAP
        return state
    }
    
    // Get Manufacturer
    class func getManufacturer(value: NSData?) -> String? {
        return getStringFromNSData(value)
    }

    // Get Firmware revision
    class func getFirmwareRevision(value: NSData?) -> String? {
        return getStringFromNSData(value)
    }
    
    // Get Current time
    class func getCurrentTimestampForHexiwear(isTimeZoneOffsetIncluded: Bool) -> [UInt8] {
        let timezone = NSTimeZone.localTimeZone()
        let currentTimestamp = NSDate()
        let currentTimestampAsUInt32 = UInt32(currentTimestamp.timeIntervalSince1970)
        
        let timezoneOffsetInSecs = timezone.secondsFromGMT
        
        let timezoneOffset = isTimeZoneOffsetIncluded ? UInt32(abs(timezoneOffsetInSecs)) : UInt32(0)
        
        let correctedTimestampForHexiwear = timezoneOffsetInSecs > 0 ? currentTimestampAsUInt32 + timezoneOffset : currentTimestampAsUInt32 - timezoneOffset
        
        var returnArray: [UInt8] = [3, 4] // 3 - AlertIn command id for setting time, 4 - lenght of value in bytes
        returnArray += uint32ToLittleEndianBytesArray(correctedTimestampForHexiwear)
        while returnArray.count < 20 {
            returnArray.append(0x00) // append remaining bytes (to 20) with zeroes
        }
        return returnArray
    }
    
    private class func getStringFromNSData(value: NSData?) -> String? {
        guard let value = value else { return nil }
        let str = String(data: value, encoding: NSUTF8StringEncoding)
        return str
    }

    //MARK:- Hexiwear private helpers
    private class func getXYZValues(value : NSData?, divideBy: Double) -> (x: Double, y: Double, z: Double)? {
        guard let value = value else { return nil }
        
        let dataFromSensor: [Int16] = dataToIntegerArray(value)
        let valueX = Double(dataFromSensor[0]) / divideBy
        let valueY = Double(dataFromSensor[1]) / divideBy
        let valueZ = Double(dataFromSensor[2]) / divideBy
        return (valueX, valueY, valueZ)
    }
}

//MARK:- OTAP

// BLE OTAP Protocol definitions
let OTAP_CmdIdFieldSize:         UInt16 =   1
let OTAP_ImageIdFieldSize:       UInt16 =   2
let OTAP_ImageVersionFieldSize:  UInt16 =   8
let OTAP_ChunkSeqNumberSize:     UInt16 =   1
let OTAP_MaxChunksPerBlock:      UInt16 = 256
let OTAP_StartPositionSize:      UInt16 =   4
let OTAP_BlockSize:              UInt16 =   4
let OTAP_ChunkSize:              UInt16 =   2
let OTAP_TransferMethodSize:     UInt16 =   1
let OTAP_TransferChannelSize:    UInt16 =   2
let OTAP_ImageFileHeaderLength:  UInt16 =  58
let OTAP_CmdErrorStatusSize:     UInt16 =   1


// ATT_MTU
let OTAP_ImageChunkDataSizeAtt:  UInt16 = 20 - OTAP_CmdIdFieldSize - OTAP_ChunkSeqNumberSize
let OTAP_TransferMethodAtt:      UInt8  = 0x00
let OTAP_TransferChannelAtt:     UInt16 = 0x0004

let GAP_PPCP_connectionInterval: Double = 0.050  // 50.0ms
let GAP_PPCP_packetLeeway:       Double = 0.0025 //  2.5ms per packet

// Protocol
protocol ConvertableToBinary {
    func convertToBinary() -> [UInt8]
}

// OTA Image Header
struct OTAImageFileHeader: ConvertableToBinary {
    let fileIdentifier:      UInt32
    let headerVersion:       UInt16
    let headerLength:        UInt16
    let headerFieldControl:  UInt16
    let companyId:           UInt16
    let imageId:             UInt16  // here will be 1 - KW40, 2 - MK64 as is in 5553 characteristics
    let imageVersion:        [UInt8] // length = OTAP_ImageVersionFieldSize - this info will be visible in DIS Firmware version string upon OTAP upload and restart
    let headerString:        [UInt8] // length = BLE_OTAP_HeaderStrLength
    let totalImageFileSize:  UInt32
    
    init?(data: NSData?) {
        // There should be some data
        guard let data = data else { return nil }

        let length = Int(OTAP_ImageFileHeaderLength) // header size is 58 bytes
        
        var dataBytes: [UInt8] = [UInt8](count: length, repeatedValue: 0x00)
        data.getBytes(&dataBytes, length: length)
        
        fileIdentifier = uint32FromFourBytes(dataBytes[0], lohiByte: dataBytes[1], hiloByte: dataBytes[2], hihiByte: dataBytes[3])
        headerVersion = uint16FromTwoBytes(dataBytes[4], hiByte: dataBytes[5])
        headerLength = uint16FromTwoBytes(dataBytes[6], hiByte: dataBytes[7])
        headerFieldControl = uint16FromTwoBytes(dataBytes[8], hiByte: dataBytes[9])
        companyId = uint16FromTwoBytes(dataBytes[10], hiByte: dataBytes[11])
        imageId = uint16FromTwoBytes(dataBytes[12], hiByte: dataBytes[13])
        imageVersion = Array(dataBytes[14...21])
        headerString = Array(dataBytes[22...53])
        totalImageFileSize = uint32FromFourBytes(dataBytes[54], lohiByte: dataBytes[55], hiloByte: dataBytes[56], hihiByte: dataBytes[57])
        print(self)
    }

    func convertToBinary() -> [UInt8] {
        var bytesArray:[UInt8] = []
        bytesArray.appendContentsOf(uint32ToLittleEndianBytesArray(fileIdentifier))
        bytesArray.appendContentsOf(uint16ToLittleEndianBytesArray(headerVersion))
        bytesArray.appendContentsOf(uint16ToLittleEndianBytesArray(headerLength))
        bytesArray.appendContentsOf(uint16ToLittleEndianBytesArray(headerFieldControl))
        bytesArray.appendContentsOf(uint16ToLittleEndianBytesArray(companyId))
        bytesArray.appendContentsOf(imageVersion)
        bytesArray.appendContentsOf(headerString)
        bytesArray.appendContentsOf(uint32ToLittleEndianBytesArray(totalImageFileSize))
        return bytesArray
    }
    
    func imageVersionAsString() -> String {
        guard imageVersion.count >= 3 else { return "" }
        
        let major = imageVersion[0]
        let minor = imageVersion[1]
        let build = imageVersion[2]
        
        return "\(major).\(minor).\(build)"
    }
}

// BLE OTAP Protocol statuses
enum OTAP_Status: UInt8 {
    case StatusSuccess                      = 0x00 /*!< The operation was successful. */
    case StatusImageDataNotExpected         = 0x01 /*!< The OTAP Server tried to send an image data chunk to the OTAP Client but the Client was not expecting it. */
    case StatusUnexpectedTransferMethod     = 0x02 /*!< The OTAP Server tried to send an image data chunk using a transfer method the OTAP Client does not support/expect. */
    case StatusUnexpectedCmdOnDataChannel   = 0x03 /*!< The OTAP Server tried to send an unexpected command (different from a data chunk) on a data Channel (ATT or CoC) */
    case StatusUnexpectedL2capChannelOrPsm  = 0x04 /*!< The selected channel or PSM is not valid for the selected transfer method (ATT or CoC). */
    case StatusUnexpectedOtapPeer           = 0x05 /*!< A command was received from an unexpected OTAP Server or Client device. */
    case StatusUnexpectedCommand            = 0x06 /*!< The command sent from the OTAP peer device is not expected in the current state. */
    case StatusUnknownCommand               = 0x07 /*!< The command sent from the OTAP peer device is not known. */
    case StatusInvalidCommandLength         = 0x08 /*!< Invalid command length. */
    case StatusInvalidCommandParameter      = 0x09 /*!< A parameter of the command was not valid. */
    case StatusFailedImageIntegrityCheck    = 0x0A /*!< The image integrity check has failed. */
    case StatusUnexpectedSequenceNumber     = 0x0B /*!< A chunk with an unexpected sequence number has been received. */
    case StatusImageSizeTooLarge            = 0x0C /*!< The upgrade image size is too large for the OTAP Client. */
    case StatusUnexpectedDataLength         = 0x0D /*!< The length of a Data Chunk was not expected. */
    case StatusUnknownFileIdentifier        = 0x0E /*!< The image file identifier is not recognized. */
    case StatusUnknownHeaderVersion         = 0x0F /*!< The image file header version is not recognized. */
    case StatusUnexpectedHeaderLength       = 0x10 /*!< The image file header length is not expected for the current header version. */
    case StatusUnexpectedHeaderFieldControl = 0x11 /*!< The image file header field control is not expected for the current header version. */
    case StatusUnknownCompanyId             = 0x12 /*!< The image file header company identifier is not recognized. */
    case StatusUnexpectedImageId            = 0x13 /*!< The image file header image identifier is not as expected. */
    case StatusUnexpectedImageVersion       = 0x14 /*!< The image file header image version is not as expected. */
    case StatusUnexpectedImageFileSize      = 0x15 /*!< The image file header image file size is not as expected. */
    case StatusInvalidSubElementLength      = 0x16 /*!< One of the sub-elements has an invalid length. */
    case StatusImageStorageError            = 0x17 /*!< An image storage error has occurred. */
    case StatusInvalidImageCrc              = 0x18 /*!< The computed CRC does not match the received CRC. */
    case StatusInvalidImageFileSize         = 0x19 /*!< The image file size is not valid. */
    case StatusInvalidL2capPsm              = 0x1A /*!< A block transfer request has been made via the L2CAP CoC method but the specified Psm is not known. */
    case StatusNoL2capPsmConnection         = 0x1B /*!< A block transfer request has been made via the L2CAP CoC method but there is no valid PSM connection. */
    case NumberOfStatuses                   = 0x1C
}

// OTAP Protocol Commands
enum OTAP_Command: UInt8 {
    case NoCommand             = 0x00 /*!< No command. */
    case NewImageNotification  = 0x01 /*!< OTAP Server -> OTAP Client - A new image is available on the OTAP Server */
    case NewImageInfoRequest   = 0x02 /*!< OTAP Client -> OTAP Server - The OTAP Client requests image information from the OTAP Server */
    case NewImageInfoResponse  = 0x03 /*!< OTAP Server -> OTAP Client - The OTAP Server sends requested image information to the OTAP Client */
    case ImageBlockRequest     = 0x04 /*!< OTAP Client -> OTAP Server - The OTAP Client requests an image block from the OTAP Server */
    case ImageChunk            = 0x05 /*!< OTAP Server -> OTAP Client - The OTAP Server sends an image chunk to the OTAP Client */
    case ImageTransferComplete = 0x06 /*!< OTAP Client -> OTAP Server - The OTAP Client notifies the OTAP Server that an image transfer was completed*/
    case ErrorNotification     = 0x07 /*!< Bidirectional - An error has occurred */
    case StopImageTransfer     = 0x08 /*!< OTAP Client -> OTAP Server - The OTAP Client request the OTAP Server to stop an image transfer. */
}


// OTAP New Image Notification Command
struct OTAP_CMD_NewImgNotification: ConvertableToBinary {
    let command: OTAP_Command = OTAP_Command.NewImageNotification
    let imageId: [UInt8]        // length = OTAP_ImageIdFieldSize
    let imageVersion: [UInt8]   // length = OTAP_ImageVersionFieldSize
    let imageFileSize: UInt32
    
    func convertToBinary() -> [UInt8] {
        var bytesArray:[UInt8] = []
        bytesArray.append(command.rawValue)
        bytesArray.appendContentsOf(imageId)
        bytesArray.appendContentsOf(imageVersion)
        bytesArray.appendContentsOf(uint32ToLittleEndianBytesArray(imageFileSize))
        return bytesArray
    }
}

// OTAP New Image Info Request Command
struct OTAP_CMD_NewImgInfoReq {
    let command: OTAP_Command = OTAP_Command.NewImageInfoRequest
    let currentImageId:  [UInt8]      // length = OTAP_ImageIdFieldSize
    let currentImageVersion: [UInt8]  // length = OTAP_ImageVersionFieldSize
    
    init?(data: NSData?) {
        // There should be some data
        guard let data = data else { return nil }
        
        var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
        let length = data.length
        data.getBytes(&dataBytes, length: length)
        
        // Data length should be CmdId + ImageId + ImageVersion = 1 + 2 + 8 = 11bytes
        guard length == Int(OTAP_CmdIdFieldSize + OTAP_ImageIdFieldSize + OTAP_ImageVersionFieldSize) else { return nil }

        currentImageId = Array(dataBytes[1...2])
        currentImageVersion = Array(dataBytes[3...dataBytes.count-1])
        print(self)
    }

}

// OTAP New Image Info Response Command
struct OTAP_CMD_NewImgInfoRes: ConvertableToBinary {
    let command: OTAP_Command = OTAP_Command.NewImageInfoResponse
    let imageId: [UInt8]        // length = OTAP_ImageIdFieldSize
    let imageVersion: [UInt8]   // length = OTAP_ImageVersionFieldSize
    let imageFileSize: UInt32

    init(imageId: [UInt8], imageVersion: [UInt8], imageFileSize: UInt32) {
        self.imageId = imageId
        self.imageVersion = imageVersion
        self.imageFileSize = imageFileSize
        print(self)
    }
    
    func convertToBinary() -> [UInt8] {
        var bytesArray:[UInt8] = []
        bytesArray.append(command.rawValue)
        bytesArray.appendContentsOf(imageId)
        bytesArray.appendContentsOf(imageVersion)
        bytesArray.appendContentsOf(uint32ToLittleEndianBytesArray(imageFileSize))
        return bytesArray
    }
}

// OTAP Image Block Request Command
struct OTAP_CMD_ImgBlockReq {
    let command: OTAP_Command = OTAP_Command.ImageBlockRequest
    let imageId: [UInt8]       // length = OTAP_ImageIdFieldSize
    let startPosition: UInt32
    let blockSize: UInt32
    let chunkSize: UInt16
    let transferMethod: UInt8      //  should be OTAP_TransferMethodAtt = 0x00
    let l2capChannelOrPsm: UInt16  //  should be OTAP_TransferChannelAtt = 0x0004
    
    init?(data: NSData?) {
        // There should be some data
        guard let data = data else { return nil }
        
        var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
        let length = data.length
        data.getBytes(&dataBytes, length: length)
        
        // Data length should be CmdId + ImageId + StartPosition + BlockSize + ChunkSize + TransferMethodSize + TransferChannelSize = 1 + 2 + 4 + 4 + 2 + 1 + 2 = 16bytes
        guard length == Int(OTAP_CmdIdFieldSize + OTAP_ImageIdFieldSize + OTAP_StartPositionSize + OTAP_BlockSize + OTAP_ChunkSize + OTAP_TransferMethodSize + OTAP_TransferChannelSize) else { return nil }
        
        imageId = Array(dataBytes[1...2])
        startPosition = uint32FromFourBytes(dataBytes[3], lohiByte: dataBytes[4], hiloByte: dataBytes[5], hihiByte: dataBytes[6])
        blockSize = uint32FromFourBytes(dataBytes[7], lohiByte: dataBytes[8], hiloByte: dataBytes[9], hihiByte: dataBytes[10])
        chunkSize = uint16FromTwoBytes(dataBytes[11], hiByte: dataBytes[12])
        transferMethod = dataBytes[13]
        l2capChannelOrPsm = uint16FromTwoBytes(dataBytes[14], hiByte: dataBytes[15])
        print(self)
    }
}

// OTAP Image Chunk Command - for ATT transfer method only
struct OTAP_CMD_ImgChunkAtt: ConvertableToBinary {
    let command: OTAP_Command = OTAP_Command.ImageChunk
    let seqNumber: UInt8  //    Max 256 chunks per block. */
    let data: [UInt8]     //    length = OTAP_ImageChunkDataSizeAtt

    init(seqNumber: UInt8, data: [UInt8]) {
        self.seqNumber = seqNumber
        self.data = data
    }

    func convertToBinary() -> [UInt8] {
        var bytesArray:[UInt8] = []
        bytesArray.append(command.rawValue)
        bytesArray.append(seqNumber)
        bytesArray.appendContentsOf(data)
        return bytesArray
    }
}

// OTAP Image Transfer Complete Command
struct OTAP_CMD_ImgTransferComplete {
    let command: OTAP_Command = OTAP_Command.ImageTransferComplete
    let imageId: [UInt8]    // length = OTAP_ImageIdFieldSize
    let status: OTAP_Status // length = OTAP_CmdErrorStatusSize
    
    init?(data: NSData?) {
        // There should be some data
        guard let data = data else { return nil }
        
        var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
        let length = data.length
        data.getBytes(&dataBytes, length: length)
        
        // Data length should be CmdId + ImageId + ErrorStatus = 1 + 2 + 1 = 4bytes
        guard length == Int(OTAP_CmdIdFieldSize + OTAP_ImageIdFieldSize + OTAP_CmdErrorStatusSize) else { return nil }
        
        imageId = Array(dataBytes[1...2])
        if let s = OTAP_Status(rawValue: dataBytes[3]) {
            status = s
        }
        else {
            status = OTAP_Status.NumberOfStatuses
        }
        print(self)
    }
}

// OTAP Error Notification Command
struct OTAP_CMD_ErrNotification: ConvertableToBinary {
    let command: OTAP_Command = OTAP_Command.ErrorNotification
    let cmdId: UInt8             // The command which caused the error
    let errStatus: UInt8         // Actually OTAP_Status code
    
    init?(data: NSData?) {
        // There should be some data
        guard let data = data else { return nil }
        
        var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
        let length = data.length
        data.getBytes(&dataBytes, length: length)
        
        // Data length should be CmdId + CmdId + ErrorStatus = 1 + 1 + 1 = 3bytes
        guard length == Int(OTAP_CmdIdFieldSize + OTAP_CmdIdFieldSize + OTAP_CmdErrorStatusSize) else { return nil }
        
        cmdId = dataBytes[1]
        errStatus = dataBytes[2]
        print(self)
    }

    func convertToBinary() -> [UInt8] {
        var bytesArray:[UInt8] = []
        bytesArray.append(command.rawValue)
        bytesArray.append(cmdId)
        bytesArray.append(errStatus)
        return bytesArray
    }
}

// OTAP Stop Image Transfer Command
struct OTAP_CMD_StopImgTransfer {
    let command: OTAP_Command
    let imageId: [UInt8]   // length = OTAP_ImageIdFieldSize
}

// Extract command id from NSData
func getOTAPCommand(data: NSData?) -> OTAP_Command {
    // There should be some data
    guard let data = data else { return OTAP_Command.NoCommand }
    
    var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
    let length = data.length
    data.getBytes(&dataBytes, length: length)
    
    let cmdId: UInt8 = dataBytes[0]
    return OTAP_Command(rawValue: cmdId) ?? OTAP_Command.NoCommand
}

// Conversion helpers
func uint32ToLittleEndianBytesArray(uint32: UInt32) -> [UInt8] {
    var littleEndian = uint32.littleEndian
    let bytePtr = withUnsafePointer(&littleEndian) {
        UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: sizeofValue(littleEndian))
    }
    let byteArray = Array(bytePtr)
    return byteArray
}

func uint16ToLittleEndianBytesArray(uint16: UInt16) -> [UInt8] {
    var littleEndian = uint16.littleEndian
    let bytePtr = withUnsafePointer(&littleEndian) {
        UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: sizeofValue(littleEndian))
    }
    let byteArray = Array(bytePtr)
    return byteArray
}

func uint16FromTwoBytes(loByte: UInt8, hiByte: UInt8) -> UInt16 {
    let lowByte  = UInt16(loByte & 0xFF)
    let highByte = UInt16(hiByte & 0xFF) << 8
    return highByte | lowByte
}

func int16FromTwoBytes(loByte: UInt8, hiByte: UInt8) -> Int16 {
    let lowByte  = Int16(loByte & 0xFF)
    let highByte = Int16(hiByte & 0xFF) << 8
    return highByte | lowByte
}

func uint32FromFourBytes(loloByte: UInt8, lohiByte: UInt8, hiloByte: UInt8, hihiByte: UInt8) -> UInt32 {
    let lowLowByte   = UInt32(loloByte & 0xFF)
    let lowHighByte  = UInt32(lohiByte & 0xFF) << 8
    let highLowByte  = UInt32(hiloByte & 0xFF) << 16
    let highHighByte = UInt32(hihiByte & 0xFF) << 24
    return highHighByte | highLowByte | lowHighByte | lowLowByte
}

func dataToIntegerArray<T: IntegerType>(value: NSData) -> [T] {
    let dataLength = value.length
    let count = dataLength / sizeof(T)
    var array = [T](count: count, repeatedValue: 0x00)
    value.getBytes(&array, length:dataLength)
    return array
}
