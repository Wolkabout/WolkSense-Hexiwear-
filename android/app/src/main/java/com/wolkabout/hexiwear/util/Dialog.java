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

package com.wolkabout.hexiwear.util;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.support.annotation.Nullable;
import android.widget.Toast;

import com.wolkabout.hexiwear.R;

import org.androidannotations.annotations.EBean;
import org.androidannotations.annotations.RootContext;
import org.androidannotations.annotations.SupposeUiThread;
import org.androidannotations.annotations.UiThread;


@EBean
public class Dialog {

    @RootContext
    Activity activity;

    @UiThread
    public void showWarning(final int stringResource) {
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
    public void showInfo(final int stringResource, final boolean finishActivity) {
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

    @UiThread
    public void showConfirmationAndCancel(final String title, final String message, final String positiveActionText,
                                          final DialogInterface.OnClickListener action) {
        showConfirmation(title, message, positiveActionText, activity.getString(R.string.cancel), action, true);
    }

    @UiThread
    public void showConfirmationAndCancel(final int title, final int message, final int positiveActionText,
                                          final DialogInterface.OnClickListener action) {
        showConfirmation(title, message, positiveActionText, R.string.cancel, action, true);
    }

    @UiThread
    public void showConfirmation(final String title, final String message, final String positiveButtonText,
                                 final String negativeButtonText, DialogInterface.OnClickListener listener, boolean cancelable) {
        final AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        builder.setCancelable(cancelable);
        if (title != null) {
            builder.setTitle(title);
        }
        builder.setMessage(message);
        builder.setPositiveButton(positiveButtonText, listener);
        builder.setNegativeButton(negativeButtonText, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                // do nothing
            }
        });

        builder.show();
    }

    @UiThread
    public void showConfirmation(final int title, final int message, final int positiveButtonText,
                                 final int negativeButtonText, DialogInterface.OnClickListener listener, boolean cancelable) {
        showConfirmation(getTitleString(title), activity.getString(message),
                activity.getString(positiveButtonText), activity.getString(negativeButtonText), listener, cancelable);
    }

    @UiThread
    public void shortToast(String text) {
        Toast.makeText(activity, text, Toast.LENGTH_SHORT).show();
    }

    @UiThread
    public void shortToast(int textRes) {
        shortToast(activity.getString(textRes));
    }

    @UiThread
    public void longToast(String text) {
        Toast.makeText(activity, text, Toast.LENGTH_SHORT).show();
    }

    @UiThread
    public void longToast(int textRes) {
        shortToast(activity.getString(textRes));
    }

    @SupposeUiThread
    public ProgressDialog createProgressDialog(String message) {
        final ProgressDialog progressDialog = new ProgressDialog(activity);
        progressDialog.setMessage(message);
        progressDialog.setIndeterminate(true);
        progressDialog.setCancelable(false);
        return progressDialog;
    }

    @SupposeUiThread
    public ProgressDialog createProgressDialog(int messageRes) {
        return createProgressDialog(activity.getString(messageRes));
    }

    @Nullable
    private String getTitleString(int title) {
        return title == 0 ? null : activity.getString(title);
    }
}
