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

import com.wolkabout.hexiwear.R;

import java.util.ArrayList;
import java.util.List;

public enum Mode {

    IDLE(0, R.string.mode_idle),
    WATCH(1, R.string.mode_watch),
    SENSOR_TAG(2, R.string.mode_sensor_tag),
    WEATHER_STATION(3, R.string.mode_weather_station),
    MOTION_CONTROL(4, R.string.mode_motion_control),
    HEARTRATE(5, R.string.mode_heartrate),
    PEDOMETER(6, R.string.mode_pedometer),
    COMPASS(7, R.string.mode_compass);

    private final int symbol;
    private final int stringResource;

    Mode(final int symbol, final int stringResource) {
        this.symbol = symbol;
        this.stringResource = stringResource;
    }

    public int getStringResource() {
        return stringResource;
    }

    public static Mode bySymbol(final int symbol) {
        for (Mode mode : values()) {
            if (mode.symbol == symbol) {
                return mode;
            }
        }
        throw new IllegalArgumentException("No mode with such symbol: " + symbol);
    }

    public List<Characteristic> getCharacteristics() {
        final List<Characteristic> characteristics = new ArrayList<>();

        switch (this) {
            case SENSOR_TAG:
                characteristics.add(Characteristic.BATTERY);
                characteristics.add(Characteristic.ACCELERATION);
                characteristics.add(Characteristic.MAGNET);
                characteristics.add(Characteristic.GYRO);
                characteristics.add(Characteristic.TEMPERATURE);
                characteristics.add(Characteristic.HUMIDITY);
                characteristics.add(Characteristic.PRESSURE);
                characteristics.add(Characteristic.LIGHT);
                break;
            case PEDOMETER:
                characteristics.add(Characteristic.STEPS);
                characteristics.add(Characteristic.CALORIES);
                break;
            case HEARTRATE:
                characteristics.add(Characteristic.HEARTRATE);
                break;
            default:
                break;
        }

        return characteristics;
    }

    public boolean hasCharacteristic(final String characteristicName) {
        return hasCharacteristic(Characteristic.valueOf(characteristicName));
    }

    public boolean hasCharacteristic(final Characteristic characteristic) {
        final List<Characteristic> characteristics = getCharacteristics();
        return characteristics.contains(characteristic);
    }

}
