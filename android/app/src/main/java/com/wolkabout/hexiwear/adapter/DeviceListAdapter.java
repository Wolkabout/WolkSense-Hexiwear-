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

package com.wolkabout.hexiwear.adapter;

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.BluetoothDeviceWrapper;
import com.wolkabout.hexiwear.model.HexiwearDevice;
import com.wolkabout.hexiwear.util.HexiwearDevices;

import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

import java.util.ArrayList;
import java.util.List;

@EBean
public class DeviceListAdapter extends BaseAdapter {

    private final List<BluetoothDeviceWrapper> devices = new ArrayList<>();

    @RootContext
    Context context;

    @Bean
    static HexiwearDevices hexiwearDevices;

    @Override
    public int getCount() {
        return devices.size();
    }

    @Override
    public BluetoothDeviceWrapper getItem(int position) {
        return devices.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @UiThread
    public void add(BluetoothDeviceWrapper wrapper) {
        for (BluetoothDeviceWrapper deviceWrapper : devices) {
            if (deviceWrapper.getDevice().getAddress().equals(wrapper.getDevice().getAddress())) {
                return;
            }
        }

        devices.add(wrapper);
        notifyDataSetChanged();
    }

    @UiThread
    public void clear() {
        devices.clear();
        notifyDataSetChanged();
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        DeviceItemView deviceItemView;
        if (convertView == null) {
            deviceItemView = DeviceListAdapter_.DeviceItemView_.build(context);
        } else {
            deviceItemView = (DeviceItemView) convertView;
        }
        deviceItemView.bind(getItem(position));
        return deviceItemView;
    }

    @EViewGroup(R.layout.item_device)
    public static class DeviceItemView extends LinearLayout {

        @ViewById
        TextView deviceName;

        @ViewById
        TextView deviceUUID;

        @ViewById
        TextView status;

        @ViewById
        ImageView signalStrength;

        @ViewById
        TextView otapMode;

        public DeviceItemView(Context context) {
            super(context);
        }

        void bind(BluetoothDeviceWrapper wrapper) {
            final BluetoothDevice device = wrapper.getDevice();

            final String name = device.getName();
            final HexiwearDevice hexiwearDevice = hexiwearDevices.getDevice(device.getAddress());
            if (hexiwearDevice != null) {
                deviceName.setText(hexiwearDevice.getWolkName());
            } else if (!TextUtils.isEmpty(name)) {
                deviceName.setText(name);
            } else {
                deviceName.setText(device.getAddress());
            }

            status.setVisibility(device.getBondState() == BluetoothDevice.BOND_BONDED ? VISIBLE : GONE);

            deviceUUID.setText(device.getAddress());
            signalStrength.setImageResource(wrapper.getSignalStrength());
            otapMode.setVisibility(wrapper.isInOtapMode() ? VISIBLE : GONE);
        }

    }

}