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
import android.text.method.LinkMovementMethod;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.view.Input;
import com.wolkabout.wolkrestandroid.dto.SignUpDto;
import com.wolkabout.wolkrestandroid.service.AuthenticationService;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.rest.spring.annotations.RestService;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpStatusCodeException;

@EActivity(R.layout.activity_sign_up)
public class SignUpActivity extends AppCompatActivity {

    @ViewById
    Input emailField;

    @ViewById
    Input passwordField;

    @ViewById
    Input confirmPasswordField;

    @ViewById
    Input firstNameField;

    @ViewById
    Input lastNameField;

    @ViewById
    CheckBox termsAndConditions;

    @ViewById
    TextView privacyPolicy;

    @ViewById
    TextView licenceTerms;

    @ViewById
    LinearLayout signingUp;

    @ViewById
    Button signUpButton;

    @Bean
    Dialog dialog;

    @RestService
    AuthenticationService authenticationService;

    @AfterViews
    void init() {
        privacyPolicy.setMovementMethod(LinkMovementMethod.getInstance());
        licenceTerms.setMovementMethod(LinkMovementMethod.getInstance());
    }

    @Click(R.id.signUpButton)
    void signUp() {
        if (!validate()) {
            return;
        }

        if (!termsAndConditions.isChecked()) {
            Toast.makeText(this, R.string.registration_accept_terms, Toast.LENGTH_LONG).show();
            return;
        }

        signUpButton.setEnabled(false);
        signingUp.setVisibility(View.VISIBLE);
        startSignUp();
    }

    @Background
    void startSignUp() {
        final SignUpDto signUpDto = parseUserInput();
        try {
            authenticationService.signUp(signUpDto);
            onSignUpSuccess();
        } catch (HttpStatusCodeException e) {
            if (e.getStatusCode() == HttpStatus.BAD_REQUEST && e.getResponseBodyAsString().contains("USER_EMAIL_IS_NOT_UNIQUE")) {
                onSignUpError(R.string.registration_error_email_already_exists);
                return;
            }

            onSignUpError(R.string.registration_failed);
        } catch (Exception e) {
            onSignUpError(R.string.registration_failed);
        } finally {
            dismissSigningUpLabel();
        }
    }

    @UiThread
    void dismissSigningUpLabel() {
        if (signUpButton == null || signingUp == null) {
            return;
        }

        signUpButton.setEnabled(true);
        signingUp.setVisibility(View.GONE);
    }

    @UiThread
    void onSignUpSuccess() {
        if (dialog == null) {
            return;
        }

        dialog.showInfo(R.string.registration_success, true);
    }

    @UiThread
    void onSignUpError(int messageRes) {
        dialog.showWarning(messageRes);
    }

    private boolean validate() {
        if (emailField.isEmpty()) {
            emailField.setError(R.string.registration_error_email_required);
            return false;
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(emailField.getValue()).matches()) {
            emailField.setError(R.string.registration_error_invalid_email);
            return false;
        }

        if (passwordField.isEmpty()) {
            passwordField.setError(R.string.registration_error_password_required);
            return false;
        }

        if (passwordField.getValue().length() < 8) {
            passwordField.setError(R.string.registration_error_short_password);
            return false;
        }

        if (confirmPasswordField.isEmpty()) {
            confirmPasswordField.setError(R.string.registration_confirm_password_error);
            return false;
        }

        if (!passwordField.getValue().equals(confirmPasswordField.getValue())) {
            confirmPasswordField.setError(R.string.registration_password_mismatch_error);
            return false;
        }

        if (firstNameField.isEmpty()) {
            firstNameField.setError(R.string.registration_error_first_name_required);
            return false;
        }

        if (lastNameField.isEmpty()) {
            lastNameField.setError(R.string.registration_error_last_name_required);
            return false;
        }

        return true;
    }

    private SignUpDto parseUserInput() {
        final String email = emailField.getValue();
        final String password = passwordField.getValue();
        final String firstName = firstNameField.getValue();
        final String lastName = lastNameField.getValue();
        return new SignUpDto(email, password, firstName, lastName);
    }

}
