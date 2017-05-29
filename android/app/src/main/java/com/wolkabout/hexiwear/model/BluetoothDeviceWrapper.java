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

import android.bluetooth.BluetoothDevice;

import com.wolkabout.hexiwear.R;

import org.parceler.Parcel;

@Parcel
public class BluetoothDeviceWrapper {

    BluetoothDevice device;

    int signalStrength;

    boolean isInOtapMode;

    public BluetoothDevice getDevice() {
        return device;
    }

    public void setDevice(BluetoothDevice device) {
        this.device = device;
    }

    public int getSignalStrength() {
        if (signalStrength > -50.0) {
            return R.drawable.ic_signal_strength_5;
        } else if (signalStrength > -60.0) {
            return R.drawable.ic_signal_strength_4;
        } else if (signalStrength > -70.0) {
            return R.drawable.ic_signal_strength_3;
        } else if (signalStrength > -80.0) {
            return R.drawable.ic_signal_strength_2;
        } else {
            return R.drawable.ic_signal_strength_1;
        }
    }

    public void setSignalStrength(int signalStrength) {
        this.signalStrength = signalStrength;
    }

    public boolean isInOtapMode() {
        return isInOtapMode;
    }

    public void setInOtapMode(boolean inOtapMode) {
        isInOtapMode = inOtapMode;
    }

    @Override
    public String toString() {
        return "BluetoothDeviceWrapper{" +
                "device=" + device +
                ", signalStrength=" + signalStrength +
                ", isInOtapMode=" + isInOtapMode +
                '}';
    }
}
