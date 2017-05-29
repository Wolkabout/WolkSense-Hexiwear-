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
import java.util.ArrayList;
import java.util.List;

public class ImageBlock {

    private final List<byte[]> chunks = new ArrayList<>();
    private final int numberOfChunks;
    private int position = 0;

    public ImageBlock(final byte[] data, final ImageBlockRequest imageBlockRequest) {
        final int chunkSize = imageBlockRequest.getChunkSize();
        numberOfChunks = (int) Math.ceil((double) imageBlockRequest.getBlockSize() / chunkSize);
        final ByteInputStream inputStream = new ByteInputStream(data);
        for (int i = 0; i < numberOfChunks - 1; i++) {
            chunks.add(inputStream.nextBytes(chunkSize));
        }
        chunks.add(inputStream.remainingBytes());
    }

    public byte[] getNextChunk() {
        final byte[] nextChunk = chunks.get(position);
        final ByteBuffer buffer = ByteBuffer.allocate(nextChunk.length + 2);
        buffer.put(Command.IMAGE_CHUNK.getCommandByte());
        buffer.put(ByteUtils.intToByte(position));
        buffer.put(nextChunk);
        position++;
        return buffer.array();
    }

    public boolean isCompleted() {
        return position == numberOfChunks;
    }

    public int getNumberOfChunks() {
        return numberOfChunks;
    }

    public int getPosition() {
        return position + 1;
    }

}
