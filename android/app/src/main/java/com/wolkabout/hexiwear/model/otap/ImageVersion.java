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

package com.wolkabout.hexiwear.model.otap;

import com.wolkabout.hexiwear.util.ByteInputStream;

public class ImageVersion {

    byte[] rawData;

    private final String buildVersion;
    private final int stackVersion;
    private final String hardwareId;
    private final int endManufacturerId;

    public ImageVersion(final byte[] bytes) {
        rawData = bytes;

        final ByteInputStream inputStream = new ByteInputStream(bytes);
        buildVersion = inputStream.nextNumberArray(3, 1);
        stackVersion = inputStream.nextInt(1);
        hardwareId = inputStream.nextNumberArray(3, 1);
        endManufacturerId = inputStream.nextInt(1);
    }

    public byte[] getRawData() {
        return rawData;
    }

    public String getBuildVersion() {
        return buildVersion;
    }

    public int getStackVersion() {
        return stackVersion;
    }

    public String getHardwareId() {
        return hardwareId;
    }

    public int getEndManufacturerId() {
        return endManufacturerId;
    }

    @Override
    public String toString() {
        return "ImageVersion{" +
                "buildVersion=" + buildVersion +
                ", stackVersion=" + stackVersion +
                ", hardwareId=" + hardwareId +
                ", endManufacturerId=" + endManufacturerId +
                '}';
    }
}
