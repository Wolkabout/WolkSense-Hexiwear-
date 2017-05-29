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

import com.wolkabout.hexiwear.model.otap.ImageVersion;
import com.wolkabout.hexiwear.util.ByteInputStream;

public class NewImageInfoRequest {

    private final long currentImageId; // Should be 0.
    private final ImageVersion currentImageVersion;

    public NewImageInfoRequest(final byte[] bytes) {
        final ByteInputStream inputStream = new ByteInputStream(bytes);
        inputStream.nextBytes(1); // Skip command byte
        currentImageId = inputStream.nextLong(2);
        currentImageVersion = new ImageVersion(inputStream.nextBytes(8));
    }

    public long getCurrentImageId() {
        return currentImageId;
    }

    public ImageVersion getCurrentImageVersion() {
        return currentImageVersion;
    }

    @Override
    public String toString() {
        return "NewImageInfoRequest{" +
                "currentImageId=" + currentImageId +
                ", currentImageVersion=" + currentImageVersion +
                '}';
    }
}
