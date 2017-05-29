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

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Service;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.ContentObserver;
import android.database.Cursor;
import android.net.Uri;
import android.os.Handler;
import android.os.IBinder;
import android.provider.CallLog;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import org.androidannotations.annotations.AfterInject;
import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.EService;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@EService
public class NotificationService extends Service {

    public static final String MISSED_CALLS_AMOUNT_CHANGED = "missedCallsAmountChanged";
    public static final String UNREAD_MESSAGES_AMOUNT_CHANGED = "unreadMessagesAmountChanged";
    public static final String UNREAD_EMAILS_AMOUNT_CHANGED = "unreadEmailsAmountChanged";
    public static final String VALUE = "value";

    private static final String TAG = NotificationService.class.getSimpleName();
    private static final int UNREAD_EMAILS_COLUMN_NUMBER = 5;

    private final List<ContentObserver> contentObservers = new ArrayList<>();
    private final Map<String, Integer> unreadEmailCounts = new HashMap<>();
    private int numberOfMissedCalls = -1;
    private int numberOfUnreadMessages = -1;

    @Override
    public void onDestroy() {
        Log.i(TAG, "Shutting down. Unregistering all observers...");
        for (ContentObserver contentObserver : contentObservers) {
            getContentResolver().unregisterContentObserver(contentObserver);
        }
        contentObservers.clear();
        super.onDestroy();
    }

    @AfterInject
    void setMissedCallObserver() {
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return;
        }

        checkMissedCallsCount();
        final ContentObserver contentObserver = new ContentObserver(new Handler()) {
            public void onChange(boolean selfChange) {
                checkMissedCallsCount();
            }
        };
        Log.i(TAG, "Observing missed calls.");
        contentObservers.add(contentObserver);
        getContentResolver().registerContentObserver(CallLog.Calls.CONTENT_URI, true, contentObserver);
    }

    @Background
    void checkMissedCallsCount() {
        final Cursor cursor = getContentResolver().query(CallLog.Calls.CONTENT_URI, null, CallLog.Calls.TYPE + " = ? AND " + CallLog.Calls.NEW + " = ?", new String[]{Integer.toString(CallLog.Calls.MISSED_TYPE), "1"}, CallLog.Calls.DATE + " DESC ");
        if (cursor != null) {
            final int count = cursor.getCount();
            if (numberOfMissedCalls != count) {
                numberOfMissedCalls = count;
                Log.d(TAG, "Missed calls: " + count);
                notifyValueChanged(MISSED_CALLS_AMOUNT_CHANGED, count);
            }
            cursor.close();
        }
    }

    @AfterInject
    void setUnreadMessageObserver() {
        if (!getPackageManager().hasSystemFeature(PackageManager.FEATURE_TELEPHONY)) {
            return;
        }

        checkUnreadMessageCount();
        final ContentObserver contentObserver = new ContentObserver(new Handler()) {
            public void onChange(boolean selfChange) {
                checkUnreadMessageCount();
            }
        };
        Log.i(TAG, "Observing unread messages.");
        contentObservers.add(contentObserver);
        getContentResolver().registerContentObserver(Uri.parse("content://sms/"), true, contentObserver);
    }

    @Background
    void checkUnreadMessageCount() {
        final Cursor cursor = getContentResolver().query(Uri.parse("content://sms/"), null, "read = 0", null, null);
        if (cursor != null) {
            final int count = cursor.getCount();
            if (numberOfUnreadMessages != count) {
                numberOfUnreadMessages = count;
                Log.d(TAG, "Unread messages: " + count);
                notifyValueChanged(UNREAD_MESSAGES_AMOUNT_CHANGED, count);
            }
            cursor.close();
        }
    }

    @AfterInject
    void setUnreadEmailsObserver() {
        final Account[] accounts = AccountManager.get(this).getAccounts();
        for (final Account account : accounts) {
            unreadEmailCounts.put(account.name, -1);
            checkUnreadEmailCount(account);
            final ContentObserver contentObserver = new ContentObserver(new Handler()) {
                public void onChange(boolean selfChange) {
                    checkUnreadEmailCount(account);
                }
            };
            Log.i(TAG, "Observing unread emails for " + account.name);
            contentObservers.add(contentObserver);
            getContentResolver().registerContentObserver(getEmailQuery(account), true, contentObserver);
        }
    }

    @Background
    void checkUnreadEmailCount(Account account) {
        final Cursor cursor = getContentResolver().query(getEmailQuery(account), null, null, null, null);
        if (cursor != null) {
            if (cursor.moveToFirst()) {
                final int count = cursor.getInt(UNREAD_EMAILS_COLUMN_NUMBER);
                if (unreadEmailCounts.get(account.name) != count) {
                    unreadEmailCounts.put(account.name, cursor.getInt(5));
                    Log.d(TAG, "Unread emails: " + count);
                    notifyValueChanged(UNREAD_EMAILS_AMOUNT_CHANGED, count);
                }
            }
            cursor.close();
        }
    }

    private Uri getEmailQuery(final Account account) {
        return Uri.parse("content://com.google.android.gm/" + account.name + "/labels");
    }

    private void notifyValueChanged(final String type, final int newValue) {
        final Intent valueChanged = new Intent(type);
        valueChanged.putExtra(VALUE, newValue);
        LocalBroadcastManager.getInstance(this).sendBroadcast(valueChanged);
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
