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

package com.wolkabout.hexiwear.fragment;

import android.content.Intent;
import android.content.SharedPreferences;
import android.preference.Preference;
import android.preference.PreferenceFragment;
import android.preference.SwitchPreference;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import com.wolkabout.hexiwear.BuildConfig;
import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.activity.SettingsActivity;
import com.wolkabout.hexiwear.model.HexiwearDevice;
import com.wolkabout.hexiwear.service.BluetoothService;
import com.wolkabout.hexiwear.service.BluetoothService_;
import com.wolkabout.hexiwear.util.HexiwearDevices;
import com.wolkabout.wolkrestandroid.Credentials_;

import org.androidannotations.annotations.AfterPreferences;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EFragment;
import org.androidannotations.annotations.PreferenceByKey;
import org.androidannotations.annotations.PreferenceScreen;
import org.androidannotations.annotations.sharedpreferences.Pref;

import java.util.Map;


@PreferenceScreen(R.xml.pref_hexiwear_settings)
@EFragment
public class HexiwearSettingsFragment extends PreferenceFragment implements SharedPreferences.OnSharedPreferenceChangeListener, Preference.OnPreferenceChangeListener {

    private static final String TAG = HexiwearSettingsFragment.class.getSimpleName();

    @Bean
    HexiwearDevices hexiwearDevices;

    @PreferenceByKey(R.string.preferences_manufacturer_info)
    Preference manufacturerInfo;

    @PreferenceByKey(R.string.preferences_fw_version)
    Preference fwVersion;

    @PreferenceByKey(R.string.preferences_publish_interval_key)
    Preference publishInterval;

    @PreferenceByKey(R.string.preferences_keep_alive_key)
    SwitchPreference keepAlive;

    @PreferenceByKey(R.string.preferences_publish_key)
    SwitchPreference publish;

    @PreferenceByKey(R.string.preferences_app_version)
    Preference appVersion;

    @Pref
    Credentials_ credentials;

    private HexiwearDevice device;
    private Map<String, Boolean> displayPreferences;

    @AfterPreferences
    void initPrefs() {
        SettingsActivity settingsActivity = (SettingsActivity) getActivity();
        device = settingsActivity.device;
        displayPreferences = hexiwearDevices.getDisplayPreferences(device.getDeviceAddress());

        for (Map.Entry<String, Boolean> entry : displayPreferences.entrySet()) {
            Log.d(TAG, "Key: " + entry.getKey() + " value " + entry.getValue());
            final SwitchPreference displayPref = (SwitchPreference) findPreference(entry.getKey());
            if (displayPref != null) {
                displayPref.setChecked(entry.getValue());
                displayPref.setOnPreferenceChangeListener(this);
            }
        }

        final String interval = String.format(getActivity().getString(R.string.preferences_publish_interval_value), hexiwearDevices.getPublishInterval(device));
        publishInterval.setSummary(interval);
        publishInterval.setOnPreferenceChangeListener(this);
        keepAlive.setChecked(hexiwearDevices.shouldKeepAlive(device));
        keepAlive.setOnPreferenceChangeListener(this);
        publish.setChecked(hexiwearDevices.shouldTransmit(device));
        publish.setOnPreferenceChangeListener(this);
        manufacturerInfo.setSummary(settingsActivity.manufacturerInfo.manufacturer);
        fwVersion.setSummary(settingsActivity.manufacturerInfo.firmwareRevision);
        appVersion.setSummary(BuildConfig.VERSION_NAME + "." + BuildConfig.FLAVOR.toUpperCase());
        getPreferenceScreen().getSharedPreferences().registerOnSharedPreferenceChangeListener(this);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        final boolean isDemo = credentials.username().get().equals("Demo");
        if (preference == publishInterval) {
            if (isDemo) {
                return true;
            }

            Log.d(TAG, "Publishing time changed. New value is: " + newValue);
            hexiwearDevices.setPublishInterval(device, Integer.valueOf((String) newValue));
            final String interval = String.format(getActivity().getString(R.string.preferences_publish_interval_value), hexiwearDevices.getPublishInterval(device));
            publishInterval.setSummary(interval);
            LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(new Intent(BluetoothService.PUBLISH_TIME_CHANGED));
        } else if (preference == keepAlive) {
            Log.d(TAG, "Keep alive changed. New value: " + newValue);
            final boolean shouldKeepAlive = (boolean) newValue;
            hexiwearDevices.setKeepAlive(device, shouldKeepAlive);
            if (shouldKeepAlive) {
                BluetoothService_.intent(getActivity()).start();
            } else {
                BluetoothService_.intent(getActivity()).stop();
            }
        } else if (preference == publish) {
            if (isDemo) {
                return true;
            }

            Log.d(TAG, "Should publish changed. New value: " + newValue);
            hexiwearDevices.toggleTracking(device);
            LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(new Intent(BluetoothService.SHOULD_PUBLISH_CHANGED));
        } else {
            Log.d(TAG, "Key: " + preference.getKey() + " value " + newValue);
            displayPreferences.put(preference.getKey(), (Boolean) newValue);
            hexiwearDevices.setDisplayPreferences(device.getDeviceAddress(), displayPreferences);

            final Intent preferenceChanged = new Intent(BluetoothService.PREFERENCE_CHANGED);
            preferenceChanged.putExtra(BluetoothService.PREFERENCE_NAME, preference.getKey());
            preferenceChanged.putExtra(BluetoothService.PREFERENCE_ENABLED, (boolean) newValue);
            LocalBroadcastManager.getInstance(getActivity()).sendBroadcast(preferenceChanged);
        }

        return true;
    }

    @Override
    public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
        // Preferences are changed on this screen only.
    }
}
