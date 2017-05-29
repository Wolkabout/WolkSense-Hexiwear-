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
import android.support.v7.widget.Toolbar;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.view.Input;
import com.wolkabout.wolkrestandroid.Credentials_;
import com.wolkabout.wolkrestandroid.dto.ChangePasswordRequest;
import com.wolkabout.wolkrestandroid.service.UserService;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.sharedpreferences.Pref;
import org.androidannotations.rest.spring.annotations.RestService;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpStatusCodeException;

@EActivity(R.layout.activity_password_change)
public class PasswordChangeActivity extends AppCompatActivity {

    @ViewById
    Toolbar toolbar;

    @ViewById
    Input currentPassword;

    @ViewById
    Input newPassword;

    @ViewById
    Input confirmPassword;

    @ViewById
    ProgressBar progressBar;

    @ViewById
    Button changePassword;

    @Bean
    Dialog dialog;

    @Pref
    Credentials_ credentials;

    @RestService
    UserService userService;

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

        showChangePasswordPending();

        try {
            final ChangePasswordRequest requestDto = new ChangePasswordRequest(currentPassword.getValue(), newPassword.getValue());
            userService.changePassword(requestDto);
            onPasswordChanged(requestDto);
        } catch (HttpStatusCodeException e) {
            hideChangePasswordPending();
            if (e.getStatusCode() == HttpStatus.BAD_REQUEST || e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                showWarningDialog(R.string.change_password_old_invalid);
                return;
            }

            showWarningDialog(R.string.change_password_error);
        } catch (Exception e) {
            hideChangePasswordPending();
            showWarningDialog(R.string.change_password_error);
        }
    }

    @UiThread
    void onPasswordChanged(ChangePasswordRequest requestDto) {
        hideChangePasswordPending();
        currentPassword.clear();
        newPassword.clear();
        confirmPassword.clear();
        showInfoDialog(R.string.change_password_success);
    }

    private boolean validate() {
        if (currentPassword.isEmpty()) {
            currentPassword.setError(R.string.change_password_current_is_empty_error);
            return false;
        }

        if (newPassword.getValue().length() < 8) {
            newPassword.setError(R.string.change_password_new_password_length_error);
            return false;
        }

        if (newPassword.isEmpty()) {
            newPassword.setError(R.string.change_password_new_password_required_error);
            return false;
        }

        if (confirmPassword.isEmpty()) {
            confirmPassword.setError(R.string.change_password_confirm_is_empty_error);
            return false;
        }

        if (!confirmPassword.getValue().equals(newPassword.getValue())) {
            confirmPassword.setError(R.string.change_password_mismatch_error);
            return false;
        }

        return true;
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
    void showChangePasswordPending() {
        if (progressBar == null || changePassword == null) {
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        changePassword.setEnabled(false);
    }

    @UiThread
    void hideChangePasswordPending() {
        if (progressBar == null || changePassword == null) {
            return;
        }

        progressBar.setVisibility(View.INVISIBLE);
        changePassword.setEnabled(true);
    }

}
