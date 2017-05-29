/**
 * Hexiwear application is used to pair with Hexiwear BLE devices
 * and send sensor readings to WolkSense sensor data cloud
 * <p>
 * Copyright (C) 2016 WolkAbout Technology s.r.o.
 * <p>
 * Hexiwear is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * <p>
 * Hexiwear is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * <p>
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.wolkabout.hexiwear.model;

import com.wolkabout.wolk.Device;

import java.io.Serializable;


public class HexiwearDevice extends Device implements Serializable {

    private String deviceName;
    private String deviceAddress;
    private String wolkName;

    public HexiwearDevice() {
    }

    public HexiwearDevice(String deviceName, String deviceSerial, String deviceAddress, String devicePassword, String wolkName) {
        this.deviceName = deviceName;
        this.serialId = deviceSerial;
        this.deviceAddress = deviceAddress;
        this.wolkName = wolkName;
        this.password = devicePassword;
    }

    public String getDeviceName() {
        return deviceName;
    }

    public String getDeviceSerial() {
        return serialId;
    }

    public String getDeviceAddress() {
        return deviceAddress;
    }

    public String getWolkName() {
        return wolkName;
    }

    public String getDevicePassword() {
        return password;
    }

    @Override
    public String toString() {
        return "HexiwearDevice{" +
                "deviceName='" + deviceName + '\'' +
                ", deviceSerial='" + serialId + '\'' +
                ", deviceAddress='" + deviceAddress + '\'' +
                ", devicePassword='" + password + '\'' +
                ", wolkName='" + wolkName + '\'' +
                '}';
    }
}
