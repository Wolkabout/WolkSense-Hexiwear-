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

package com.wolkabout.hexiwear.activity;

import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;

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
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.rest.spring.annotations.RestService;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpStatusCodeException;

@EActivity(R.layout.activity_reset_password)
public class ResetPasswordActivity extends AppCompatActivity {

    private static final String TAG = ResetPasswordActivity.class.getSimpleName();

    @ViewById
    Input email;

    @ViewById
    ProgressBar progressBar;

    @ViewById
    Button resetPassword;

    @Bean
    Dialog dialog;

    @RestService
    AuthenticationService authenticationService;

    @Click
    @EditorAction(R.id.email)
    @Background
    void resetPassword() {
        if (email.isEmpty()) {
            email.setError(R.string.registration_error_email_required);
            return;
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email.getValue()).matches()) {
            email.setError(R.string.registration_error_invalid_email);
            return;
        }

        submitResetPassword();
    }

    @Background
    void submitResetPassword() {
        showResetPending();
        try {
            authenticationService.resetPassword(new ResetPasswordRequest(email.getValue()));
            hideResetPending();
            showInfoDialog(R.string.reset_password_success);
        } catch (HttpStatusCodeException e) {
            Log.e(TAG, "Couldn't reset password", e);
            hideResetPending();
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                showWarningDialog(R.string.reset_password_no_such_email_error);
                return;
            }

            showWarningDialog(R.string.reset_password_error);
        } catch (Exception e) {
            Log.e(TAG, "Couldn't reset password", e);
            hideResetPending();
            showWarningDialog(R.string.reset_password_error);
        }
    }

    @UiThread
    void showWarningDialog(int messageRes) {
        if (dialog == null) {
            return;
        }

        dialog.showWarning(messageRes);
    }

    @UiThread
    void showInfoDialog(int messageRes) {
        if (dialog == null) {
            return;
        }

        dialog.showInfo(messageRes, true);
    }

    @UiThread
    void showResetPending() {
        if (progressBar == null || resetPassword == null) {
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        resetPassword.setEnabled(false);
    }

    @UiThread
    void hideResetPending() {
        if (progressBar == null || resetPassword == null) {
            return;
        }

        progressBar.setVisibility(View.INVISIBLE);
        resetPassword.setEnabled(true);
    }

}
