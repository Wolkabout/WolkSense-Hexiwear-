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

package com.wolkabout.hexiwear.util;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.view.Input;

import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.UiThread;


@EBean
public class Dialog {

    @RootContext
    Activity activity;

    @UiThread
    public void showWarning(final int stringResource){
        final AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setPositiveButton(activity.getString(R.string.dismiss), new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                dialog.dismiss();
            }
        });
        builder.setMessage(activity.getString(stringResource));
        builder.show();
    }

    @UiThread
    public void showInfo(final int stringResource, final boolean finishActivity){
        final AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setPositiveButton(activity.getString(R.string.ok), new DialogInterface.OnClickListener() {
            @Override
            public void onClick(final DialogInterface dialog, final int which) {
                if (finishActivity) {
                    activity.finish();
                }
            }
        });
        builder.setMessage(activity.getString(stringResource));
        builder.show();
    }

}
