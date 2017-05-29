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
import android.support.annotation.Nullable;
import android.support.v4.app.NotificationCompat;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.Characteristic;
import com.wolkabout.hexiwear.model.otap.Command;
import com.wolkabout.hexiwear.model.otap.Image;
import com.wolkabout.hexiwear.model.otap.ImageBlock;
import com.wolkabout.hexiwear.model.otap.response.ErrorNotification;
import com.wolkabout.hexiwear.model.otap.response.ImageBlockRequest;
import com.wolkabout.hexiwear.model.otap.response.ImageTransferComplete;
import com.wolkabout.hexiwear.util.ByteUtils;

import org.androidannotations.annotations.EService;
import org.androidannotations.annotations.Receiver;
import org.androidannotations.annotations.SystemService;

import java.util.UUID;

@EService
public class FirmwareUpdateService extends Service {

    public static final String UPDATE_INITIATED = "updateStarted";
    public static final String UPDATE_CANCELED = "updateCanceled";
    public static final String UPDATE_FINISHED = "updateFinished";
    public static final String UPDATE_ERROR = "updateError";
    public static final String UPDATE_PROGRESS = "updateProgress";
    public static final String UPDATE_PROGRESS_VALUE = "progress";
    public static final String CANCEL_UPDATE = "cancelUpdate";

    private static final String TAG = FirmwareUpdateService.class.getSimpleName();
    private static final int NOTIFICATION_ID = 1;

    @SystemService
    static NotificationManager notificationManager;

    private static NotificationCompat.Builder notificationBuilder;
    private static BluetoothGatt bluetoothGatt;

    @Override
    public int onStartCommand(final Intent intent, final int flags, final int startId) {
        return START_STICKY;
    }

    @Nullable
    @Override
    public IBinder onBind(final Intent intent) {
        return new ServiceBinder(this);
    }

    public void updateFirmware(final BluetoothDevice device, final Image image) {
        notificationBuilder = new NotificationCompat.Builder(this)
                .setSmallIcon(R.drawable.ic_bluetooth_connected_white_48dp)
                .setContentTitle(getResources().getString(R.string.app_name))
                .setLights(Color.GREEN, 100, 5000);
        startForeground(NOTIFICATION_ID, notificationBuilder.build());

        bluetoothGatt = device.connectGatt(this, true, new FirmwareUpdater(image));
    }

    @Receiver(actions = CANCEL_UPDATE)
    public void cancelUpdate() {
        sendBroadcast(UPDATE_CANCELED);
        stopService();
    }

    private void stopService() {
        if (bluetoothGatt != null) {
            bluetoothGatt.close();
        }
        stopForeground(true);
        stopSelf();
    }

    private void sendBroadcast(final String event) {
        sendBroadcast(new Intent(event));
    }

    public void sendBroadcast(final Intent intent) {
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    private class FirmwareUpdater extends BluetoothGattCallback {

        private static final String OTAP_SERVICE_UUID = "01ff5550-ba5e-f4ee-5ca1-eb1e5e4b1ce0";
        private static final String CONTROL_POINT_DESCRIPTOR_UUID = "00002902-0000-1000-8000-00805f9b34fb";

        private final Image image;

        private BluetoothGattCharacteristic controlPoint;
        private BluetoothGattCharacteristic data;
        private BluetoothGattCharacteristic state;

        private ImageBlock currentBlock;

        public FirmwareUpdater(final Image image) {
            this.image = image;
        }

        @Override
        public void onConnectionStateChange(final BluetoothGatt gatt, final int status, final int newState) {
            if (BluetoothProfile.STATE_CONNECTED == newState) {
                Log.i(TAG, "GATT connected.");
                gatt.discoverServices();
            } else {
                Log.i(TAG, "GATT disconnected.");
                gatt.connect();
            }
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            Log.i(TAG, "Services discovered.");
            if (status == BluetoothGatt.GATT_INSUFFICIENT_AUTHENTICATION) {
                gatt.disconnect();
                gatt.getDevice().createBond();
                return;
            }

            // Get GATT characteristics from the device.
            final BluetoothGattService otapService = gatt.getService(UUID.fromString(OTAP_SERVICE_UUID));
            controlPoint = otapService.getCharacteristic(UUID.fromString(Characteristic.CONTROL_POINT.getUuid()));
            data = otapService.getCharacteristic(UUID.fromString(Characteristic.DATA.getUuid()));
            state = otapService.getCharacteristic(UUID.fromString(Characteristic.STATE.getUuid()));

            gatt.readCharacteristic(state);
        }

        @Override
        public void onCharacteristicRead(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic, final int status) {
            if (characteristic != state) {
                return;
            }

            final int value = ByteUtils.parseInt(characteristic.getValue());
            if (value == 0) {
                Log.e(TAG, "OTAP mode is not enabled.");
                return;
            }

            final boolean wrongModeForMK64 = value == 1 && image.getType() == Image.Type.MK64;
            final boolean wrongModeForKW40 = value == 2 && image.getType() == Image.Type.KW40;
            if (wrongModeForMK64 || wrongModeForKW40) {
                Log.e(TAG, "Wrong OTAP mode for the selected image.");
                sendBroadcast(UPDATE_ERROR);
                return;
            }

            Log.i(TAG, "The device is in the correct OTAP mode. Starting communication.");

            gatt.setCharacteristicNotification(controlPoint, true);

            final BluetoothGattDescriptor descriptor = controlPoint.getDescriptor(UUID.fromString(CONTROL_POINT_DESCRIPTOR_UUID));
            gatt.readDescriptor(descriptor);
        }

        @Override
        public void onDescriptorRead(final BluetoothGatt gatt, final BluetoothGattDescriptor descriptor, final int status) {
            descriptor.setValue(BluetoothGattDescriptor.ENABLE_INDICATION_VALUE);
            gatt.writeDescriptor(descriptor);
        }

        @Override
        public void onCharacteristicChanged(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic) {
            final byte[] value = characteristic.getValue();
            final Command command = Command.byCommandByte(value[0]);
            Log.i(TAG, "Received command: " + command);
            switch (command) {
                case NEW_IMAGE_INFO_REQUEST:
                    controlPoint.setValue(image.getNewImageInfoResponse());
                    gatt.writeCharacteristic(controlPoint);
                    Log.i(TAG, "Writing command: NEW_IMAGE_INFO_RESPONSE");
                    final PendingIntent pendingIntent = PendingIntent.getBroadcast(FirmwareUpdateService.this, 0, new Intent(CANCEL_UPDATE), 0);
                    notificationBuilder.addAction(R.drawable.ic_clear_white_24dp, getString(R.string.firmware_update_cancel), pendingIntent);
                    setNotificationText(R.string.firmware_update_start);
                    sendBroadcast(UPDATE_INITIATED);
                    break;
                case IMAGE_BLOCK_REQUEST:
                    final ImageBlockRequest imageBlockRequest = new ImageBlockRequest(value);
                    Log.i(TAG, "Block request is: " + imageBlockRequest);
                    currentBlock = image.getBlock(imageBlockRequest);
                    setProgress(imageBlockRequest.getStartPosition());
                    writeChunk(gatt);
                    break;
                case IMAGE_TRANSFER_COMPLETE:
                    final ImageTransferComplete imageTransferComplete = new ImageTransferComplete(value);
                    Log.i(TAG, "Image transfer completed: " + imageTransferComplete);
                    setNotificationText(R.string.firmware_update_complete);
                    sendBroadcast(UPDATE_FINISHED);
                    stopService();
                    break;
                case ERROR_NOTIFICATION:
                    final ErrorNotification errorNotification = new ErrorNotification(value);
                    Log.e(TAG, "Error during firmware update: " + errorNotification);
                    setNotificationText(R.string.firmware_update_error);
                    sendBroadcast(UPDATE_ERROR);
                    stopService();
                    break;
                default:
                    break;
            }
        }

        @Override
        public void onCharacteristicWrite(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic, final int status) {
            if (characteristic == controlPoint) {
                Log.i(TAG, "Successfully written to control point.");
            } else if (characteristic == data && !currentBlock.isCompleted()) {
                writeChunk(gatt);
            }
        }

        private synchronized void writeChunk(BluetoothGatt gatt) {
            // The first block will block and stop OTAP if the chunks are sent too fast.
            try {
                wait(50);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            Log.v(TAG, "Writing chunk " + currentBlock.getPosition() + " / " + currentBlock.getNumberOfChunks());
            data.setValue(currentBlock.getNextChunk());
            gatt.writeCharacteristic(data);
        }

        private void setProgress(final int value) {
            notificationBuilder.setContentText(getString(R.string.firmware_update_notification_text));
            final int progress = (int) (((double) value / image.getSize()) * 100);
            notificationBuilder.setProgress(100, progress, false);
            notificationBuilder.setOngoing(true);
            notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());

            final Intent progressUpdated = new Intent(UPDATE_PROGRESS);
            progressUpdated.putExtra(UPDATE_PROGRESS_VALUE, progress);
            sendBroadcast(progressUpdated);
        }

        private void setNotificationText(final int stringResource) {
            notificationBuilder.setContentText(FirmwareUpdateService.this.getString(stringResource));
            notificationBuilder.setProgress(0, 0, false);
            notificationBuilder.setOngoing(false);
            notificationManager.notify(NOTIFICATION_ID, notificationBuilder.build());
        }
    }

    public class ServiceBinder extends Binder {

        private FirmwareUpdateService service;

        public ServiceBinder(final FirmwareUpdateService service) {
            this.service = service;
        }

        public FirmwareUpdateService getService() {
            return service;
        }
    }

}
