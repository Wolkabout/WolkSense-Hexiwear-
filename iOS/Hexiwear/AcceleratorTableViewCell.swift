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
//  AcceleratorTableViewCell.swift
//

import UIKit

class AcceleratorTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var xLabel: UILabel!
    @IBOutlet fileprivate weak var yLabel: UILabel!
    @IBOutlet fileprivate weak var zLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    var xValue: String {
        get {
            return xLabel.text!
        }
        set (newX) {
            xLabel.text = newX
        }
    }
    
    var yValue: String {
        get {
            return yLabel.text!
        }
        set (newY) {
            yLabel.text = newY
        }
    }
    
    var zValue: String {
        get {
            return zLabel.text!
        }
        set (newZ) {
            zLabel.text = newZ
        }
    }
    
}
