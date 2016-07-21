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
//  FWUpgradeViewController.swift
//

import UIKit
import CoreBluetooth

protocol OTAPDelegate {
    func didCancelOTAP()
    func didFailedOTAP()
}

class FWUpgradeViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var firmwareLabel: UILabel!
    @IBOutlet weak var panelContainer: UIView!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var fwType: UILabel!
    
    var fwPath: String = ""
    var fwFileName: String = ""
    var fwTypeString: String = ""
    var fwVersion: String = ""
    var hexiwearPeripheral : CBPeripheral!
    var hexiwearDelegate: HexiwearPeripheralDelegate?
    var otapDelegate: OTAPDelegate?


    // OTAP vars
    var isOTAPEnabled         = true // if hexiware is in OTAP mode this will be true
    var hexiwearFW:   [UInt8] = []    // array of bytes of hexiwear firmware
    var hexiwearFWLength: Int = 0
    var otapIsRunning = false


    var otapControlPointCharacteristic: CBCharacteristic?
    var otapDataCharacteristic: CBCharacteristic?
    var otapStateCharacteristic: CBCharacteristic?
    
    var isOtapStateAvailable = false // first read which otap state (i.e. which firmware file to send) and then proceed with otap

    let formatter = NSNumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        hexiwearPeripheral.delegate = self
        hexiwearPeripheral.discoverServices(nil)
        
        // Progress % formatter
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        
        title = "Firmware upgrade"
        
        progressView.progress = 0.0
        filenameLabel.text = ""
        versionLabel.text = ""
        fwType.text = ""
    }
    
    override func viewWillAppear(animated: Bool) {
        filenameLabel.text = "FILE: \(fwFileName)"
        versionLabel.text = "VERSION: \(fwVersion)"
        fwType.text = "TYPE: \(fwTypeString)"
    }
    
    override func viewWillDisappear(animated: Bool) {
        if isMovingFromParentViewController() && otapIsRunning {
            otapDelegate?.didCancelOTAP()
        }
    }
}


//MARK:- CBPeripheralDelegate
extension FWUpgradeViewController: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if let error = error { print("didDiscoverServices error: \(error)") }

        guard let services = peripheral.services else { return }
        
        for service in services {
            let thisService = service as CBService
            if Hexiwear.validService(thisService, isOTAPEnabled: isOTAPEnabled) {
                peripheral.discoverCharacteristics(nil, forService: thisService)
            }
        }
    }
    
    // Enable notification for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let error = error { print("didDiscoverCharacteristicsForService error: \(error)") }

        guard let characteristics = service.characteristics else { return }
        
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            if Hexiwear.validDataCharacteristic(thisCharacteristic, isOTAPEnabled: isOTAPEnabled) {
                if thisCharacteristic.UUID == OTAPControlPointUUID {
                    otapControlPointCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.UUID == OTAPDataUUID {
                    otapDataCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.UUID == OTAPStateUUID {
                    otapStateCharacteristic = thisCharacteristic
                    peripheral.readValueForCharacteristic(otapStateCharacteristic!)
                }
            }
        }
    }
    
    // Get data values when they are updated
    private func setLabelsHidden(hidden: Bool) {
        panelContainer.hidden = hidden
    }
    
    private func setInfo(infoText: String) {
        firmwareLabel.text = infoText
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        // If authentication is lost, drop OTAP
        if let err = error where err.domain == CBATTErrorDomain {
            let authenticationError: Int = CBATTError.InsufficientAuthentication.rawValue
            if err.code == authenticationError {
                hexiwearDelegate?.didLoseBonding()
                return
            }
        }
        
        setLabelsHidden(false)
        
        if characteristic.UUID == OTAPStateUUID {
            isOtapStateAvailable = true
            let otapState = Hexiwear.getOtapState(characteristic.value)
            print("otapState: \(otapState)")
            if let otap = otapControlPointCharacteristic {
                peripheral.setNotifyValue(true, forCharacteristic: otap)
            }
        }
        else if characteristic.UUID == OTAPControlPointUUID {
            otapIsRunning = true
            let rawData = characteristic.value
            print("Control point notified with \(characteristic.value)")
            // Get command
            let otapCommand = getOTAPCommand(rawData)
            
            switch otapCommand {
            case .NewImageInfoRequest:
                
                // Parse received NewImageInfoRequest command
                guard let _ = OTAP_CMD_NewImgInfoReq(data: rawData) else {
                    setInfo("Error initiating firmware upgrade. Wrong image info request received.")
                    return
                }
                print("New image info request parsed!")

                guard let data = NSData(contentsOfFile: fwPath) else {
                    setInfo("Error reading firmware file data. Upgrade aborted.")
                    return
                }
                
                var dataBytes: [UInt8] = [UInt8](count: data.length, repeatedValue: 0x00)
                let length = data.length
                data.getBytes(&dataBytes, length: length)
                hexiwearFW = dataBytes
                hexiwearFWLength = length
                
                // Parse FW file header
                guard let otapImageFileHeader = OTAImageFileHeader(data: data) else {
                    setInfo("Error initiating firmware upgrade. Wrong image info request received.")
                    return
                }
                
                
                // Make NewImageInfoResponse command and send to OTAP Client
                let newImageInfoResponse = OTAP_CMD_NewImgInfoRes(imageId: uint16ToLittleEndianBytesArray(otapImageFileHeader.imageId), imageVersion: otapImageFileHeader.imageVersion, imageFileSize: otapImageFileHeader.totalImageFileSize)
                let newImageResponseBinary = newImageInfoResponse.convertToBinary()
                let newImageResponseData = NSData(bytes: newImageResponseBinary, length: newImageResponseBinary.count)
                print("write image info response binary: \(newImageResponseBinary) data: \(newImageResponseData)")
                peripheral.writeValue(newImageResponseData, forCharacteristic: otapControlPointCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
                print("New image info response sent!")
                
            case .ImageBlockRequest:
                
                // Parse received Image block request command
                guard let imageBlockRequest = OTAP_CMD_ImgBlockReq(data: rawData) else {
                    setInfo("Error upgrading firmware. Wrong image block request received.")
                    return
                }
                
                // Set OTAP transfer parameters
                let startPosition = imageBlockRequest.startPosition
                let blockSize = imageBlockRequest.blockSize
                let chunkSize = imageBlockRequest.chunkSize
                
                self.sendImageChunks(peripheral, startPosition: startPosition, blockSize: blockSize, chunkSize: chunkSize, sequenceNumber: 0, amountOfChunksToSend: 4)
                
            case .ErrorNotification:
                
                otapIsRunning = false
                // Parse received Error notification command
                guard let errorNotification = OTAP_CMD_ErrNotification(data: rawData) else {
                    setInfo("Error upgrading firmware. Error notification received.")
                    return
                }
                
                if let errorStatus = OTAP_Status(rawValue: errorNotification.errStatus) {
                    setInfo("Error upgrading firmware. Error status = \(errorStatus).")
                    print(errorStatus)
                }
                else {
                    setInfo("Error upgrading firmware.")
                    print("Unknown error status")
                }
                otapDelegate?.didFailedOTAP()
                
            case .ImageTransferComplete:
                otapIsRunning = false
                // Parse image transfer complete
                guard let imageTransferComplete = OTAP_CMD_ImgTransferComplete(data: rawData) else {
                    setInfo("Error upgrading firmware. Image transfer failed.")
                    return
                }
                
                if imageTransferComplete.status == OTAP_Status.StatusSuccess {
                    setInfo("Firmware upgrade completed successfully.")
                    print("Image transfer complete with success !")
                }
                else {
                    setInfo("Firmware upgrade failed.")
                    print("Image transfer failed !")
                    print(imageTransferComplete.status)
                }
                
            default:
                print("Command not recognized")
            }
        }
    }
    
    func sendImageChunks(peripheral: CBPeripheral, startPosition: UInt32, blockSize: UInt32, chunkSize: UInt16, sequenceNumber: UInt8, amountOfChunksToSend: UInt8) {
        
        guard otapIsRunning else { return }
        
        var sequenceNumber = sequenceNumber
        
        for i: UInt8 in 0 ..< amountOfChunksToSend {
            sendChunk(peripheral, startPosition:startPosition, blockSize: blockSize, chunkSize: chunkSize, sequenceNumber: sequenceNumber + i)
        }

        // Print progress
        let start = startPosition / UInt32(chunkSize)
        let end = UInt32(hexiwearFWLength) / UInt32(chunkSize) + 1
        let progress = start + UInt32(sequenceNumber) + UInt32(amountOfChunksToSend)
        
        let progressPercentage = Float(progress)/Float(end)
        progressView.progress = progressPercentage
        
        if progress <= end {
            setInfo("Uploaded \(progress) of \(end) chunks (\(formatter.stringFromNumber(Float(100 * progressPercentage))!))%")
        }
        
        if sequenceNumber < 0xFF - amountOfChunksToSend + 1 {
            // Continue with next chunks
            sequenceNumber += amountOfChunksToSend
            
            delay((GAP_PPCP_connectionInterval + GAP_PPCP_packetLeeway) * Double(amountOfChunksToSend)) {
                self.sendImageChunks(peripheral, startPosition: startPosition, blockSize: blockSize, chunkSize: chunkSize, sequenceNumber: sequenceNumber, amountOfChunksToSend: amountOfChunksToSend)
            }
        }
    }
    
    func sendChunk(peripheral: CBPeripheral, startPosition: UInt32, blockSize: UInt32, chunkSize: UInt16, sequenceNumber: UInt8) {
        guard otapIsRunning else { return }

        let currentChunkStart = startPosition + UInt32(UInt16(sequenceNumber) * chunkSize)
        let proposedChunkEnd = currentChunkStart + UInt32(chunkSize) - 1
        let isProposedChunkEndBeyondFileSize = proposedChunkEnd >= UInt32(hexiwearFWLength)
        let currentChunkEnd =  isProposedChunkEndBeyondFileSize ? hexiwearFWLength - 1 : Int(proposedChunkEnd)
        
        guard UInt32(hexiwearFWLength) > currentChunkStart else { return }
        
        let data: [UInt8] = [UInt8](hexiwearFW[Int(currentChunkStart)...Int(currentChunkEnd)])
        let imageChunkCmd = OTAP_CMD_ImgChunkAtt(seqNumber: sequenceNumber, data: data)
        let imageChunkBinary = imageChunkCmd.convertToBinary()
        let imageChunkData = NSData(bytes: imageChunkBinary, length: imageChunkBinary.count)
        
        peripheral.writeValue(imageChunkData, forCharacteristic: otapDataCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
}

