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
import android.util.Log;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.view.Input;
import com.wolkabout.wolkrestandroid.dto.ResetPasswordRequest;
import com.wolkabout.wolkrestandroid.service.AuthenticationService;

import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.EditorAction;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.rest.spring.annotations.RestService;

@EActivity(R.layout.activity_reset_password)
public class ResetPasswordActivity extends AppCompatActivity {

    private static final String TAG = ResetPasswordActivity.class.getSimpleName();

    @ViewById
    Input email;

    @Bean
    Dialog dialog;

    @RestService
    AuthenticationService authenticationService;

    @Click
    @EditorAction(R.id.email)
    @Background
    void resetPassword() {
        try {
            authenticationService.resetPassword(new ResetPasswordRequest(email.getValue()));
            dialog.showInfo(R.string.reset_password_success, true);
        } catch (Exception e) {
            Log.e(TAG, "Couldn't reset password", e);
            dialog.showWarning(R.string.reset_password_error);
        }
    }

}
