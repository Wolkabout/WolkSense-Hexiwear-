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

package com.wolkabout.hexiwear.model.otap.response;

import com.wolkabout.hexiwear.util.ByteInputStream;

public class ImageTransferComplete {

    private final int imageId;
    private final int status; // 0 = Success

    public ImageTransferComplete(final byte[] bytes) {
        final ByteInputStream inputStream = new ByteInputStream(bytes);
        inputStream.nextBytes(1); // Skip command byte
        imageId = inputStream.nextInt(2);
        status = inputStream.nextInt(1);
    }

    public int getImageId() {
        return imageId;
    }

    public boolean isSuccessful() {
        return status == 0;
    }

    @Override
    public String toString() {
        return "ImageTransferComplete{" +
                "imageId=" + imageId +
                ", status=" + status +
                '}';
    }
}
