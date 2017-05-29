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
    
    let formatter = NumberFormatter()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        filenameLabel.text = "FILE: \(fwFileName)"
        versionLabel.text = "VERSION: \(fwVersion)"
        fwType.text = "TYPE: \(fwTypeString)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParentViewController && otapIsRunning {
            otapDelegate?.didCancelOTAP()
        }
    }
}


//MARK:- CBPeripheralDelegate
extension FWUpgradeViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { print("didDiscoverServices error: \(error)") }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            let thisService = service as CBService
            if Hexiwear.validService(thisService, isOTAPEnabled: isOTAPEnabled) {
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }
    
    // Enable notification for each characteristic of valid service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error { print("didDiscoverCharacteristicsForService error: \(error)") }
        
        guard let characteristics = service.characteristics else { return }
        
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            if Hexiwear.validDataCharacteristic(thisCharacteristic, isOTAPEnabled: isOTAPEnabled) {
                if thisCharacteristic.uuid == OTAPControlPointUUID {
                    otapControlPointCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.uuid == OTAPDataUUID {
                    otapDataCharacteristic = thisCharacteristic
                }
                else if thisCharacteristic.uuid == OTAPStateUUID {
                    otapStateCharacteristic = thisCharacteristic
                    peripheral.readValue(for: otapStateCharacteristic!)
                }
            }
        }
    }
    
    // Get data values when they are updated
    fileprivate func setLabelsHidden(_ hidden: Bool) {
        panelContainer.isHidden = hidden
    }
    
    fileprivate func setInfo(_ infoText: String) {
        firmwareLabel.text = infoText
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // If authentication is lost, drop OTAP
        if let err = error, err._domain == CBATTErrorDomain {
            let authenticationError: Int = CBATTError.Code.insufficientAuthentication.rawValue
            if err._code == authenticationError {
                hexiwearDelegate?.didLoseBonding()
                return
            }
        }
        
        setLabelsHidden(false)
        
        if characteristic.uuid == OTAPStateUUID {
            isOtapStateAvailable = true
            let otapState = Hexiwear.getOtapState(characteristic.value)
            print("otapState: \(otapState)")
            if let otap = otapControlPointCharacteristic {
                peripheral.setNotifyValue(true, for: otap)
            }
        }
        else if characteristic.uuid == OTAPControlPointUUID {
            otapIsRunning = true
            let rawData = characteristic.value
            print("Control point notified with \(String(describing: characteristic.value))")
            // Get command
            let otapCommand = getOTAPCommand(rawData)
            
            switch otapCommand {
            case .newImageInfoRequest:
                
                // Parse received NewImageInfoRequest command
                guard let _ = OTAP_CMD_NewImgInfoReq(data: rawData) else {
                    setInfo("Error initiating firmware upgrade. Wrong image info request received.")
                    return
                }
                print("New image info request parsed!")
                
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: fwPath)) else {
                    setInfo("Error reading firmware file data. Upgrade aborted.")
                    return
                }
                
                var dataBytes: [UInt8] = [UInt8](repeating: 0x00, count: data.count)
                let length = data.count
                (data as NSData).getBytes(&dataBytes, length: length)
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
                let newImageResponseData = Data(bytes: UnsafePointer<UInt8>(newImageResponseBinary), count: newImageResponseBinary.count)
                print("write image info response binary: \(newImageResponseBinary) data: \(newImageResponseData)")
                peripheral.writeValue(newImageResponseData, for: otapControlPointCharacteristic!, type: CBCharacteristicWriteType.withResponse)
                print("New image info response sent!")
                
            case .imageBlockRequest:
                
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
                
            case .errorNotification:
                
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
                
            case .imageTransferComplete:
                otapIsRunning = false
                // Parse image transfer complete
                guard let imageTransferComplete = OTAP_CMD_ImgTransferComplete(data: rawData) else {
                    setInfo("Error upgrading firmware. Image transfer failed.")
                    return
                }
                
                if imageTransferComplete.status == OTAP_Status.statusSuccess {
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
    
    func sendImageChunks(_ peripheral: CBPeripheral, startPosition: UInt32, blockSize: UInt32, chunkSize: UInt16, sequenceNumber: UInt8, amountOfChunksToSend: UInt8) {
        
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
            setInfo("Uploaded \(progress) of \(end) chunks (\(formatter.string(from: NSNumber(value: Float(100 * progressPercentage)))!))%")
        }
        
        if sequenceNumber < 0xFF - amountOfChunksToSend + 1 {
            // Continue with next chunks
            sequenceNumber += amountOfChunksToSend
            
            delay((GAP_PPCP_connectionInterval + GAP_PPCP_packetLeeway) * Double(amountOfChunksToSend)) {
                self.sendImageChunks(peripheral, startPosition: startPosition, blockSize: blockSize, chunkSize: chunkSize, sequenceNumber: sequenceNumber, amountOfChunksToSend: amountOfChunksToSend)
            }
        }
    }
    
    func sendChunk(_ peripheral: CBPeripheral, startPosition: UInt32, blockSize: UInt32, chunkSize: UInt16, sequenceNumber: UInt8) {
        guard otapIsRunning else { return }
        
        let currentChunkStart = startPosition + UInt32(UInt16(sequenceNumber) * chunkSize)
        let proposedChunkEnd = currentChunkStart + UInt32(chunkSize) - 1
        let isProposedChunkEndBeyondFileSize = proposedChunkEnd >= UInt32(hexiwearFWLength)
        let currentChunkEnd =  isProposedChunkEndBeyondFileSize ? hexiwearFWLength - 1 : Int(proposedChunkEnd)
        
        guard UInt32(hexiwearFWLength) > currentChunkStart else { return }
        
        let data: [UInt8] = [UInt8](hexiwearFW[Int(currentChunkStart)...Int(currentChunkEnd)])
        let imageChunkCmd = OTAP_CMD_ImgChunkAtt(seqNumber: sequenceNumber, data: data)
        let imageChunkBinary = imageChunkCmd.convertToBinary()
        let imageChunkData = Data(bytes: UnsafePointer<UInt8>(imageChunkBinary), count: imageChunkBinary.count)
        
        peripheral.writeValue(imageChunkData, for: otapDataCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
}

