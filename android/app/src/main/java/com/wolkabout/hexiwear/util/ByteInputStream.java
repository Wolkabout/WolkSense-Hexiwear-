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

package com.wolkabout.hexiwear.util;


public class ByteInputStream {

    private static final String NUMBER_ARRAY_DELIMITER = ".";

    private final byte[] bytes;

    private int position = 0;

    public ByteInputStream(final byte[] bytes) {
        this.bytes = bytes;
    }

    public ByteInputStream(final byte[] bytes, final int offset) {
        this.bytes = bytes;
        position = offset;
    }

    public long nextLong(final int length) {
        final byte[] bytes = nextBytes(length);
        return ByteUtils.parseLong(bytes);
    }

    public int nextInt(final int length) {
        if (length > 4) {
            throw new IllegalArgumentException("Integer value can be changed during conversion.");
        }

        final byte[] bytes = nextBytes(length);
        return (int) ByteUtils.parseLong(bytes);
    }

    public String nextString(final int length) {
        final byte[] bytes = nextBytes(length);
        return ByteUtils.parseString(bytes);
    }

    public String nextNumberArray(final int arrayLength, final int numberLength) {
        final StringBuilder numberArray = new StringBuilder();
        for (int i = 0; i < arrayLength; i++) {
            numberArray.append(nextInt(numberLength));
            if (i != arrayLength - 1) {
                numberArray.append(NUMBER_ARRAY_DELIMITER);
            }
        }
        return numberArray.toString();
    }

    public byte[] nextBytes(final int length) {
        final byte[] subArray = new byte[length];
        System.arraycopy(bytes, position, subArray, 0, length);
        position += length;
        return subArray;
    }

    public byte[] remainingBytes() {
        final byte[] remainingBytes = new byte[bytes.length - position];
        System.arraycopy(bytes, position, remainingBytes, 0, remainingBytes.length);
        return remainingBytes;
    }

}
