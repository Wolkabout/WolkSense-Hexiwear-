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

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.SharedPreferences;

import com.wolkabout.hexiwear.model.Characteristic;
import com.wolkabout.hexiwear.model.HexiwearDevice;
import com.wolkabout.wolkrestandroid.Credentials_;
import com.wolkabout.wolkrestandroid.dto.PointWithFeedsResponse;

import org.androidannotations.annotations.AfterInject;
import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.sharedpreferences.Pref;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@EBean(scope = EBean.Scope.Singleton)
public class HexiwearDevices {

    private static final String NAME_SUFFIX = "_deviceName";
    private static final String SERIAL_SUFFIX = "_deviceSerial";
    private static final String PASSWORD_SUFFIX = "_devicePassword";
    private static final String WOLK_NAME_SUFFIX = "_wolkName";
    private static final String SHOULD_TRANSMIT_SUFFIX = "_shouldTransmit";
    private static final String PUBLISH_INTERVAL_SUFFIX = "_publishInterval";
    private static final String KEEP_ALIVE_SUFFIX = "_keepAlive";

    private SharedPreferences preferences;
    private String account;

    @Pref
    Credentials_ credentials;

    @RootContext
    Context context;

    @AfterInject
    public void init() {
        account = credentials.username().get();
        preferences = context.getSharedPreferences("HEX_" + account, Context.MODE_PRIVATE);
    }

    public Set<HexiwearDevice> getDevices() {
        final Set<HexiwearDevice> devices = new HashSet<>();
        final Set<String> addresses = preferences.getStringSet(account, new HashSet<String>());
        for (String address : addresses) {
            final String name = preferences.getString(address + NAME_SUFFIX, "");
            final String serial = preferences.getString(address + SERIAL_SUFFIX, "");
            final String password = preferences.getString(address + PASSWORD_SUFFIX, "");
            final String wolkName = preferences.getString(address + WOLK_NAME_SUFFIX, "");

            final HexiwearDevice device = new HexiwearDevice(name, serial, address, password, wolkName);
            devices.add(device);
        }
        return devices;
    }

    public HexiwearDevice getDevice(String address) {
        final Set<HexiwearDevice> hexiwearDevices = getDevices();
        for (HexiwearDevice device : hexiwearDevices) {
            if (device.getDeviceAddress().equalsIgnoreCase(address)) {
                return device;
            }
        }
        return null;
    }

    public boolean isRegistered(BluetoothDevice device) {
        return getDevice(device.getAddress()) != null;
    }

    public void storeDevice(HexiwearDevice hexiwearDevice) {
        final SharedPreferences.Editor editor = preferences.edit();
        final Set<String> addresses = preferences.getStringSet(account, new HashSet<String>());
        final String address = hexiwearDevice.getDeviceAddress();
        addresses.add(address);
        editor.putStringSet(account, addresses);
        editor.putString(address + NAME_SUFFIX, hexiwearDevice.getDeviceName());
        editor.putString(address + SERIAL_SUFFIX, hexiwearDevice.getDeviceSerial());
        editor.putString(address + PASSWORD_SUFFIX, hexiwearDevice.getDevicePassword());
        editor.putString(address + WOLK_NAME_SUFFIX, hexiwearDevice.getWolkName());
        editor.apply();
    }

    public Map<String, Boolean> getDisplayPreferences(String deviceAddress) {
        final Map<String, Boolean> displayPrefs = new HashMap<>();

        final List<Characteristic> readings = Characteristic.getReadings();
        for (Characteristic reading : readings) {
            displayPrefs.put(reading.name(), preferences.getBoolean(deviceAddress + reading.name(), true));
        }

        return displayPrefs;
    }

    public List<String> getEnabledPreferences(String deviceAddress) {
        final List<String> enabledPrefs = new ArrayList<>();

        final Map<String, Boolean> displayPreferences = getDisplayPreferences(deviceAddress);
        for (Map.Entry<String, Boolean> entry : displayPreferences.entrySet()) {
            if (entry.getValue()) {
                enabledPrefs.add(entry.getKey());
            }
        }

        return enabledPrefs;
    }

    public void setDisplayPreferences(String deviceAddress, Map<String, Boolean> displayPrefs) {
        final SharedPreferences.Editor editor = preferences.edit();
        for (Map.Entry<String, Boolean> entry : displayPrefs.entrySet()) {
            editor.putBoolean(deviceAddress + entry.getKey(), entry.getValue());
        }
        editor.apply();
    }

    public static List<HexiwearDevice> getDevices(List<PointWithFeedsResponse> response) {
        final List<HexiwearDevice> devices = new ArrayList<>();

        for (PointWithFeedsResponse pwf : response) {
            if (pwf.getDeviceSerial().length() > 8 && "HX".equalsIgnoreCase(pwf.getDeviceSerial().substring(4, 6))) {
                devices.add(new HexiwearDevice(pwf.getName(), pwf.getDeviceSerial(), "", "", pwf.getName()));
            }
        }

        return devices;
    }

    public void setPublishInterval(final HexiwearDevice device, final int interval) {
        preferences.edit().putInt(device.getDeviceAddress() + PUBLISH_INTERVAL_SUFFIX, interval).apply();
    }

    public int getPublishInterval(final HexiwearDevice device) {
        return preferences.getInt(device.getDeviceAddress() + PUBLISH_INTERVAL_SUFFIX, 10);
    }

    public void toggleTracking(final BluetoothDevice device) {
        final boolean isTracking = shouldTransmit(device);
        preferences.edit().putBoolean(device.getAddress() + SHOULD_TRANSMIT_SUFFIX, !isTracking).apply();
    }

    public void toggleTracking(final HexiwearDevice device) {
        final boolean isTracking = shouldTransmit(device);
        preferences.edit().putBoolean(device.getDeviceAddress() + SHOULD_TRANSMIT_SUFFIX, !isTracking).apply();
    }

    public boolean shouldTransmit(final BluetoothDevice device) {
        return preferences.getBoolean(device.getAddress() + SHOULD_TRANSMIT_SUFFIX, false);
    }

    public boolean shouldTransmit(final HexiwearDevice device) {
        return preferences.getBoolean(device.getDeviceAddress() + SHOULD_TRANSMIT_SUFFIX, false);
    }

    public void setKeepAlive(final HexiwearDevice device, final boolean keepAlive) {
        preferences.edit().putBoolean(device.getDeviceAddress() + KEEP_ALIVE_SUFFIX, keepAlive).apply();
    }

    public boolean shouldKeepAlive(final HexiwearDevice device) {
        return preferences.getBoolean(device.getDeviceAddress() + KEEP_ALIVE_SUFFIX, true);
    }

}
