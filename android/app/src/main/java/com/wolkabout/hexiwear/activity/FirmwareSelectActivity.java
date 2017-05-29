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
import android.content.ServiceConnection;
import android.content.res.AssetManager;
import android.os.Environment;
import android.os.IBinder;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.util.Log;
import android.view.View;
import android.widget.ListView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.adapter.FirmwareListAdapter;
import com.wolkabout.hexiwear.model.otap.Image;
import com.wolkabout.hexiwear.service.FirmwareUpdateService;
import com.wolkabout.hexiwear.service.FirmwareUpdateService_;
import com.wolkabout.hexiwear.util.ByteUtils;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.Extra;
import org.androidannotations.annotations.ItemClick;
import org.androidannotations.annotations.Receiver;
import org.androidannotations.annotations.ViewById;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;

@EActivity(R.layout.activity_firmware_select)
public class FirmwareSelectActivity extends AppCompatActivity implements ServiceConnection {

    private static final String TAG = FirmwareSelectActivity.class.getSimpleName();

    private static final String UPDATE_INITIATED = "updateStarted";
    private static final String UPDATE_CANCELED = "updateCanceled";
    private static final String UPDATE_FINISHED = "updateFinished";
    private static final String UPDATE_PROGRESS = "updateProgress";
    private static final String UPDATE_ERROR = "updateError";

    private static final String HEXIWEAR_PREFIX = "HEXIWEAR";
    private static final String IMAGE_EXTENSION = ".img";
    private static final int PREFIX_LENGTH = 14;
    private static final String FACTORY_SETTINGS = "factory_settings";


    @ViewById
    Toolbar toolbar;

    @ViewById
    ListView firmwareList;

    @Bean
    FirmwareListAdapter adapter;

    @Extra
    BluetoothDevice device;

    private ProgressDialog progressDialog;
    private FirmwareUpdateService firmwareUpdateService;

    @AfterViews
    void init() {
        setSupportActionBar(toolbar);
        firmwareList.setAdapter(adapter);
        addFactorySettingImages();
        discoverFirmwareImages();
        FirmwareUpdateService_.intent(this).start();
        bindService(FirmwareUpdateService_.intent(this).get(), this, 0);
    }

    void addFactorySettingImages() {
        try {
            final AssetManager assetManager = getAssets();
            for (String factorySetting : assetManager.list(FACTORY_SETTINGS)) {
                final InputStream inputStream = assetManager.open(FACTORY_SETTINGS + "/" + factorySetting);
                final String imageName = factorySetting.substring(PREFIX_LENGTH).replace(IMAGE_EXTENSION, "");
                final Image image = new Image(imageName, ByteUtils.readBytes(inputStream));
                adapter.add(image);
            }
        } catch (IOException e) {
            Log.e(TAG, "Couldn't open factory images.", e);
        }
    }

    void discoverFirmwareImages() {
        final File downloadsDirectory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
        for (final File file : downloadsDirectory.listFiles()) {
            if (file.getName().startsWith(HEXIWEAR_PREFIX)) {
                final String imageName = file.getName().substring(PREFIX_LENGTH).replace(IMAGE_EXTENSION, "");
                final Image image = new Image(imageName, ByteUtils.readBytes(file));
                adapter.add(image);
            }
        }
    }

    @ItemClick(R.id.firmwareList)
    void updateFirmware(final Image image) {
        progressDialog = new ProgressDialog(this);
        progressDialog.setTitle(R.string.firmware_update_activity_title);
        progressDialog.setMessage(getString(R.string.firmware_update_start));
        progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
        progressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, getString(R.string.firmware_update_cancel), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(final DialogInterface dialog, final int which) {
                firmwareUpdateService.cancelUpdate();
            }
        });
        progressDialog.setButton(DialogInterface.BUTTON_NEUTRAL, getString(R.string.firmware_update_hide), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(final DialogInterface dialog, final int which) {
                progressDialog.dismiss();
                finish();
            }
        });
        progressDialog.show();

        progressDialog.getButton(DialogInterface.BUTTON_NEUTRAL).setVisibility(View.INVISIBLE);
        firmwareUpdateService.updateFirmware(device, image);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unbindService(this);
        if (progressDialog != null) {
            progressDialog.dismiss();
        }
    }

    @Override
    public void onServiceConnected(final ComponentName name, final IBinder service) {
        final FirmwareUpdateService.ServiceBinder binder = (FirmwareUpdateService.ServiceBinder) service;
        firmwareUpdateService = binder.getService();
    }

    @Override
    public void onServiceDisconnected(final ComponentName name) {
        // Something terrible happened.
    }

    @Receiver(actions = UPDATE_INITIATED, local = true)
    void onUpdateInitiated() {
        progressDialog.setMessage(getString(R.string.firmware_update_in_progress));
        progressDialog.setMax(100);
        progressDialog.getButton(DialogInterface.BUTTON_NEUTRAL).setVisibility(View.VISIBLE);
    }

    @Receiver(actions = UPDATE_PROGRESS, local = true)
    void onUpdateProgress(@Receiver.Extra final int progress) {
        progressDialog.setProgress(progress);
    }

    @Receiver(actions = UPDATE_CANCELED, local = true)
    void onUpdateCanceled() {
        progressDialog.hide();
    }

    @Receiver(actions = UPDATE_FINISHED, local = true)
    void onUpdateFinished() {
        progressDialog.setProgress(100);
        progressDialog.setMessage(getString(R.string.firmware_update_complete));
        progressDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setVisibility(View.INVISIBLE);
    }

    @Receiver(actions = UPDATE_ERROR, local = true)
    void onUpdateError() {
        progressDialog.setMax(0);
        progressDialog.setProgress(0);
        progressDialog.setMessage(getString(R.string.firmware_update_error));
        progressDialog.getButton(DialogInterface.BUTTON_NEGATIVE).setVisibility(View.INVISIBLE);
    }

}
