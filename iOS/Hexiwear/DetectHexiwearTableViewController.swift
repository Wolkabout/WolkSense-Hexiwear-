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
//  DetectHexiwearTableViewController.swift
//

import UIKit
import CoreBluetooth
import JGProgressHUD

struct HexiwearPeripheral {
    let p: CBPeripheral
    let isOTAP: Bool
    let deviceName: String
    let rssi: NSNumber?
}

protocol HexiwearReconnection {
    func didReconnectPeripheral(_ peripheral: CBPeripheral)
    func didDisconnectPeripheral()
}

class DetectHexiwearTableViewController: UITableViewController {
    
    // BLE
    var centralManager : CBCentralManager!
    var hexiwearPeripherals: [HexiwearPeripheral] = []
    var selectedPeripheral: CBPeripheral!
    var isHEXIOTAP: Bool = false
    
    var dataStore: DataStore!
    var userCredentials: UserCredentials!
    var device: TrackingDevice!
    var mqttAPI: MQTTAPI!
    var titleForReadings: String?
    
    var skipButton: UIBarButtonItem!
    var refreshCont: UIRefreshControl!
    
    var disconnectOnSignOut: Bool = false
    var hexiwearReconnection: HexiwearReconnection?
    let progressHUD = JGProgressHUD(style: .dark)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        self.tableView.tableFooterView = UIView()
        
        // Initialize central manager
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        self.refreshCont = UIRefreshControl()
        self.refreshCont.addTarget(self, action: #selector(DetectHexiwearTableViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshCont)
        
        title = "Detect"
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .whiteLarge
        indicator.color = UIColor.black
        indicator.startAnimating()
        tableView.backgroundView = indicator
        
        scanPeripherals()
    }
    
    func refresh(_ sender:AnyObject) {
        scanPeripherals()
        refreshCont.endRefreshing()
    }
    
    fileprivate func scanPeripherals() {
        hexiwearPeripherals = retrieveConnectedHexiwearPeripherals()
        tableView.reloadData()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    fileprivate func getNoPeripheralsLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "No devices found, swipe down to refresh."
        
        return label
    }
    
    fileprivate func retrieveConnectedHexiwearPeripherals() -> [HexiwearPeripheral] {
        return
            centralManager
                .retrieveConnectedPeripherals(withServices: [DIServiceUUID])
                .filter({$0.name == "HEXIWEAR"})
                .map { peri -> HexiwearPeripheral in
                    let deviceName = getDeviceNameForHexiSerial(peri.identifier.uuidString)
                    return HexiwearPeripheral(p: peri, isOTAP: false, deviceName: deviceName, rssi: nil)
        }
    }
    
    fileprivate func getDeviceNameForHexiSerial(_ hexiSerial: String) -> String {
        let serialMappings = getSerialMappings()
        
        guard let wolkSerialForHexiSerial = device.findHexiAndWolkCombination(hexiSerial, hexiAndWolkSerials: serialMappings) else { return "" }
        
        return dataStore.getDeviceNameForSerial(wolkSerialForHexiSerial) ?? ""
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = hexiwearPeripherals.isEmpty ? getNoPeripheralsLabel() : nil
        return hexiwearPeripherals.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hexiwearCellNew", for: indexPath) as! HexiwearTableViewCell
        
        guard indexPath.row < hexiwearPeripherals.count else {
            cell.titleLabel.text = ""
            cell.detailLabel.text = ""
            cell.signalLabel.text = ""
            return cell
        }
        
        // Configure the cell...
        let peri = hexiwearPeripherals[indexPath.row]
        if peri.isOTAP {
            cell.titleLabel?.text = peri.deviceName == "" ? "New HEXIWEAR OTAP" : peri.deviceName + " -- OTAP"
        }
        else {
            cell.titleLabel?.text = peri.deviceName == "" ? "New HEXIWEAR" : peri.deviceName
        }
        
        cell.detailLabel?.text = peri.p.identifier.uuidString
        
        if let rssi = peri.rssi, rssi.doubleValue < 0.0 {
            cell.signalLabel?.text = getSignalLevel(rssi)
        }
        else {
            cell.signalLabel?.text = ""
        }
        
        return cell
    }
    
    func getSignalLevel(_ rssi: NSNumber) -> String {
        
        if rssi.doubleValue > -50.0 {
            return "●●●●"
        }
        else if rssi.doubleValue > -60.0 {
            return "●●●○"
        }
        else if rssi.doubleValue > -70.0 {
            return "●●○○"
        }
        else if rssi.doubleValue > -80.0 {
            return "●○○○"
        }
        else {
            return "○○○○"
        }
    }
    
    func failureHandler(_ failureReason: Reason) {
        delay(0.0) {
            self.progressHUD?.dismiss()
            switch failureReason {
            case .other(let err):
                print("Other error \(err.description)")
            default:
                print("Default error handler")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != hexiwearPeripherals.count else { return }
        
        centralManager.stopScan()
        
        let peri = hexiwearPeripherals[indexPath.row]
        selectedPeripheral = peri.p
        isHEXIOTAP = peri.isOTAP
        titleForReadings = peri.deviceName
        centralManager.connect(selectedPeripheral, options: nil)
        
        progressHUD?.textLabel.text = "Connecting to \(peri.deviceName)"
        progressHUD?.show(in: self.view, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        progressHUD?.dismiss()
        
        if segue.identifier == "toHexiwearDeviceTable" {
            if let vc = segue.destination as? HexiwearTableViewController {
                vc.hexiwearPeripheral = selectedPeripheral
                vc.dataStore = self.dataStore
                if userCredentials.isDemoUser() {
                    vc.title = "DEMO"
                    vc.isDemoAccount = true
                }
                else {
                    vc.isDemoAccount = false
                    let onlineTitle = device.trackingIsOff ? " (cloud OFF)" : " (cloud ON)"
                    if let title = titleForReadings {
                        vc.title = title + onlineTitle
                    }
                    else {
                        vc.title = title
                    }
                }
                
                vc.trackingDevice = self.device
                vc.mqttAPI = self.mqttAPI
                vc.hexiwearDelegate = self
                hexiwearReconnection = vc
                
                let serialMappings = getSerialMappings()
                
                let hexiSerial = selectedPeripheral.identifier.uuidString
                
                let (wolkSerialForHexiSerial, wolkPasswordForHexiSerial) = device.findWolkCredentials(hexiSerial, hexiAndWolkSerials: serialMappings)
                vc.wolkSerialForHexiserial = wolkSerialForHexiSerial
                vc.wolkPasswordForHexiserial = wolkPasswordForHexiSerial
                
                centralManager.stopScan()
            }
        }
        else if segue.identifier == "toOTAP" {
            if let vc = segue.destination as? FirmwareSelectionTableViewController {
                vc.peri = selectedPeripheral
                vc.hexiwearDelegate = self
                vc.otapDelegate = self
                centralManager.stopScan()
            }
        }
        else if segue.identifier == "toActivateDevice" {
            if let vc = segue.destination as? ActivateDeviceViewController {
                vc.dataStore = self.dataStore
                vc.selectedPeripheral = selectedPeripheral
                vc.deviceActivationDelegate = self
            }
        }
        else if segue.identifier == "toSettingsBase" {
            if let nc = segue.destination as? BaseNavigationController,
                let vc = nc.topViewController as? SettingaBaseTableViewController {
                vc.title = "Cloud settings"
                vc.dataStore = self.dataStore
                vc.trackingDevice = self.device
                vc.delegate = self
                vc.isDemoUser = userCredentials.isDemoUser()
            }
        }
    }
    
    fileprivate func showAlertWithText (_ header : String = "Warning", message : String) {
        let alert = UIAlertController(title: header, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}


//MARK:- CBCentralManagerDelegate
extension DetectHexiwearTableViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            scanPeripherals()
        }
        else {
            showAlertWithText("Error", message: "Bluetooth not initialized")
        }
    }
    
    fileprivate func foundHexiwearIndex(_ p: CBPeripheral) -> (Bool, Int) {
        guard hexiwearPeripherals.count > 0 else { return (false, 0) }
        
        for i in 0..<hexiwearPeripherals.count {
            if hexiwearPeripherals[i].p == p {
                return (true, i)
            }
        }
        return (false, 0)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let serialMappings = getSerialMappings()
        
        let hexiSerial = peripheral.identifier.uuidString
        
        var deviceNameForSerial: String?
        if let wolkSerialForHexiSerial = device.findHexiAndWolkCombination(hexiSerial, hexiAndWolkSerials: serialMappings) {
            deviceNameForSerial = dataStore.getDeviceNameForSerial(wolkSerialForHexiSerial)
        }
        
        if Hexiwear.hexiotapFound(advertisementData) {
            appendOrReplacePeripheral(peripheral, isOTAP: true, deviceName: deviceNameForSerial ?? "", rssi: RSSI)
        }
        else if Hexiwear.hexiwearFound(advertisementData) {
            appendOrReplacePeripheral(peripheral, isOTAP: false, deviceName: deviceNameForSerial ?? "", rssi: RSSI)
        }
    }
    
    fileprivate func appendOrReplacePeripheral(_ peripheral: CBPeripheral, isOTAP: Bool, deviceName: String, rssi: NSNumber?) {
        let (found, index) = foundHexiwearIndex(peripheral)
        let newHexiwearPeripheral = HexiwearPeripheral(p: peripheral, isOTAP: isOTAP, deviceName: deviceName, rssi: rssi)
        if !found {
            hexiwearPeripherals.append(newHexiwearPeripheral)
            tableView.reloadData()
        }
        else {
            let offset = tableView.contentOffset.y + tableView.contentInset.top
            guard offset >= 0.0 else { return } // do not reload table while it is refreshing
            hexiwearPeripherals.replaceSubrange(index...index, with: [newHexiwearPeripheral])
            tableView.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        selectedPeripheral = peripheral
        
        // If device is reconnected while on readings screen, just drop any checking
        guard navigationController?.topMostViewController() == self else {
            progressHUD?.dismiss()
            hexiwearReconnection?.didReconnectPeripheral(peripheral)
            return
        }
        
        // if user is logged in with demo account, skip cloud features (activation)
        guard userCredentials.isDemoUser() == false else {
            if self.isHEXIOTAP {
                self.performSegue(withIdentifier: "toOTAP", sender: self)
            }
            else {
                self.performSegue(withIdentifier: "toHexiwearDeviceTable", sender: self)
            }
            return
        }
        
        
        // Check device activation status...
        let serialMappings = getSerialMappings()
        
        let hexiSerial = peripheral.identifier.uuidString
        
        // Activate device if there is no serial for selected hexiwear
        guard let wolkSerialForHexiSerial = device.findHexiAndWolkCombination(hexiSerial, hexiAndWolkSerials: serialMappings) else {
            self.dataStore.fetchAll(self.failureHandler) {
                DispatchQueue.main.async {
                    // ... if it is not activated proceed to activation screen
                    self.performSegue(withIdentifier: "toActivateDevice", sender: self)
                }
            }
            return
        }
        
        // If cloud is OFF
        guard device.trackingIsOff == false else {
            if self.isHEXIOTAP {
                self.performSegue(withIdentifier: "toOTAP", sender: self)
            }
            else {
                self.performSegue(withIdentifier: "toHexiwearDeviceTable", sender: self)
            }
            return
        }
        
        // If cloud is ON
        self.dataStore.getActivationStatusForSerial(wolkSerialForHexiSerial, onFailure: self.failureHandler) { activationStatus in
            DispatchQueue.main.async {
                // ... if it is activated proceed to main screen
                if activationStatus == "ACTIVATED" {
                    DispatchQueue.main.async {
                        if self.isHEXIOTAP {
                            self.performSegue(withIdentifier: "toOTAP", sender: self)
                        }
                        else {
                            self.performSegue(withIdentifier: "toHexiwearDeviceTable", sender: self)
                        }
                    }
                    return
                }
                
                self.dataStore.fetchAll(self.failureHandler) {
                    DispatchQueue.main.async {
                        // ... if it is not activated proceed to activation screen
                        self.performSegue(withIdentifier: "toActivateDevice", sender: self)
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if let error = error { print("didDisconnectPeripheral error: \(error)") }
        
        // If authentication is lost, drop readings processing
        if let err = error, err._domain == CBErrorDomain {
            let connectionFailedError: Int = CBError.Code.connectionFailed.rawValue
            if err._code == connectionFailedError {
                print("connection failed")
            }
        }
        
        guard !disconnectOnSignOut else { return }
        
        if let _ = navigationController?.topMostViewController() as? FWUpgradeViewController {
            showSimpleAlertWithTitle(applicationTitle, message: "Hexiwear disconnected!", viewController: self, OKhandler: { _ in
                self.navigationController?.popToViewController(self, animated: true)
            })
        }
        else if let _ = navigationController?.topMostViewController() as? FirmwareSelectionTableViewController {
            showSimpleAlertWithTitle(applicationTitle, message: "Hexiwear disconnected!", viewController: self, OKhandler: { _ in
                self.navigationController?.popToViewController(self, animated: true)
            })
        }
        else if navigationController?.topMostViewController() != self { // reconnect
            hexiwearReconnection?.didDisconnectPeripheral()
            central.connect(peripheral, options: nil)
        }
        
    }
    
    fileprivate func getSerialMappings() -> [SerialMapping] {
        let hexiAndWolkSerials = device.hexiAndWolkSerials
        
        let serialMappings = device.serialsStringToHexiAndWolkCombination(hexiAndWolkSerials)
        return serialMappings
    }
}


// MARK: - DeviceActivationDelegate
extension DetectHexiwearTableViewController: DeviceActivationDelegate {
    func didActivateDevice(_ pointId: Int, serials: SerialMapping) {
        print("DETECT HEXI -- didActivateDevice with serials: \(serials) and pointId: \(pointId)")
        
        // Get hexi and wolk serial mappings
        let serialMappings = getSerialMappings()
        
        // Filter out mapping new hexi serial (if there is one)
        var serialMappingsFiltered = serialMappings.filter { return $0.hexiSerial != serials.hexiSerial }
        
        // Add new hexi serial mapping
        serialMappingsFiltered.append(serials)
        
        // Save new mappings
        device.hexiAndWolkSerials = device.hexiAndWolkCombinationToString(serialMappingsFiltered)
        
        proceedToMainScreen()
    }
    
    func didSkipActivation() {
        navigationController?.popViewController(animated: true)
        restartScanning()
    }
    
    func proceedToMainScreen() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: false)
            let segueToPerform = self.isHEXIOTAP ? "toOTAP" : "toHexiwearDeviceTable"
            self.performSegue(withIdentifier: segueToPerform, sender: self)
        }
    }
    
    func restartScanning() {
        navigationController?.popToViewController(self, animated: true)
        if selectedPeripheral != nil {
            centralManager.cancelPeripheralConnection(selectedPeripheral)
            selectedPeripheral.delegate = nil
            selectedPeripheral = nil
        }
        mqttAPI.setAuthorisationOptions("", password: "")
        hexiwearPeripherals = []
        tableView.reloadData()
        scanPeripherals()
    }
}

extension DetectHexiwearTableViewController: HexiwearPeripheralDelegate {
    func didUnwind() {
        restartScanning()
    }
    
    func didLoseBonding() {
        let message = "Lost bonding with HEXIWEAR. Click OK to open Bluetooth settings and choose forget HEXIWEAR and try again."
        
        showOKAndCancelAlertWithTitle(applicationTitle, message: message, viewController: self, OKhandler: {_ in
            UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!);
        })
        if selectedPeripheral != nil {
            centralManager.cancelPeripheralConnection(selectedPeripheral)
            selectedPeripheral.delegate = nil
            selectedPeripheral = nil
        }
        mqttAPI.setAuthorisationOptions("", password: "")
        hexiwearPeripherals = []
        tableView.reloadData()
        scanPeripherals()
        self.navigationController?.popToViewController(self, animated: true)
    }
    
    func willDisconnectOnSignOut() {
        if selectedPeripheral != nil {
            disconnectOnSignOut = true
            centralManager.cancelPeripheralConnection(selectedPeripheral)
            selectedPeripheral.delegate = nil
            selectedPeripheral = nil
        }
        mqttAPI.setAuthorisationOptions("", password: "")
        NotificationCenter.default.post(name: Notification.Name(rawValue: HexiwearDidSignOut), object: nil)
        
    }
}

extension DetectHexiwearTableViewController: OTAPDelegate {
    func didCancelOTAP() {
        restartScanning()
    }
    
    func didFailedOTAP() {
        showSimpleAlertWithTitle(applicationTitle, message: "OTAP failed!", viewController: self, OKhandler: { _ in
            self.navigationController?.popToViewController(self, animated: true)
            self.restartScanning()
        })
    }
}

extension DetectHexiwearTableViewController : HexiwearSettingsDelegate {
    func didSignOut() {
        willDisconnectOnSignOut()
    }
    
    func didSetTime() {
        print("n/a")
    }
}
