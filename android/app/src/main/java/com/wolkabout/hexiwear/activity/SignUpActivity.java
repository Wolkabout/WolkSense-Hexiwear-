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

@EActivity(R.layout.activity_sign_up)
public class SignUpActivity extends AppCompatActivity {

    @ViewById
    Input emailField;

    @ViewById
    Input passwordField;

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
            acceptTermsAndConditions();
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
        } catch (Exception e) {
            onSignUpError();
        }
        dismissSigningUpLabel();
    }

    @UiThread
    void dismissSigningUpLabel() {
        signUpButton.setEnabled(true);
        signingUp.setVisibility(View.GONE);
    }

    @UiThread
    void acceptTermsAndConditions() {
        Toast.makeText(this, R.string.registration_accept_terms, Toast.LENGTH_LONG).show();
    }

    @UiThread
    void onSignUpSuccess() {
        dialog.showInfo(R.string.registration_success, true);
    }

    @UiThread
    void onSignUpError() {
        Toast.makeText(this, R.string.registration_failed, Toast.LENGTH_LONG).show();
    }

    private boolean validate() {
        if (emailField.isEmpty()) {
            emailField.setError(R.string.registration_error_field_required);
            return false;
        }

        if (passwordField.isEmpty()) {
            passwordField.setError(R.string.registration_error_field_required);
            return false;
        }

        if (passwordField.getValue().length() < 8) {
            passwordField.setError(R.string.registration_error_invalid_password);
            return false;
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(emailField.getValue()).matches()) {
            emailField.setError(R.string.registration_error_invalid_email);
            return false;
        }

        if (firstNameField.isEmpty()) {
            firstNameField.setError(R.string.registration_error_field_required);
            return false;
        }

        if (lastNameField.isEmpty()) {
            lastNameField.setError(R.string.registration_error_field_required);
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
