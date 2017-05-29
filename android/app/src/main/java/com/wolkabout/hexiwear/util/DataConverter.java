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

import com.wolkabout.hexiwear.model.Characteristic;

import java.util.Locale;

public class DataConverter {

    private static final String INTEGER = "%d";
    private static final String FLOAT = "%.0f";
    private static final String TRIPLE_VALUE = "%+.0f%+.0f%+.0f";

    private DataConverter() {
        // Not meant to be instantiated.
    }

    public static String parseBluetoothData(final Characteristic characteristic, final byte[] data) {
        if (data == null || data.length == 0) return "";

        float floatVal;
        float xfloatVal;
        float yfloatVal;
        float zfloatVal;

        final String unit = characteristic.getUnit();

        switch (characteristic) {
            case HEARTRATE:
            case BATTERY:
            case LIGHT:
            case CALORIES:
            case STEPS:
                floatVal = (data[0] & 0xff);
                return String.format("%.0f %s", floatVal, unit);
            case TEMPERATURE:
            case HUMIDITY:
            case PRESSURE:
                final int intVal = (data[1] << 8) & 0xff00 | (data[0] & 0xff);
                floatVal = (float) intVal / 100;
                return String.format("%.2f %s", floatVal, unit);
            case ACCELERATION:
            case MAGNET:
                final int xintVal = ((int) data[1] << 8) | (data[0] & 0xff);
                xfloatVal = (float) xintVal / 100;

                final int yintVal = ((int) data[3] << 8) | (data[2] & 0xff);
                yfloatVal = (float) yintVal / 100;

                final int zintVal = ((int) data[5] << 8) | (data[4] & 0xff);
                zfloatVal = (float) zintVal / 100;

                return String.format("%.2f %s;%.2f %s;%.2f %s", xfloatVal, unit, yfloatVal, unit, zfloatVal, unit);
            case GYRO:
                final int gyroXintVal = ((int) data[1] << 8) | (data[0] & 0xff);
                xfloatVal = (float) gyroXintVal;

                final int gyroYintVal = ((int) data[3] << 8) | (data[2] & 0xff);
                yfloatVal = (float) gyroYintVal;

                final int gyroZintVal = ((int) data[5] << 8) | (data[4] & 0xff);
                zfloatVal = (float) gyroZintVal;

                return String.format("%.2f %s;%.2f %s;%.2f %s", xfloatVal, unit, yfloatVal, unit, zfloatVal, unit);
            default:
                return "Unknown";
        }
    }

    public static String formatForPublushing(final Characteristic characteristic, final byte[] data) {
        if (data == null || data.length == 0) return "";

        switch (characteristic) {
            case HEARTRATE:
            case LIGHT:
            case BATTERY:
            case CALORIES:
                final int heartRate = (data[0] & 0xff);
                return format(INTEGER, heartRate);
            case STEPS:
            case TEMPERATURE:
            case HUMIDITY:
                final int intVal = (data[1] << 8) & 0xff00 | (data[0] & 0xff);
                final float floatVal = (float) intVal / 10;
                return format(FLOAT, floatVal);
            case PRESSURE:
                final int pressureVal = (data[1] << 8) & 0xff00 | (data[0] & 0xff);
                return format(INTEGER, pressureVal);
            case ACCELERATION:
            case MAGNET:
                final int xintVal = ((int) data[1] << 8) | (data[0] & 0xff);
                final float xfloatVal = (float) xintVal / 10;

                final int yintVal = ((int) data[3] << 8) | (data[2] & 0xff);
                final float yfloatVal = (float) yintVal / 10;

                final int zintVal = ((int) data[5] << 8) | (data[4] & 0xff);
                final float zfloatVal = (float) zintVal / 10;
                return format(TRIPLE_VALUE, xfloatVal, yfloatVal, zfloatVal);
            case GYRO:
                final int gyroXintVal = ((int) data[1] << 8) | (data[0] & 0xff);
                final float gyroXfloatVal = (float) gyroXintVal * 10;

                final int gyroYintVal = ((int) data[3] << 8) | (data[2] & 0xff);
                final float gyroYfloatVal = (float) gyroYintVal * 10;

                final int gyroZintVal = ((int) data[5] << 8) | (data[4] & 0xff);

                final float gyroZfloatVal = (float) gyroZintVal * 10;
                return format(TRIPLE_VALUE, gyroXfloatVal, gyroYfloatVal, gyroZfloatVal);
            default:
                return "Unknown";
        }
    }

    private static String format(final String type, final Object... values) {
        return String.format(Locale.ENGLISH, type, values);
    }

}
