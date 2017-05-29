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

import org.parceler.Parcel;

@Parcel
public class ManufacturerInfo {
    public String manufacturer;
    public String hardwareRevision;
    public String firmwareRevision;

    @Override
    public String toString() {
        return "ManufacturerInfo{" +
                "manufacturer='" + manufacturer + '\'' +
                ", hardwareRevision='" + hardwareRevision + '\'' +
                ", firmwareRevision='" + firmwareRevision + '\'' +
                '}';
    }
}
