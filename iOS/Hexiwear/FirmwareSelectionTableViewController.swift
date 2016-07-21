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
        self.refreshCont.addTarget(self, action: #selector(FirmwareSelectionTableViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshCont)
        
        title = "Select firmware file"
    }
    
    func refresh(sender:AnyObject) {
        // Code to refresh table view
        getFirmwareFiles()
        tableView.reloadData()
        self.refreshCont.endRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        getFirmwareFiles()
    }

    override func viewWillDisappear(animated: Bool) {
        if isMovingFromParentViewController() {
            hexiwearDelegate?.didUnwind()
        }
    }

    private func getFactorySettingsFirmwareFiles() {
        firmwareFilesKW40 = []
        firmwareFilesMK64 = []

        guard let _ = NSBundle.mainBundle().pathForResource("HEXIWEAR_KW40_factory_settings", ofType: "img") else { return }
        let kw40FW = FirmwareFileItem(fileName: "HEXIWEAR_KW40_factory_settings.img", fileVersion: "version: 1.0.0", factory: true)
        firmwareFilesKW40.append(kw40FW)
        
        guard let _ = NSBundle.mainBundle().pathForResource("HEXIWEAR_MK64_factory_settings", ofType: "img") else { return }
        let mk64FW = FirmwareFileItem(fileName: "HEXIWEAR_MK64_factory_settings.img", fileVersion: "version: 1.0.0", factory: true)
        firmwareFilesMK64.append(mk64FW)
    }
    
    private func getFirmwareFiles() {
        firmwareFilesKW40 = []
        firmwareFilesMK64 = []
        
        getFactorySettingsFirmwareFiles()
        privateDocsDir = getPrivateDocumentsDirectory()
        let fileManager = NSFileManager.defaultManager()
        
        do {
            let fwFilesPaths = try fileManager.contentsOfDirectoryAtPath(privateDocsDir!)
            for file in fwFilesPaths {
                let fullFileName = (self.privateDocsDir! as NSString).stringByAppendingPathComponent(file)

                if let data = NSData(contentsOfFile: fullFileName) {
                    var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
                    let length = data.length
                    data.getBytes(&dataBytes, length: length)
                    
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toFWUpgrade" {
            if let vc = segue.destinationViewController as? FWUpgradeViewController {
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? firmwareFilesKW40.count : firmwareFilesMK64.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "KW40"
        }
        return "MK64"
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor(red: 127.0/255.0, green: 147.0/255.0, blue: 0.0, alpha: 0.6)
            headerView.alpha = 0.95
        }
    }
    


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("firmwareCell", forIndexPath: indexPath)
        
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
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // If the first item of any section is tapped, that is factory file which is embedded in bundle
        // File path is different than for other FW files
        
        if indexPath.section == 0 && indexPath.row == 0 { // factory KW40
            guard let strPathKW40 = NSBundle.mainBundle().pathForResource("HEXIWEAR_KW40_factory_settings", ofType: "img") else { return }
            selectedType = "KW40"
            selectedFileVersion = "1.0.0"
            selectedFileName = "HEXIWEAR_KW40_factory_settings.img"
            selectedFile = strPathKW40
            performSegueWithIdentifier("toFWUpgrade", sender: nil)

            return
        }
        
        if indexPath.section == 1 && indexPath.row == 0 { // factory MK64
            guard let strPathMK64 = NSBundle.mainBundle().pathForResource("HEXIWEAR_MK64_factory_settings", ofType: "img") else { return }
            selectedType = "MK64"
            selectedFileVersion = "1.0.0"
            selectedFileName = "HEXIWEAR_MK64_factory_settings.img"
            selectedFile = strPathMK64
            performSegueWithIdentifier("toFWUpgrade", sender: nil)
            
            return
        }
        
        
        guard let selectedFWFile = getFileForIndexPath(indexPath) else { return }
        selectedFileName = selectedFWFile
        let fullFileName = (self.privateDocsDir! as NSString).stringByAppendingPathComponent(selectedFWFile)
        selectedFile = fullFileName
        if let data = NSData(contentsOfFile: fullFileName) {
            var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
            let length = data.length
            data.getBytes(&dataBytes, length: length)
            
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

        performSegueWithIdentifier("toFWUpgrade", sender: nil)
        
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // let the controller to know that able to edit tableView's row
        return true
    }
    
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?  {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete", handler: { (action , indexPath) -> Void in
            
            let item = indexPath.section == 0 ? self.firmwareFilesKW40[indexPath.row] : self.firmwareFilesMK64[indexPath.row]
            
            let fileManager = NSFileManager.defaultManager()
            
            do {
                let fullFileName = (self.privateDocsDir! as NSString).stringByAppendingPathComponent(item.fileName)
                try fileManager.removeItemAtPath(fullFileName)
                dispatch_async(dispatch_get_main_queue()) {
                    if indexPath.section == 0 {
                        self.firmwareFilesKW40.removeAtIndex(indexPath.row)
                    }
                    else {
                        self.firmwareFilesMK64.removeAtIndex(indexPath.row)
                    }
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            } catch {
                print(error)
            }
        })
        
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction]
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    private func getFileForIndexPath(indexPath: NSIndexPath) -> String? {
        if indexPath.section == 0 {
            return indexPath.row >= firmwareFilesKW40.count ? nil : firmwareFilesKW40[indexPath.row].fileName
        }

        return indexPath.row >= firmwareFilesMK64.count ? nil : firmwareFilesMK64[indexPath.row].fileName
    }
}
