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

public enum Command {

    NEW_IMAGE_NOTIFICATION(1),
    NEW_IMAGE_INFO_REQUEST(2),
    NEW_IMAGE_INFO_RESPONSE(3),
    IMAGE_BLOCK_REQUEST(4),
    IMAGE_CHUNK(5),
    IMAGE_TRANSFER_COMPLETE(6),
    ERROR_NOTIFICATION(7),
    STOP_IMAGE_TRANSFER(8);

    private final byte commandByte;

    Command(final int commandByte) {
        this.commandByte = (byte) commandByte;
    }

    public byte getCommandByte() {
        return commandByte;
    }

    public static Command byCommandByte(final byte commandByte) {
        for (Command command : values()) {
            if (command.getCommandByte() == commandByte) {
                return command;
            }
        }
        throw new IllegalArgumentException("Unknown command: " + commandByte);
    }
}
