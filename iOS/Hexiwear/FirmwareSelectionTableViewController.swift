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
//  FirmwareSelectionTableViewController.swift
//

import UIKit
import CoreBluetooth


struct FirmwareFileItem {
    let fileName: String
    let fileVersion: String
    let factory: Bool
}

class FirmwareSelectionTableViewController: UITableViewController {
    
    var firmwareFilesKW40: [FirmwareFileItem] = []
    var firmwareFilesMK64: [FirmwareFileItem] = []
    var peri: CBPeripheral!
    var selectedFile: String = ""
    var selectedFileName: String = ""
    var selectedType: String = ""
    var selectedFileVersion: String = ""
    var privateDocsDir: String?
    var refreshCont: UIRefreshControl!
    var hexiwearDelegate: HexiwearPeripheralDelegate?
    var otapDelegate: OTAPDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshCont = UIRefreshControl()
        self.refreshCont.addTarget(self, action: #selector(FirmwareSelectionTableViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshCont)
        
        title = "Select firmware file"
    }
    
    func refresh(_ sender:AnyObject) {
        // Code to refresh table view
        getFirmwareFiles()
        tableView.reloadData()
        self.refreshCont.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getFirmwareFiles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParentViewController {
            hexiwearDelegate?.didUnwind()
        }
    }
    
    fileprivate func getFactorySettingsFirmwareFiles() {
        firmwareFilesKW40 = []
        firmwareFilesMK64 = []
        
        guard let pathKW40 = Bundle.main.path(forResource: "HEXIWEAR_KW40_factory_settings", ofType: "img") else { return }
        guard let kw40Data = NSData(contentsOfFile: pathKW40) else { return }
        var kw40dataBytes: [UInt8] = [UInt8](repeating: 0x00, count: kw40Data.length)
        let kw40dataLength = kw40Data.length
        kw40Data.getBytes(&kw40dataBytes, length: kw40dataLength)
        
        // Parse FW file header
        if let otapKW40ImageFileHeader = OTAImageFileHeader(data: kw40Data as Data) {
            selectedFileVersion = "version: \(otapKW40ImageFileHeader.imageVersionAsString())"
            let kw40FW = FirmwareFileItem(fileName: "HEXIWEAR_KW40_factory_settings.img", fileVersion: selectedFileVersion, factory: true)
            firmwareFilesKW40.append(kw40FW)
        }
        
        guard let pathMK64 = Bundle.main.path(forResource: "HEXIWEAR_MK64_factory_settings", ofType: "img") else { return }
        
        guard let mk64Data = NSData(contentsOfFile: pathMK64) else { return }
        var mk64dataBytes: [UInt8] = [UInt8](repeating: 0x00, count: mk64Data.length)
        let mk64dataLength = mk64Data.length
        mk64Data.getBytes(&mk64dataBytes, length: mk64dataLength)
        
        
        // Parse FW file header
        if let otapMK64ImageFileHeader = OTAImageFileHeader(data: mk64Data as Data) {
            selectedFileVersion = "version: \(otapMK64ImageFileHeader.imageVersionAsString())"
            let mk64FW = FirmwareFileItem(fileName: "HEXIWEAR_MK64_factory_settings.img", fileVersion: selectedFileVersion, factory: true)
            firmwareFilesMK64.append(mk64FW)
        }
        
    }
    
    fileprivate func getFirmwareFiles() {
        firmwareFilesKW40 = []
        firmwareFilesMK64 = []
        
        getFactorySettingsFirmwareFiles()
        privateDocsDir = getPrivateDocumentsDirectory()
        let fileManager = FileManager.default
        
        do {
            let fwFilesPaths = try fileManager.contentsOfDirectory(atPath: privateDocsDir!)
            for file in fwFilesPaths {
                let fullFileName = (self.privateDocsDir! as NSString).appendingPathComponent(file)
                
                if let data = try? Data(contentsOf: URL(fileURLWithPath: fullFileName)) {
                    var dataBytes: [UInt8] = [UInt8](repeating: 0x00, count: data.count)
                    let length = data.count
                    (data as NSData).getBytes(&dataBytes, length: length)
                    
                    // Parse FW file header
                    if let otapImageFileHeader = OTAImageFileHeader(data: data) {
                        selectedFileVersion = "version: \(otapImageFileHeader.imageVersionAsString())"
                        let firmwareFile = FirmwareFileItem(fileName: file, fileVersion: selectedFileVersion, factory: false)
                        
                        if otapImageFileHeader.imageId == 1 {
                            firmwareFilesKW40.append(firmwareFile)
                        }
                        else if otapImageFileHeader.imageId == 2 {
                            firmwareFilesMK64.append(firmwareFile)
                        }
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toFWUpgrade" {
            if let vc = segue.destination as? FWUpgradeViewController {
                vc.fwPath = selectedFile
                vc.fwFileName = selectedFileName
                vc.fwTypeString = selectedType
                vc.fwVersion = selectedFileVersion
                vc.hexiwearPeripheral = peri
                vc.hexiwearDelegate = self.hexiwearDelegate
                vc.otapDelegate = self.otapDelegate
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? firmwareFilesKW40.count : firmwareFilesMK64.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "KW40"
        }
        return "MK64"
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor(red: 127.0/255.0, green: 147.0/255.0, blue: 0.0, alpha: 0.6)
            headerView.alpha = 0.95
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "firmwareCell", for: indexPath)
        
        if indexPath.section == 0 {
            let firmwareFile = firmwareFilesKW40[indexPath.row]
            cell.textLabel?.text = firmwareFile.fileName
            cell.detailTextLabel?.text = firmwareFile.fileVersion
        }
        else {
            let firmwareFile = firmwareFilesMK64[indexPath.row]
            cell.textLabel?.text = firmwareFile.fileName
            cell.detailTextLabel?.text = firmwareFile.fileVersion
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If the first item of any section is tapped, that is factory file which is embedded in bundle
        // File path is different than for other FW files
        
        if indexPath.section == 0 && indexPath.row == 0 { // factory KW40
            guard let strPathKW40 = Bundle.main.path(forResource: "HEXIWEAR_KW40_factory_settings", ofType: "img") else { return }
            selectedType = "KW40"
            selectedFileVersion = "1.0.0"
            selectedFileName = "HEXIWEAR_KW40_factory_settings.img"
            selectedFile = strPathKW40
            performSegue(withIdentifier: "toFWUpgrade", sender: nil)
            
            return
        }
        
        if indexPath.section == 1 && indexPath.row == 0 { // factory MK64
            guard let strPathMK64 = Bundle.main.path(forResource: "HEXIWEAR_MK64_factory_settings", ofType: "img") else { return }
            selectedType = "MK64"
            selectedFileVersion = "1.0.0"
            selectedFileName = "HEXIWEAR_MK64_factory_settings.img"
            selectedFile = strPathMK64
            performSegue(withIdentifier: "toFWUpgrade", sender: nil)
            
            return
        }
        
        
        guard let selectedFWFile = getFileForIndexPath(indexPath) else { return }
        selectedFileName = selectedFWFile
        let fullFileName = (self.privateDocsDir! as NSString).appendingPathComponent(selectedFWFile)
        selectedFile = fullFileName
        if let data = try? Data(contentsOf: URL(fileURLWithPath: fullFileName)) {
            var dataBytes: [UInt8] = [UInt8](repeating: 0x00, count: data.count)
            let length = data.count
            (data as NSData).getBytes(&dataBytes, length: length)
            
            // Parse FW file header
            if let otapImageFileHeader = OTAImageFileHeader(data: data) {
                if otapImageFileHeader.imageId == 1 {
                    selectedType = "KW40"
                }
                else if otapImageFileHeader.imageId == 2 {
                    selectedType = "MK64"
                }
                selectedFileVersion = otapImageFileHeader.imageVersionAsString()
            }
        }
        
        performSegue(withIdentifier: "toFWUpgrade", sender: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // let the controller to know that able to edit tableView's row
        return true
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?  {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action , indexPath) -> Void in
            
            let item = indexPath.section == 0 ? self.firmwareFilesKW40[indexPath.row] : self.firmwareFilesMK64[indexPath.row]
            
            let fileManager = FileManager.default
            
            do {
                let fullFileName = (self.privateDocsDir! as NSString).appendingPathComponent(item.fileName)
                try fileManager.removeItem(atPath: fullFileName)
                DispatchQueue.main.async {
                    if indexPath.section == 0 {
                        self.firmwareFilesKW40.remove(at: indexPath.row)
                    }
                    else {
                        self.firmwareFilesMK64.remove(at: indexPath.row)
                    }
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } catch {
                print(error)
            }
        })
        
        deleteAction.backgroundColor = UIColor.red
        
        return [deleteAction]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    fileprivate func getFileForIndexPath(_ indexPath: IndexPath) -> String? {
        if indexPath.section == 0 {
            return indexPath.row >= firmwareFilesKW40.count ? nil : firmwareFilesKW40[indexPath.row].fileName
        }
        
        return indexPath.row >= firmwareFilesMK64.count ? nil : firmwareFilesMK64[indexPath.row].fileName
    }
}
