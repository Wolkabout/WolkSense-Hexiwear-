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
//  BaseNavigationController.swift
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layer = self.navigationBar.layer
        self.navigationBar.barTintColor = wolkaboutBlueColor
        self.navigationBar.tintColor = UIColor.white
        layer.cornerRadius = 3.0
        layer.shadowOffset = CGSize(width: 1.0, height: 2.0)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 3.0
        layer.shadowOpacity = 0.3
        navigationBar.tintColor = UIColor.white
        navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
}
