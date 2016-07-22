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

package com.wolkabout.hexiwear.activity;

import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.view.Input;
import com.wolkabout.wolkrestandroid.Credentials_;
import com.wolkabout.wolkrestandroid.dto.ChangePasswordRequest;
import com.wolkabout.wolkrestandroid.service.AuthenticationService;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.sharedpreferences.Pref;
import org.androidannotations.rest.spring.annotations.RestService;

@EActivity(R.layout.activity_password_change)
public class PasswordChangeActivity extends AppCompatActivity {

    @ViewById
    Toolbar toolbar;

    @ViewById
    Input currentPassword;

    @ViewById
    Input newPassword;

    @Bean
    Dialog dialog;

    @Pref
    Credentials_ credentials;

    @RestService
    AuthenticationService authenticationService;

    @AfterViews
    void init() {
        setSupportActionBar(toolbar);
    }

    @Click
    @Background
    void changePassword() {
        if (!validate()) {
            return;
        }

        try {
            final ChangePasswordRequest requestDto = new ChangePasswordRequest(credentials.username().get(), currentPassword.getValue(), newPassword.getValue());
            authenticationService.changePassword(requestDto);
            onPasswordChanged(requestDto);
        } catch (Exception e) {
            dialog.showWarning(R.string.change_password_error);
        }
    }

    @UiThread
    void onPasswordChanged(ChangePasswordRequest requestDto) {
        currentPassword.clear();
        newPassword.clear();
        dialog.showInfo(R.string.change_password_success, false);
    }

    private boolean validate() {
        if (newPassword.isEmpty()) {
            newPassword.setError(R.string.registration_error_field_required);
            return false;
        }

        if (newPassword.getValue().length() < 8) {
            newPassword.setError(R.string.registration_error_invalid_password);
            return false;
        }

        return true;
    }

}
