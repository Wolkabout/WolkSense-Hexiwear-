/**
 *  Hexiwear application is used to pair with Hexiwear BLE devices
 *  and send sensor readings to WolkSense sensor data cloud
 *
 *  Copyright (C) 2016 WolkAbout Technology s.r.o.
 *
 *  Hexiwear is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Hexiwear is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package com.wolkabout.hexiwear.activity;

import android.bluetooth.BluetoothDevice;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.support.v4.widget.SwipeRefreshLayout;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.ListView;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.adapter.DeviceListAdapter;
import com.wolkabout.hexiwear.model.BluetoothDeviceWrapper;
import com.wolkabout.hexiwear.service.BluetoothService;
import com.wolkabout.hexiwear.service.BluetoothService_;
import com.wolkabout.hexiwear.service.DeviceDiscoveryService;
import com.wolkabout.hexiwear.service.DeviceRegistrationService;
import com.wolkabout.hexiwear.util.HexiwearDevices;
import com.wolkabout.wolkrestandroid.Credentials_;

import org.androidannotations.annotations.AfterInject;
import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.ItemClick;
import org.androidannotations.annotations.ItemLongClick;
import org.androidannotations.annotations.OptionsItem;
import org.androidannotations.annotations.OptionsMenu;
import org.androidannotations.annotations.OptionsMenuItem;
import org.androidannotations.annotations.Receiver;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.sharedpreferences.Pref;

@OptionsMenu(R.menu.menu_main)
@EActivity(R.layout.activity_main)
public class MainActivity extends AppCompatActivity implements ServiceConnection {

    private static final String TAG = MainActivity.class.getSimpleName();
    private static final String OTAP_PREFIX = "OTAP";

    @Bean
    DeviceListAdapter adapter;

    @ViewById
    ListView listDevices;

    @ViewById
    ProgressBar progressBar;

    @ViewById
    SwipeRefreshLayout swipeRefresh;

    @ViewById
    Toolbar toolbar;

    @OptionsMenuItem
    MenuItem toggleTracking;

    @Pref
    Credentials_ credentials;

    @Bean
    DeviceDiscoveryService deviceDiscoveryService;

    @Bean
    DeviceRegistrationService deviceRegistrationService;

    @Bean
    HexiwearDevices devicesStore;

    private boolean serviceBound;

    @AfterInject
    void setStore() {
        devicesStore.init();
    }

    @AfterViews
    void setViews() {
        setSupportActionBar(toolbar);
        listDevices.setAdapter(adapter);
        deviceDiscoveryService.startScan();
        swipeRefresh.setOnRefreshListener(new SwipeRefreshLayout.OnRefreshListener() {
            @Override
            public void onRefresh() {
                swipeRefresh.setRefreshing(false);
                adapter.clear();
                deviceDiscoveryService.startScan();
            }
        });
    }

    @AfterInject
    void checkService() {
        serviceBound = bindService(BluetoothService_.intent(this).get(), this, 0);
    }

    @ItemClick(R.id.listDevices)
    void bondWithDevice(final BluetoothDeviceWrapper wrapper) {
        deviceDiscoveryService.cancelScan();
        final BluetoothDevice device = wrapper.getDevice();
        if (device.getBondState() == BluetoothDevice.BOND_BONDED) {
            onBonded(device);
        } else {
            device.createBond();
        }
    }

    // TODO This is a method to help with development. Remove once its no longer needed.
    @ItemLongClick(R.id.listDevices)
    void unbindDevice(final BluetoothDeviceWrapper wrapper) {
        try {
            final BluetoothDevice device = wrapper.getDevice();
            device.getClass().getMethod("removeBond", (Class[]) null).invoke(device, (Object[]) null);
            Toast.makeText(this, "Device unpaired.", Toast.LENGTH_SHORT).show();
            adapter.notifyDataSetChanged();
        } catch (Exception e) {
            Log.e(TAG, "Can't remove bond", e);
        }
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        final BluetoothService.ServiceBinder binder = (BluetoothService.ServiceBinder) service;
        final BluetoothService bluetoothService = binder.getService();
        final BluetoothDevice currentDevice = bluetoothService.getCurrentDevice();
        if (currentDevice != null) {
            ReadingsActivity_.intent(this).device(currentDevice).flags(Intent.FLAG_ACTIVITY_NEW_TASK).start();
            final BluetoothDeviceWrapper wrapper = new BluetoothDeviceWrapper();
            wrapper.setDevice(currentDevice);
            wrapper.setSignalStrength(-65);
            adapter.add(wrapper);

        }

        unbindService(this);
        serviceBound = false;
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {
        // Something terrible happened.
    }

    @Override
    protected void onDestroy() {
        if (serviceBound) {
            unbindService(this);
        }
        super.onDestroy();
    }

    @Receiver(actions = DeviceDiscoveryService.SCAN_STARTED, local = true)
    void onScanningStarted() {
        progressBar.setVisibility(View.VISIBLE);
        toolbar.setTitle(R.string.discovery_scanning);
    }

    @Receiver(actions = DeviceDiscoveryService.SCAN_STOPPED, local = true)
    void onScanningStopped() {
        progressBar.setVisibility(View.INVISIBLE);
        toolbar.setTitle(credentials.username().get());
    }

    @Receiver(actions = DeviceDiscoveryService.DEVICE_DISCOVERED, local = true)
    void onBluetoothDeviceFound(@Receiver.Extra final BluetoothDeviceWrapper wrapper) {
        adapter.add(wrapper);
    }

    @Receiver(actions = BluetoothDevice.ACTION_BOND_STATE_CHANGED)
    void onBondStateChanged(Intent intent) {
        final BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
        final int previousBondState = intent.getIntExtra(BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, -1);
        final int newBondState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, -1);

        Log.d(TAG, device.getName() + "(" + device.getAddress() + ") changed state: " + previousBondState + " -> " + newBondState);
        adapter.notifyDataSetChanged();

        if (newBondState == BluetoothDevice.BOND_BONDED) {
            onBonded(device);
        } else if (previousBondState == BluetoothDevice.BOND_BONDING && newBondState == BluetoothDevice.BOND_NONE) {
            device.createBond();
        }
    }

    private void onBonded(BluetoothDevice device) {
        Log.i(TAG, "Successfully bonded to: " + device.getName());
        if (!devicesStore.isRegistered(device)) {
            deviceRegistrationService.registerHexiwearDevice(device);
        } else if (device.getName().contains(OTAP_PREFIX)) {
            FirmwareSelectActivity_.intent(this).device(device).start();
        } else {
            ReadingsActivity_.intent(this).flags(Intent.FLAG_ACTIVITY_SINGLE_TOP).device(device).start();
        }
    }

    @OptionsItem
    void changePassword() {
        PasswordChangeActivity_.intent(this).start();
    }

    @OptionsItem
    void signOut() {
        credentials.clear();
        LoginActivity_.intent(this).flags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK).start();
        finish();
    }

}
