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
import com.wolkabout.hexiwear.util.ByteUtils;


public class ImageHeader {

    public static final int SIZE = 58;

    private final byte[] upgradeFileIdentifier;
    private final byte[] headerVersion;
    private final byte[] headerLength;
    private final byte[] headerFieldControl;
    private final byte[] companyIdentifier;
    private final byte[] imageId;
    private final ImageVersion imageVersion;
    private final byte[] headerString;
    private final byte[] totalImageFileSize;

    public ImageHeader(final byte[] bytes) {
        if (bytes.length != SIZE) {
            throw new IllegalArgumentException("Header data must contain exactly " + SIZE + " bytes.");
        }

        final ByteInputStream inputStream = new ByteInputStream(bytes);
        upgradeFileIdentifier = inputStream.nextBytes(4);
        headerVersion = inputStream.nextBytes(2);
        headerLength = inputStream.nextBytes(2);
        headerFieldControl = inputStream.nextBytes(2);
        companyIdentifier = inputStream.nextBytes(2);
        imageId = inputStream.nextBytes(2);
        imageVersion = new ImageVersion(inputStream.nextBytes(8));
        headerString = inputStream.nextBytes(32);
        totalImageFileSize = inputStream.nextBytes(4);
    }

    public byte[] getUpgradeFileIdentifier() {
        return upgradeFileIdentifier;
    }

    public byte[] getHeaderVersion() {
        return headerVersion;
    }

    public byte[] getHeaderLength() {
        return headerLength;
    }

    public byte[] getHeaderFieldControl() {
        return headerFieldControl;
    }

    public byte[] getCompanyIdentifier() {
        return companyIdentifier;
    }

    public byte[] getImageId() {
        return imageId;
    }

    public ImageVersion getImageVersion() {
        return imageVersion;
    }

    public byte[] getHeaderString() {
        return headerString;
    }

    public byte[] getTotalImageFileSize() {
        return totalImageFileSize;
    }

    @Override
    public String toString() {
        return "ImageHeader{" +
                "upgradeFileIdentifier=" + ByteUtils.parseLong(upgradeFileIdentifier) +
                ", headerVersion=" + ByteUtils.parseLong(headerVersion) +
                ", headerLength=" + ByteUtils.parseLong(headerLength) +
                ", headerFieldControl=" + ByteUtils.parseLong(headerFieldControl) +
                ", companyIdentifier=" + ByteUtils.parseLong(companyIdentifier) +
                ", imageId=" + ByteUtils.parseLong(imageId) +
                ", imageVersion=" + imageVersion +
                ", headerString=" + ByteUtils.parseString(headerString) +
                ", totalImageFileSize=" + ByteUtils.parseLong(totalImageFileSize) +
                '}';
    }
}
