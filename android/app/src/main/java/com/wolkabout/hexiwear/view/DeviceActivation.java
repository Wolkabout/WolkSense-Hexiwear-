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

package com.wolkabout.hexiwear.view;

import android.content.Context;
import android.text.TextUtils;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.adapter.HexiwearListAdapter;
import com.wolkabout.hexiwear.model.HexiwearDevice;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.ItemClick;
import org.androidannotations.annotations.ViewById;

import java.util.List;

@EViewGroup(R.layout.view_register_device)
public class DeviceActivation extends LinearLayout {

    @ViewById
    TextView serialField;

    @ViewById
    Input deviceName;

    @ViewById
    ListView hexiwearDevices;

    @Bean
    HexiwearListAdapter adapter;

    public DeviceActivation(Context context) {
        super(context);
    }

    @AfterViews
    void setDeviceList() {
        hexiwearDevices.setChoiceMode(ListView.CHOICE_MODE_SINGLE);
        hexiwearDevices.setAdapter(adapter);
        hexiwearDevices.setItemChecked(0, true);
    }

    public void setDevices(List<HexiwearDevice> devices) {
        adapter.update(devices);
    }

    public boolean isNewDeviceSelected() {
        return deviceName.isEnabled();
    }

    public String getDeviceSerial() {
        return serialField.getText().toString();
    }

    public String getWolkName() {
        return deviceName.getValue();
    }

    @ItemClick(R.id.hexiwearDevices)
    void onDeviceSelected(HexiwearDevice device) {
        final String wolkName = device.getWolkName();
        final String deviceSerial = device.getDeviceSerial();

        deviceName.setText(TextUtils.isEmpty(wolkName) ? getContext().getString(R.string.activation_dialog_default_name) : wolkName);
        deviceName.setEnabled(TextUtils.isEmpty(deviceSerial));
        serialField.setText(deviceSerial);
    }

}
