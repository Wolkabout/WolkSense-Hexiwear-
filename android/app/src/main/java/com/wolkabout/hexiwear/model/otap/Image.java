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

import com.wolkabout.hexiwear.model.otap.response.ImageBlockRequest;
import com.wolkabout.hexiwear.util.ByteInputStream;
import com.wolkabout.hexiwear.util.ByteUtils;

import java.nio.ByteBuffer;

public class Image {

    private final String fileName;
    private final ImageHeader header;

    byte[] data;

    public Image(final String fileName, final byte[] bytes) {
        this.fileName = fileName;
        final ByteInputStream inputStream = new ByteInputStream(bytes);
        header = new ImageHeader(inputStream.nextBytes(ImageHeader.SIZE));
        data = bytes;
    }

    public byte[] getNewImageInfoResponse() {
        final ByteBuffer buffer = ByteBuffer.allocate(15);
        buffer.put(Command.NEW_IMAGE_INFO_RESPONSE.getCommandByte());
        buffer.put(header.getImageId());
        buffer.put(header.getImageVersion().getRawData());
        buffer.put(header.getTotalImageFileSize());
        return buffer.array();
    }

    public ImageBlock getBlock(final ImageBlockRequest imageBlockRequest) {
        final ByteInputStream inputStream = new ByteInputStream(data, imageBlockRequest.getStartPosition());
        final byte[] blockData = inputStream.nextBytes(imageBlockRequest.getBlockSize());
        return new ImageBlock(blockData, imageBlockRequest);
    }

    public String getFileName() {
        return fileName;
    }

    public String getVersion() {
        return header.getImageVersion().getBuildVersion();
    }

    public long getSize() {
        return ByteUtils.parseLong(header.getTotalImageFileSize());
    }

    public Type getType() {
        return Type.fromBytes(header.getImageId());
    }

    public enum Type {
        KW40, MK64;

        public static Type fromBytes(final byte[] bytes) {
            final int id = (int) ByteUtils.parseLong(bytes);
            switch (id) {
                case 1:
                    return KW40;
                case 2:
                    return MK64;
                default:
                    throw new IllegalArgumentException("No such type: " + id);
            }
        }
    }

}
