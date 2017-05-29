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

import android.content.Context;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Checkable;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.HexiwearDevice;

import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

import java.util.ArrayList;
import java.util.List;

@EBean
public class HexiwearListAdapter extends BaseAdapter {

    private final List<HexiwearDevice> devices = new ArrayList<>();

    @RootContext
    Context context;

    @Override
    public int getCount() {
        return devices.size();
    }

    @Override
    public HexiwearDevice getItem(int position) {
        return devices.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        HexiwearItemView hexiwearItemView;
        if (convertView == null) {
            hexiwearItemView = HexiwearListAdapter_.HexiwearItemView_.build(context);
        } else {
            hexiwearItemView = (HexiwearItemView) convertView;
        }
        hexiwearItemView.bind(getItem(position));
        return hexiwearItemView;
    }

    @UiThread
    public void update(List<HexiwearDevice> devices) {
        this.devices.clear();
        this.devices.add(new HexiwearDevice());
        this.devices.addAll(devices);
        notifyDataSetChanged();
    }

    @EViewGroup(R.layout.item_hexiwear)
    static class HexiwearItemView extends LinearLayout implements Checkable {

        @ViewById
        ImageView icon;

        @ViewById
        TextView deviceName;

        private boolean checked;

        public HexiwearItemView(final Context context) {
            super(context);
        }

        public void bind(HexiwearDevice device) {
            final String wolkName = device.getWolkName();
            final boolean isNewDevice = TextUtils.isEmpty(wolkName);
            deviceName.setText(isNewDevice ? getContext().getString(R.string.activation_dialog_new_device) : wolkName);
        }

        @Override
        public void setChecked(final boolean checked) {
            this.checked = checked;
            onCheckedChanged();
        }

        @Override
        public boolean isChecked() {
            return checked;
        }

        @Override
        public void toggle() {
            checked = !checked;
            onCheckedChanged();
        }

        private void onCheckedChanged() {
            icon.setBackgroundResource(checked ? R.drawable.ic_arrow_forward_black_24dp : 0);
        }
    }

}
