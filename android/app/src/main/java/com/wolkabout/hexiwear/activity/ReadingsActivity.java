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

package com.wolkabout.hexiwear.activity;

import android.app.ProgressDialog;
import android.bluetooth.BluetoothDevice;
import android.content.ComponentName;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.support.design.widget.Snackbar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.Menu;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.Characteristic;
import com.wolkabout.hexiwear.model.HexiwearDevice;
import com.wolkabout.hexiwear.model.Mode;
import com.wolkabout.hexiwear.service.BluetoothService;
import com.wolkabout.hexiwear.service.BluetoothService_;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.util.HexiwearDevices;
import com.wolkabout.hexiwear.view.Reading;
import com.wolkabout.hexiwear.view.SingleReading;
import com.wolkabout.hexiwear.view.TripleReading;
import com.wolkabout.wolkrestandroid.Credentials_;

import org.androidannotations.annotations.AfterInject;
import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.Extra;
import org.androidannotations.annotations.OptionsItem;
import org.androidannotations.annotations.OptionsMenu;
import org.androidannotations.annotations.Receiver;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.sharedpreferences.Pref;

import java.lang.reflect.InvocationTargetException;
import java.util.Map;

@EActivity(R.layout.activity_readings)
@OptionsMenu(R.menu.menu_readings)
public class ReadingsActivity extends AppCompatActivity implements ServiceConnection {

    private static final String TAG = ReadingsActivity.class.getSimpleName();

    @Extra
    BluetoothDevice device;

    @ViewById
    View coordinator;

    @ViewById
    Toolbar toolbar;

    @ViewById
    SingleReading readingBattery;

    @ViewById
    SingleReading readingTemperature;

    @ViewById
    SingleReading readingHumidity;

    @ViewById
    SingleReading readingPressure;

    @ViewById
    SingleReading readingHeartRate;

    @ViewById
    SingleReading readingLight;

    @ViewById
    SingleReading readingSteps;

    @ViewById
    SingleReading readingCalories;

    @ViewById
    TripleReading readingAcceleration;

    @ViewById
    TripleReading readingMagnet;

    @ViewById
    TripleReading readingGyro;

    @ViewById
    TextView connectionStatus;

    @ViewById
    ProgressBar progressBar;

    @ViewById
    LinearLayout readings;

    @Bean
    HexiwearDevices hexiwearDevices;

    @Pref
    Credentials_ credentials;

    @Bean
    Dialog dialog;

    private ProgressDialog progressDialog;
    private HexiwearDevice hexiwearDevice;
    private BluetoothService bluetoothService;
    private boolean isBound;
    private Mode mode = Mode.IDLE;
    private boolean shouldUnpair;

    @AfterInject
    void startService() {
        hexiwearDevice = hexiwearDevices.getDevice(device.getAddress());
        if (hexiwearDevices.shouldKeepAlive(hexiwearDevice)) {
            BluetoothService_.intent(this).start();
        }
        isBound = bindService(BluetoothService_.intent(this).get(), this, BIND_AUTO_CREATE);
    }

    @AfterViews
    void setViews() {
        toolbar.setTitle(hexiwearDevice.getWolkName());
        setSupportActionBar(toolbar);
        progressBar.setVisibility(View.VISIBLE);
    }

    @Override
    protected void onResume() {
        super.onResume();
        shouldUnpair = false;
        invalidateOptionsMenu();
        setReadingVisibility(mode);
    }

    @Receiver(actions = BluetoothService.MODE_CHANGED, local = true)
    void onModeChanged(@Receiver.Extra final Mode mode) {
        this.mode = mode;
        connectionStatus.setText(mode.getStringResource());

        if (mode == Mode.IDLE) {
            dialog.showInfo(R.string.readings_idle_mode, false);
        }

        setReadingVisibility(mode);
    }

    @Receiver(actions = BluetoothService.BLUETOOTH_SERVICE_STOPPED, local = true)
    void onBluetoothServiceDestroyed() {
        if (!shouldUnpair) {
            return;
        }

        try {
            device.getClass().getMethod("removeBond", (Class[]) null).invoke(device, (Object[]) null);
            dialog.shortToast(R.string.device_unpaired);
            if (progressDialog != null) {
                progressDialog.dismiss();
            }
            finish();
        } catch (IllegalAccessException | InvocationTargetException | NoSuchMethodException e) {
            e.printStackTrace();
            dialog.shortToast(R.string.failed_to_unpair);
        }
    }

    @Receiver(actions = BluetoothService.SHOW_TIME_PROGRESS, local = true)
    void showProgressForSettingTime() {
        if (progressBar == null) {
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
    }

    @Receiver(actions = BluetoothService.HIDE_TIME_PROGRESS, local = true)
    void hideProgressForSettingTime() {
        if (progressBar == null) {
            return;
        }

        progressBar.setVisibility(View.INVISIBLE);
    }

    private void setReadingVisibility(final Mode mode) {
        final Map<String, Boolean> displayPreferences = hexiwearDevices.getDisplayPreferences(device.getAddress());
        for (int i = 0; i < readings.getChildCount(); i++) {
            final Reading reading = (Reading) readings.getChildAt(i);
            final Characteristic readingType = reading.getReadingType();
            final boolean readingEnabled = displayPreferences.get(readingType.name());
            reading.setVisibility(readingEnabled && mode.hasCharacteristic(readingType) ? View.VISIBLE : View.GONE);
        }
    }

    @Override
    public void onServiceConnected(final ComponentName name, final IBinder service) {
        final BluetoothService.ServiceBinder binder = (BluetoothService.ServiceBinder) service;
        bluetoothService = binder.getService();
        if (!bluetoothService.isConnected()) {
            bluetoothService.startReading(device);
        }
        final Mode mode = bluetoothService.getCurrentMode();
        if (mode != null) {
            onModeChanged(mode);
        }
    }

    @Override
    public void onServiceDisconnected(final ComponentName name) {
        // Something terrible happened.
    }

    @Override
    protected void onDestroy() {
        if (isBound) {
            unbindService(this);
            isBound = false;
        }
        super.onDestroy();
    }

    @Receiver(actions = BluetoothService.ACTION_NEEDS_BOND, local = true)
    void onBondRequested() {
        connectionStatus.setText(R.string.discovery_pairing);
        Snackbar.make(coordinator, R.string.discovery_pairing, Snackbar.LENGTH_LONG).show();
    }

    @Receiver(actions = BluetoothService.CONNECTION_STATE_CHANGED, local = true)
    void onConnectionStateChanged(@Receiver.Extra final boolean connectionState) {
        connectionStatus.setText(connectionState ? R.string.readings_connection_connected : R.string.readings_connection_reconnecting);
    }

    @Receiver(actions = BluetoothService.DATA_AVAILABLE, local = true)
    void onDataAvailable(Intent intent) {
        progressBar.setVisibility(View.INVISIBLE);

        final String uuid = intent.getStringExtra(BluetoothService.READING_TYPE);
        final String data = intent.getStringExtra(BluetoothService.STRING_DATA);

        if (data.isEmpty()) {
            return;
        }

        final Characteristic characteristic = Characteristic.byUuid(uuid);
        if (characteristic == null) {
            Log.w(TAG, "UUID " + uuid + " is unknown. Skipping.");
            return;
        }

        switch (characteristic) {
            case BATTERY:
                readingBattery.setValue(data);
                break;
            case TEMPERATURE:
                readingTemperature.setValue(data);
                break;
            case HUMIDITY:
                readingHumidity.setValue(data);
                break;
            case PRESSURE:
                readingPressure.setValue(data);
                break;
            case HEARTRATE:
                readingHeartRate.setValue(data);
                break;
            case LIGHT:
                readingLight.setValue(data);
                break;
            case STEPS:
                readingSteps.setValue(data);
                break;
            case CALORIES:
                readingCalories.setValue(data);
                break;
            case ACCELERATION:
                final String[] accelerationReadings = data.split(";");
                readingAcceleration.setFirstValue(accelerationReadings[0]);
                readingAcceleration.setSecondValue(accelerationReadings[1]);
                readingAcceleration.setThirdValue(accelerationReadings[2]);
                break;
            case MAGNET:
                final String[] magnetReadings = data.split(";");
                readingMagnet.setFirstValue(magnetReadings[0]);
                readingMagnet.setSecondValue(magnetReadings[1]);
                readingMagnet.setThirdValue(magnetReadings[2]);
                break;
            case GYRO:
                final String[] gyroscopeReadings = data.split(";");
                readingGyro.setFirstValue(gyroscopeReadings[0]);
                readingGyro.setSecondValue(gyroscopeReadings[1]);
                readingGyro.setThirdValue(gyroscopeReadings[2]);
                break;
            default:
                break;
        }
    }

    @Receiver(actions = BluetoothService.STOP)
    void onStopReading() {
        Log.i(TAG, "Stop command received. Finishing...");
        finish();
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        final boolean shouldTransmit = hexiwearDevices.shouldTransmit(device);
        final int icon = shouldTransmit ? R.drawable.ic_cloud_queue_white_48dp : R.drawable.ic_cloud_off_white_48dp;
        menu.getItem(0).setIcon(icon);
        return super.onPrepareOptionsMenu(menu);
    }

    @OptionsItem
    void openSettings() {
        SettingsActivity_.intent(this).device(hexiwearDevice).manufacturerInfo(bluetoothService.getManufacturerInfo()).start();
    }

    @OptionsItem
    void setTime() {
        bluetoothService.setTime();
    }

    @OptionsItem
    void toggleTracking() {
        if (credentials.username().get().equals("Demo")) {
            return;
        }

        hexiwearDevices.toggleTracking(device);
        final boolean shouldTransmit = hexiwearDevices.shouldTransmit(device);
        bluetoothService.setTracking(shouldTransmit);
        supportInvalidateOptionsMenu();
    }

    @OptionsItem
    void unpair() {
        dialog.showConfirmation(0, R.string.unpair_message, R.string.yes, R.string.no, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int which) {
                progressDialog = dialog.createProgressDialog(R.string.readings_unpairing);
                progressDialog.show();
                stopBluetoothServiceAndUnpair();
            }
        }, true);
    }

    private void stopBluetoothServiceAndUnpair() {
        shouldUnpair = true;
        if (isBound) {
            unbindService(this);
            isBound = false;
        }
        BluetoothService_.intent(this).stop();
    }

    @Override
    public void onBackPressed() {
        if (isTaskRoot()) {
            MainActivity_.intent(this).start();
        }
        BluetoothService_.intent(this).stop();
        super.onBackPressed();
    }

}
