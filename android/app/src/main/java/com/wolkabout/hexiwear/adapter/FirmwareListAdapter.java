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
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.otap.Image;

import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@EBean
public class FirmwareListAdapter extends BaseAdapter {

    @RootContext
    Context context;

    private final List<Image> images = new ArrayList<>();

    @Override
    public int getCount() {
        return images.size();
    }

    @Override
    public Image getItem(final int position) {
        return images.get(position);
    }

    @Override
    public long getItemId(final int position) {
        return position;
    }

    @Override
    public View getView(final int position, final View convertView, final ViewGroup parent) {
        FirmwareItemView firmwareItemView;
        if (convertView == null) {
            firmwareItemView = FirmwareListAdapter_.FirmwareItemView_.build(context);
        } else {
            firmwareItemView = (FirmwareItemView) convertView;
        }
        firmwareItemView.bind(getItem(position));
        return firmwareItemView;
    }

    public void clear() {
        images.clear();
        refreshList();
    }

    public void add(final Image image) {
        images.add(image);
        refreshList();
    }

    @UiThread
    void refreshList() {
        notifyDataSetChanged();
    }

    @EViewGroup(R.layout.item_firmware)
    public static class FirmwareItemView extends LinearLayout {

        @ViewById
        TextView fileName;

        @ViewById
        TextView version;

        @ViewById
        TextView type;

        public FirmwareItemView(Context context) {
            super(context);
        }

        void bind(final Image image) {
            fileName.setText(image.getFileName());
            version.setText(formatValue(R.string.firmware_update_version, image.getVersion()));
            type.setText(formatValue(R.string.firmware_update_type, image.getType().name()));
        }

        private String formatValue(final int stringResource, final String value) {
            return String.format(Locale.ENGLISH, getContext().getString(stringResource), value);
        }

    }
}
