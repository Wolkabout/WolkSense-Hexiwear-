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

package com.wolkabout.hexiwear.service;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.wolkabout.hexiwear.model.BluetoothDeviceWrapper;

import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.api.BackgroundExecutor;
import org.parceler.Parcels;

@EBean
public class DeviceDiscoveryService {

    private static final String TAG = DeviceDiscoveryService.class.getSimpleName();

    private static final long SCAN_PERIOD = 5000;
    private static final String SCAN_TASK = "scan";
    private static final String HEXIWEAR_TAG = "hexiwear";
    private static final String HEXI_OTAP_TAG = "hexiotap";

    public static final String SCAN_STARTED = "scanStarted";
    public static final String SCAN_STOPPED = "scanStopped";
    public static final String DEVICE_DISCOVERED = "deviceDiscovered";
    public static final String WRAPPER = "wrapper";

    private static final BluetoothAdapter bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

    @RootContext
    Context context;

    private static ScanCallback lolipopScanCallback;
    private static BluetoothAdapter.LeScanCallback kitKatScanCallback;

    public void startScan() {
        if (!isEnabled()) {
            return;
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            startKitKatScan();
        } else {
            startLolipopScan();
        }

        setScanTimeLimit();
        sendBroadcast(new Intent(SCAN_STARTED));
        Log.i(TAG, "Bluetooth device discovery started.");
    }

    @SuppressWarnings("deprecation")
    @TargetApi(Build.VERSION_CODES.KITKAT)
    public void startKitKatScan() {
        kitKatScanCallback = new BluetoothAdapter.LeScanCallback() {
            @Override
            public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
                final BluetoothDeviceWrapper wrapper = new BluetoothDeviceWrapper();
                wrapper.setDevice(device);
                wrapper.setSignalStrength(rssi);
                onDeviceDiscovered(wrapper);
            }
        };
        bluetoothAdapter.startLeScan(kitKatScanCallback);
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private void startLolipopScan() {
        lolipopScanCallback = new ScanCallback() {
            @Override
            public void onScanResult(int callbackType, ScanResult result) {
                super.onScanResult(callbackType, result);
                final BluetoothDeviceWrapper wrapper = new BluetoothDeviceWrapper();
                wrapper.setDevice(result.getDevice());
                wrapper.setSignalStrength(result.getRssi());
                onDeviceDiscovered(wrapper);
            }
        };
        bluetoothAdapter.getBluetoothLeScanner().startScan(lolipopScanCallback);
    }

    private void onDeviceDiscovered(final BluetoothDeviceWrapper wrapper) {
        final BluetoothDevice device = wrapper.getDevice();
        Log.i(TAG, "Discovered device: " + device.getName() + "(" + device.getAddress() + ")");
        final String name = wrapper.getDevice().getName();
        if (HEXI_OTAP_TAG.equalsIgnoreCase(name)) {
            wrapper.setInOtapMode(true);
        } else if (!HEXIWEAR_TAG.equalsIgnoreCase(name)) {
            return;
        }

        final Intent deviceDiscovered = new Intent(DEVICE_DISCOVERED);
        deviceDiscovered.putExtra(WRAPPER, Parcels.wrap(wrapper));
        sendBroadcast(deviceDiscovered);
    }

    @Background(id = SCAN_TASK, delay = SCAN_PERIOD)
    void setScanTimeLimit() {
        cancelScan();
    }

    @SuppressWarnings("deprecation")
    public void cancelScan() {
        if (!isEnabled()) {
            return;
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            bluetoothAdapter.stopLeScan(kitKatScanCallback);
        } else {
            bluetoothAdapter.getBluetoothLeScanner().stopScan(lolipopScanCallback);
        }

        sendBroadcast(new Intent(SCAN_STOPPED));
        Log.i(TAG, "Bluetooth device discovery canceled");
        BackgroundExecutor.cancelAll(SCAN_TASK, true);
    }

    boolean isEnabled() {
        if (bluetoothAdapter == null) {
            Log.e(TAG, "Bluetooth not supported");
            return false;
        } else if (!bluetoothAdapter.isEnabled()) {
            context.startActivity(new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE));
            return false;
        } else {
            Log.v(TAG, "Bluetooth is enabled and functioning properly.");
            return true;
        }
    }

    private void sendBroadcast(Intent intent) {
        LocalBroadcastManager.getInstance(context).sendBroadcast(intent);
    }
}
