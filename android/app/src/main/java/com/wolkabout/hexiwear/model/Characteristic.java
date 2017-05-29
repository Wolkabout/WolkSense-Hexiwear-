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

import java.util.ArrayList;
import java.util.List;

public enum Characteristic {

    ACCELERATION(Type.READING, "00002001-0000-1000-8000-00805f9b34fb", "g"),
    GYRO(Type.READING, "00002002-0000-1000-8000-00805f9b34fb", "\u00B0/s"),
    MAGNET(Type.READING, "00002003-0000-1000-8000-00805f9b34fb", "\u00B5T"),
    LIGHT(Type.READING, "00002011-0000-1000-8000-00805f9b34fb", "%"),
    TEMPERATURE(Type.READING, "00002012-0000-1000-8000-00805f9b34fb", "\u2103"),
    HUMIDITY(Type.READING, "00002013-0000-1000-8000-00805f9b34fb", "%"),
    PRESSURE(Type.READING, "00002014-0000-1000-8000-00805f9b34fb", "kPa"),
    BATTERY(Type.READING, "00002a19-0000-1000-8000-00805f9b34fb", "%"),
    HEARTRATE(Type.READING, "00002021-0000-1000-8000-00805f9b34fb", "bpm"),
    STEPS(Type.READING, "00002022-0000-1000-8000-00805f9b34fb", ""),
    CALORIES(Type.READING, "00002023-0000-1000-8000-00805f9b34fb", ""),

    ALERT_IN(Type.ALERT, "00002031-0000-1000-8000-00805f9b34fb"),
    ALERT_OUT(Type.ALERT, "00002032-0000-1000-8000-00805f9b34fb"),

    MODE(Type.MODE, "00002041-0000-1000-8000-00805f9b34fb"),

    SERIAL(Type.INFO, "00002a25-0000-1000-8000-00805f9b34fb"),
    FW_REVISION(Type.INFO, "00002a26-0000-1000-8000-00805f9b34fb"),
    HW_REVISION(Type.INFO, "00002a27-0000-1000-8000-00805f9b34fb"),
    MANUFACTURER(Type.INFO, "00002a29-0000-1000-8000-00805f9b34fb"),

    CONTROL_POINT(Type.OTAP, "01ff5551-ba5e-f4ee-5ca1-eb1e5e4b1ce0"),
    DATA(Type.OTAP, "01ff5552-ba5e-f4ee-5ca1-eb1e5e4b1ce0"),
    STATE(Type.OTAP, "01ff5553-ba5e-f4ee-5ca1-eb1e5e4b1ce0");

    private final Type type;
    private final String uuid;
    private final String unit;

    Characteristic(final Type type, final String uuid) {
        this.type = type;
        this.uuid = uuid;
        this.unit = "";
    }

    Characteristic(final Type type, final String uuid, final String unit) {
        this.type = type;
        this.uuid = uuid;
        this.unit = unit;
    }

    public Type getType() {
        return type;
    }

    public String getUuid() {
        return uuid;
    }

    public String getUnit() {
        return unit;
    }

    public static Characteristic byUuid(final String uuid) {
        for (final Characteristic characteristic : values()) {
            if (characteristic.uuid.equals(uuid)) {
                return characteristic;
            }
        }
        return null;
    }

    public static Characteristic byOrdinal(final int ordinal) {
        return values()[ordinal];
    }

    public static List<Characteristic> getReadings() {
        final List<Characteristic> readingCharacteristics = new ArrayList<>();
        for (Characteristic characteristic : values()) {
            if (characteristic.type == Type.READING) {
                readingCharacteristics.add(characteristic);
            }
        }
        return readingCharacteristics;
    }

    public enum Type {
        READING, ALERT, MODE, INFO, OTAP
    }
}
