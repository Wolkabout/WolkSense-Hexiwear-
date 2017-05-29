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

public class ImageBlockRequest {

    private final int imageId; // Image ID
    private final int startPosition; // Start position of the image block to be transferred.
    private final int blockSize; // Requested total block size in bytes.
    private final int chunkSize; // Chunk size in bytes. Maximum of 256 chunks per block.
    private final int transferMethod; // 0 = ATT, 1 = L2CAP PSM Credit based channel
    private final int l2capChannelOrPsm; // 4 = ATT, Other values = PSM for credit based channels

    public ImageBlockRequest(final byte[] bytes) {
        final ByteInputStream inputStream = new ByteInputStream(bytes);
        inputStream.nextBytes(1); // Skip command byte
        imageId = inputStream.nextInt(2);
        startPosition = inputStream.nextInt(4);
        blockSize = inputStream.nextInt(4);
        chunkSize = inputStream.nextInt(2);
        transferMethod = inputStream.nextInt(1);
        l2capChannelOrPsm = inputStream.nextInt(2);
    }

    public int getImageId() {
        return imageId;
    }

    public int getStartPosition() {
        return startPosition;
    }

    public int getBlockSize() {
        return blockSize;
    }

    public int getChunkSize() {
        return chunkSize;
    }

    public int getTransferMethod() {
        return transferMethod;
    }

    public int getL2capChannelOrPsm() {
        return l2capChannelOrPsm;
    }

    @Override
    public String toString() {
        return "ImageBlockRequest{" +
                "imageId=" + imageId +
                ", startPosition=" + startPosition +
                ", blockSize=" + blockSize +
                ", chunkSize=" + chunkSize +
                ", transferMethod=" + transferMethod +
                ", l2capChannelOrPsm=" + l2capChannelOrPsm +
                '}';
    }
}
