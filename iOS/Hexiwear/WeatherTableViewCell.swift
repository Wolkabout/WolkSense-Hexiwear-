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
//  WeatherTableViewCell.swift
//

import UIKit

class WeatherTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var topLabel: UILabel!
    @IBOutlet fileprivate weak var middleLabel: UILabel!
    @IBOutlet fileprivate weak var bottomLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    var topText: String {
        get {
            return topLabel.text!
        }
        set (newText) {
            topLabel.text = newText
        }
    }
    
    var middleText: String {
        get {
            return middleLabel.text!
        }
        set (newText) {
            middleLabel.text = newText
        }
    }
    
    var bottomText: String {
        get {
            return bottomLabel.text!
        }
        set (newText) {
            bottomLabel.text = newText
        }
    }
}
