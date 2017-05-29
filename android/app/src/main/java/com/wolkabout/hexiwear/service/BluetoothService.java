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

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.Intent;
import android.graphics.Color;
import android.os.Binder;
import android.os.IBinder;
import android.support.v4.app.NotificationCompat;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.widget.Toast;

import com.wolkabout.hexiwear.BuildConfig;
import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.activity.MainActivity_;
import com.wolkabout.hexiwear.activity.ReadingsActivity_;
import com.wolkabout.hexiwear.model.Characteristic;
import com.wolkabout.hexiwear.model.HexiwearDevice;
import com.wolkabout.hexiwear.model.ManufacturerInfo;
import com.wolkabout.hexiwear.model.Mode;
import com.wolkabout.hexiwear.util.ByteUtils;
import com.wolkabout.hexiwear.util.DataConverter;
import com.wolkabout.hexiwear.util.HexiwearDevices;
import com.wolkabout.wolk.Logger;
import com.wolkabout.wolk.ReadingType;
import com.wolkabout.wolk.Wolk;
import com.wolkabout.wolkrestandroid.Credentials_;

import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EService;
import org.androidannotations.annotations.Receiver;
import org.androidannotations.annotations.SystemService;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.sharedpreferences.Pref;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.TimeZone;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;

@EService
public class BluetoothService extends Service {

    private static final String TAG = BluetoothService.class.getSimpleName();

    public static final String SERVICES_AVAILABLE = "servicesAvailable";
    public static final String DATA_AVAILABLE = "dataAvailable";
    public static final String READING_TYPE = "readingType";
    public static final String CONNECTION_STATE_CHANGED = "ConnectionStateChange";
    public static final String CONNECTION_STATE = "connectionState";
    public static final String STRING_DATA = "stringData";
    public static final String STOP = "stop";
    public static final String ACTION_NEEDS_BOND = "noBond";
    public static final String PREFERENCE_CHANGED = "preferenceChanged";
    public static final String PREFERENCE_NAME = "preferenceName";
    public static final String PREFERENCE_ENABLED = "preferenceEnabled";
    public static final String PUBLISH_TIME_CHANGED = "publishTimeChanged";
    public static final String SHOULD_PUBLISH_CHANGED = "shouldPublishChanged";
    public static final String MODE_CHANGED = "modeChanged";
    public static final String MODE = "mode";
    public static final String BLUETOOTH_SERVICE_STOPPED = "BLUETOOTH_SERVICE_STOPPED";
    public static final String SHOW_TIME_PROGRESS = "SHOW_TIME_PROGRESS";
    public static final String HIDE_TIME_PROGRESS = "HIDE_TIME_PROGRESS";

    // Notification types
    private static final byte MISSED_CALLS = 2;
    private static final byte UNREAD_MESSAGES = 4;
    private static final byte UNREAD_EMAILS = 6;

    // Alert In commands
    private static final byte WRITE_NOTIFICATION = 1;
    private static final byte WRITE_TIME = 3;

    private static final Map<String, BluetoothGattCharacteristic> readableCharacteristics = new HashMap<>();
    private static final ManufacturerInfo manufacturerInfo = new ManufacturerInfo();
    private static final Queue<String> readingQueue = new ArrayBlockingQueue<>(12);
    private static final Queue<byte[]> notificationsQueue = new LinkedBlockingDeque<>();

    private volatile boolean shouldUpdateTime;
    private volatile boolean isConnected;
    private BluetoothDevice bluetoothDevice;
    private HexiwearDevice hexiwearDevice;
    private BluetoothGattCharacteristic alertIn;
    private BluetoothGatt bluetoothGatt;
    private Wolk wolk;
    private Mode mode;

    @Bean
    HexiwearDevices hexiwearDevices;

    @SystemService
    NotificationManager notificationManager;

    @Pref
    Credentials_ credentials;

    @Receiver(actions = BluetoothDevice.ACTION_BOND_STATE_CHANGED)
    void onBondStateChanged(Intent intent) {
        final BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
        final int bondState = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, -1);
        final int previousBondState = intent.getIntExtra(BluetoothDevice.EXTRA_PREVIOUS_BOND_STATE, -1);

        Log.d(TAG, "Bond state changed for: " + device.getAddress() + " new state: " + bondState + " previous: " + previousBondState);

        if (bondState == BluetoothDevice.BOND_BONDED) {
            Log.i(TAG, "Bonded");
            createGATT(device);
        } else if (bondState == BluetoothDevice.BOND_NONE) {
            device.createBond();
        }
    }

    @Receiver(actions = STOP)
    void onStopCommand() {
        Log.i(TAG, "Stop command received.");
        stopForeground(true);
        stopSelf();
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Stopping service...");
        if (bluetoothGatt != null) {
            bluetoothGatt.close();
            NotificationService_.intent(this).stop();
        }
        if (wolk != null && hexiwearDevices.shouldTransmit(hexiwearDevice)) {
            wolk.stopAutoPublishing();
        }

        Log.d(TAG, "onDestroy: sending intent that bt service stopped");
        final Intent intent = new Intent(BLUETOOTH_SERVICE_STOPPED);
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    public void startReading(BluetoothDevice device) {
        Log.i(TAG, "Starting to read data for device: " + device.getName());
        hexiwearDevice = hexiwearDevices.getDevice(device.getAddress());
        bluetoothDevice = device;
        createGATT(device);

        if (credentials.username().get().equals("Demo")) {
            return;
        }

        wolk = new Wolk(hexiwearDevice, BuildConfig.MQTT_HOST);
        wolk.setLogger(new Logger() {
            @Override
            public void info(final String message) {
                Log.i(TAG, message);
            }

            @Override
            public void error(final String message, final Throwable e) {
                Log.e(TAG, message, e);
            }
        });

        if (hexiwearDevices.shouldTransmit(device)) {
            final int publishInterval = hexiwearDevices.getPublishInterval(hexiwearDevice);
            wolk.startAutoPublishing(publishInterval);
        }
    }

    private void createGATT(final BluetoothDevice device) {
        bluetoothGatt = device.connectGatt(this, true, new BluetoothGattCallback() {
            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                isConnected = BluetoothProfile.STATE_CONNECTED == newState;
                if (isConnected) {
                    Log.i(TAG, "GATT connected.");
                    startForeground(442, getNotification(device));
                    gatt.discoverServices();
                } else {
                    Log.i(TAG, "GATT disconnected.");
                    NotificationService_.intent(BluetoothService.this).stop();
                    notificationManager.notify(442, getNotification(device));
                    gatt.connect();
                }

                final Intent connectionStateChanged = new Intent(CONNECTION_STATE_CHANGED);
                connectionStateChanged.putExtra(CONNECTION_STATE, isConnected);
                sendBroadcast(connectionStateChanged);
            }

            @Override
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                Log.i(TAG, "Services discovered.");
                if (status == BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION) {
                    handleAuthenticationError(gatt);
                    return;
                }

                discoverCharacteristics(gatt);
            }

            @Override
            public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
                Log.i(TAG, "Characteristic written: " + status);

                if (status == BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION) {
                    handleAuthenticationError(gatt);
                    return;
                }

                final byte command = characteristic.getValue()[0];
                switch (command) {
                    case WRITE_TIME:
                        Log.i(TAG, "Time written.");
                        showToast(R.string.readings_time_set_success);
                        final Intent intent = new Intent(HIDE_TIME_PROGRESS);
                        sendBroadcast(intent);

                        final BluetoothGattCharacteristic batteryCharacteristic = readableCharacteristics.get(Characteristic.BATTERY.getUuid());
                        gatt.setCharacteristicNotification(batteryCharacteristic, true);
                        for (BluetoothGattDescriptor descriptor : batteryCharacteristic.getDescriptors()) {
                            if (descriptor.getUuid().toString().startsWith("00002904")) {
                                descriptor.setValue(BluetoothGattDescriptor.ENABLE_INDICATION_VALUE);
                                gatt.writeDescriptor(descriptor);
                            }
                        }
                        break;
                    case WRITE_NOTIFICATION:
                        Log.i(TAG, "Notification sent.");
                        if (notificationsQueue.isEmpty()) {
                            Log.i(TAG, "Reading characteristics...");
                            readNextCharacteristics(gatt);
                        } else {
                            Log.i(TAG, "writing next notification...");
                            alertIn.setValue(notificationsQueue.poll());
                            gatt.writeCharacteristic(alertIn);
                        }
                        break;
                    default:
                        Log.w(TAG, "No such ALERT IN command: " + command);
                        break;
                }
            }

            @Override
            public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
                readCharacteristic(gatt, Characteristic.MANUFACTURER);
            }

            @Override
            public void onCharacteristicRead(BluetoothGatt gatt, final BluetoothGattCharacteristic gattCharacteristic, int status) {
                if (status == BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION) {
                    handleAuthenticationError(gatt);
                    return;
                }

                final String characteristicUuid = gattCharacteristic.getUuid().toString();
                final Characteristic characteristic = Characteristic.byUuid(characteristicUuid);
                switch (characteristic) {
                    case MANUFACTURER:
                        manufacturerInfo.manufacturer = gattCharacteristic.getStringValue(0);
                        readCharacteristic(gatt, Characteristic.FW_REVISION);
                        break;
                    case FW_REVISION:
                        manufacturerInfo.firmwareRevision = gattCharacteristic.getStringValue(0);
                        readCharacteristic(gatt, Characteristic.MODE);
                        break;
                    default:
                        Log.v(TAG, "Characteristic read: " + characteristic.name());
                        if (characteristic == Characteristic.MODE) {
                            final Mode newMode = Mode.bySymbol(gattCharacteristic.getValue()[0]);
                            if (mode != newMode) {
                                onModeChanged(newMode);
                            }
                        } else {
                            onBluetoothDataReceived(characteristic, gattCharacteristic.getValue());
                        }

                        if (shouldUpdateTime) {
                            updateTime();
                        }

                        if (notificationsQueue.isEmpty()) {
                            readNextCharacteristics(gatt);
                        } else {
                            alertIn.setValue(notificationsQueue.poll());
                            gatt.writeCharacteristic(alertIn);
                        }

                        break;
                }
            }

            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic gattCharacteristic) {
                final String characteristicUuid = gattCharacteristic.getUuid().toString();
                final Characteristic characteristic = Characteristic.byUuid(characteristicUuid);
                Log.d(TAG, "Characteristic changed: " + characteristic);

                if (characteristic == Characteristic.BATTERY) {
                    onBluetoothDataReceived(Characteristic.BATTERY, gattCharacteristic.getValue());
                }
            }
        });
    }

    private void onModeChanged(final Mode newMode) {
        Log.i(TAG, "Mode changed. New mode is: " + mode);
        mode = newMode;

        setReadingQueue();

        final Intent modeChanged = new Intent(MODE_CHANGED);
        modeChanged.putExtra(MODE, newMode);
        LocalBroadcastManager.getInstance(this).sendBroadcast(modeChanged);
    }

    private void setReadingQueue() {
        readingQueue.clear();
        readingQueue.add(Characteristic.MODE.name());
        final List<String> enabledPreferences = hexiwearDevices.getEnabledPreferences(bluetoothDevice.getAddress());
        for (String characteristic : enabledPreferences) {
            if (mode.hasCharacteristic(characteristic)) {
                readingQueue.add(characteristic);
            }
        }
    }

    @Receiver(actions = PREFERENCE_CHANGED, local = true)
    void preferenceChanged(@Receiver.Extra String preferenceName, @Receiver.Extra boolean preferenceEnabled) {
        if (!mode.hasCharacteristic(preferenceName)) {
            return;
        }

        if (preferenceEnabled) {
            readingQueue.add(preferenceName);
        } else {
            readingQueue.remove(preferenceName);
        }
    }

    @Receiver(actions = PUBLISH_TIME_CHANGED, local = true)
    void onPublishTimeChanged() {
        if (hexiwearDevices.shouldTransmit(hexiwearDevice)) {
            setTracking(false);
            setTracking(true);
        }
    }

    @Receiver(actions = SHOULD_PUBLISH_CHANGED, local = true)
    void onShouldPublishChanged() {
        setTracking(hexiwearDevices.shouldTransmit(hexiwearDevice));
    }

    @Receiver(actions = NotificationService.MISSED_CALLS_AMOUNT_CHANGED, local = true)
    void onMissedCallsAmountChanged(@Receiver.Extra final int value) {
        queueNotification(MISSED_CALLS, value);
    }

    @Receiver(actions = NotificationService.UNREAD_MESSAGES_AMOUNT_CHANGED, local = true)
    void onUnreadMessagesAmountChanged(@Receiver.Extra final int value) {
        queueNotification(UNREAD_MESSAGES, value);
    }

    @Receiver(actions = NotificationService.UNREAD_EMAILS_AMOUNT_CHANGED, local = true)
    void onUnreadEmailAmountChanged(@Receiver.Extra final int value) {
        queueNotification(UNREAD_EMAILS, value);
    }

    private void queueNotification(final byte type, final int amount) {
        final byte[] notification = new byte[20];
        notification[0] = WRITE_NOTIFICATION;
        notification[1] = type;
        notification[2] = ByteUtils.intToByte(amount);
        notificationsQueue.add(notification);
    }

    private void onBluetoothDataReceived(final Characteristic type, final byte[] data) {
        if (wolk != null && hexiwearDevices.shouldTransmit(hexiwearDevice) && type != Characteristic.BATTERY) {
            final ReadingType readingType = ReadingType.valueOf(type.name());
            wolk.addReading(readingType, DataConverter.formatForPublushing(type, data));
        }

        final Intent dataRead = new Intent(DATA_AVAILABLE);
        dataRead.putExtra(READING_TYPE, type.getUuid());
        dataRead.putExtra(STRING_DATA, DataConverter.parseBluetoothData(type, data));
        sendBroadcast(dataRead);
    }

    void readNextCharacteristics(final BluetoothGatt gatt) {
        final String characteristicUuid = readingQueue.poll();
        readingQueue.add(characteristicUuid);
        readCharacteristic(gatt, Characteristic.valueOf(characteristicUuid));
    }

    private void readCharacteristic(final BluetoothGatt gatt, final Characteristic characteristic) {
        if (!isConnected) {
            return;
        }

        final BluetoothGattCharacteristic gattCharacteristic = readableCharacteristics.get(characteristic.getUuid());
        if (gattCharacteristic != null) {
            gatt.readCharacteristic(gattCharacteristic);
        }
    }

    private void discoverCharacteristics(final BluetoothGatt gatt) {
        if (gatt.getServices().size() == 0) {
            Log.i(TAG, "No services found.");
        }

        for (BluetoothGattService gattService : gatt.getServices()) {
            storeCharacteristicsFromService(gattService);
        }

        sendBroadcast(new Intent(SERVICES_AVAILABLE));
    }

    private void storeCharacteristicsFromService(BluetoothGattService gattService) {
        for (BluetoothGattCharacteristic gattCharacteristic : gattService.getCharacteristics()) {
            final String characteristicUuid = gattCharacteristic.getUuid().toString();
            final Characteristic characteristic = Characteristic.byUuid(characteristicUuid);

            if (characteristic == Characteristic.ALERT_IN) {
                Log.d(TAG, "ALERT_IN DISCOVERED");
                alertIn = gattCharacteristic;
                setTime();
                updateTime();
                NotificationService_.intent(BluetoothService.this).start();
            } else if (characteristic != null) {
                Log.v(TAG, characteristic.getType() + ": " + characteristic.name());
                readableCharacteristics.put(characteristicUuid, gattCharacteristic);
            } else {
                Log.v(TAG, "UNKNOWN: " + characteristicUuid);
            }
        }
    }

    public void setTime() {
        Log.d(TAG, "Setting time...");
        if (!isConnected || alertIn == null) {
            Log.w(TAG, "Time not set.");
            return;
        }

        shouldUpdateTime = true;
    }

    void updateTime() {
        shouldUpdateTime = false;

        final byte[] time = new byte[20];
        final long currentTime = System.currentTimeMillis();
        final long currentTimeWithTimeZoneOffset = (currentTime + TimeZone.getDefault().getOffset(currentTime)) / 1000;

        final ByteBuffer buffer = ByteBuffer.allocate(8);
        buffer.order(ByteOrder.LITTLE_ENDIAN).asLongBuffer().put(currentTimeWithTimeZoneOffset);
        final byte[] utcBytes = buffer.array();

        final byte length = 0x04;

        time[0] = WRITE_TIME;
        time[1] = length;
        time[2] = utcBytes[0];
        time[3] = utcBytes[1];
        time[4] = utcBytes[2];
        time[5] = utcBytes[3];

        alertIn.setValue(time);
        alertIn.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        bluetoothGatt.writeCharacteristic(alertIn);
        final Intent intent = new Intent(SHOW_TIME_PROGRESS);
        sendBroadcast(intent);
        showToast(R.string.readings_setting_time);
    }

    @UiThread
    void showToast(int messageRes) {
        Toast.makeText(getApplicationContext(), messageRes, Toast.LENGTH_SHORT).show();
    }

    public void setTracking(final boolean enabled) {
        if (enabled) {
            final int publishInterval = hexiwearDevices.getPublishInterval(hexiwearDevice);
            wolk.startAutoPublishing(publishInterval);
        } else {
            wolk.stopAutoPublishing();
        }
    }

    public boolean isConnected() {
        return isConnected;
    }

    public Mode getCurrentMode() {
        return mode;
    }

    public BluetoothDevice getCurrentDevice() {
        return bluetoothDevice;
    }

    private void handleAuthenticationError(final BluetoothGatt gatt) {
        gatt.close();
        sendBroadcast(new Intent(BluetoothService.ACTION_NEEDS_BOND));
        gatt.getDevice().createBond();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new ServiceBinder(this);
    }

    public ManufacturerInfo getManufacturerInfo() {
        return manufacturerInfo;
    }

    protected Notification getNotification(final BluetoothDevice device) {
        final boolean connectionEstablished = isConnected && bluetoothGatt != null && bluetoothGatt.getDevice() != null;
        final String text = connectionEstablished ? "Device is connected to " + hexiwearDevice.getWolkName() : "Device is not connected.";
        final int icon = connectionEstablished ? R.drawable.ic_bluetooth_connected_white_48dp : R.drawable.ic_bluetooth_searching_white_48dp;

        final Intent readingsActivityIntent = ReadingsActivity_.intent(this).flags(Intent.FLAG_ACTIVITY_SINGLE_TOP).device(device).get();
        final Intent mainActivityIntent = MainActivity_.intent(this).flags(Intent.FLAG_ACTIVITY_SINGLE_TOP).get();
        final Intent launchActivity = connectionEstablished ? readingsActivityIntent : mainActivityIntent;
        final PendingIntent pendingIntentMain = PendingIntent.getActivity(this, 71, launchActivity, PendingIntent.FLAG_UPDATE_CURRENT);

        final Intent stopIntent = new Intent(STOP);
        final PendingIntent pendingStopIntent = PendingIntent.getBroadcast(this, 0, stopIntent, 0);

        return new NotificationCompat.Builder(this)
                .setSmallIcon(icon)
                .setContentTitle(getResources().getString(R.string.app_name))
                .setContentIntent(pendingIntentMain)
                .setLights(Color.GREEN, 100, 5000)
                .addAction(R.drawable.ic_cloud_off_black_24dp, "Stop", pendingStopIntent)
                .setContentText(text).build();
    }

    @Override
    public void sendBroadcast(Intent intent) {
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    public class ServiceBinder extends Binder {

        private BluetoothService service;

        public ServiceBinder(BluetoothService service) {
            this.service = service;
        }

        public BluetoothService getService() {
            return service;
        }

    }
}
