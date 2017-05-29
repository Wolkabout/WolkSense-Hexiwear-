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
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.util.Dialog;
import com.wolkabout.hexiwear.view.Input;
import com.wolkabout.wolkrestandroid.Credentials_;
import com.wolkabout.wolkrestandroid.dto.AuthenticationResponseDto;
import com.wolkabout.wolkrestandroid.dto.EmailVerificationRequest;
import com.wolkabout.wolkrestandroid.dto.SignInDto;
import com.wolkabout.wolkrestandroid.service.AuthenticationService;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.Background;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.Click;
import org.androidannotations.annotations.EActivity;
import org.androidannotations.annotations.EditorAction;
import org.androidannotations.annotations.SystemService;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;
import org.androidannotations.annotations.sharedpreferences.Pref;
import org.androidannotations.rest.spring.annotations.RestService;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpStatusCodeException;

@EActivity(R.layout.activity_login)
public class LoginActivity extends AppCompatActivity {

    public static final String TAG = LoginActivity.class.getSimpleName();

    @ViewById
    Input emailField;

    @ViewById
    Input passwordField;

    @ViewById
    View signInElements;

    @ViewById
    TextView signingInLabel;

    @ViewById
    View signingInElements;

    @ViewById
    Button signInButton;

    @Pref
    Credentials_ credentials;

    @SystemService
    InputMethodManager inputMethodManager;

    @Bean
    Dialog dialog;

    @RestService
    AuthenticationService authenticationService;

    @Override
    protected void onResume() {
        super.onResume();
        String dataString = getIntent().getDataString();
        Log.i(TAG, "Data string: " + dataString);
        if (dataString != null && dataString.contains("activationCode=")) {
            Log.i(TAG, "Activate");
            verifyEmail(dataString.substring(dataString.indexOf('=') + 1));
        }
    }

    @AfterViews
    void startMainActivity() {
        if (credentials.username().exists() && !credentials.username().get().equals("Demo")) {
            MainActivity_.intent(this).start();
            finish();
        }
    }

    @Click(R.id.signUp)
    void openSignUpScreen() {
        SignUpActivity_.intent(this).start();
    }

    @Click(R.id.signInButton)
    @EditorAction(R.id.passwordField)
    void attemptSignIn() {
        if ("demo".equals(emailField.getValue()) && "demo".equals(passwordField.getValue())) {
            credentials.username().put("Demo");
            MainActivity_.intent(LoginActivity.this).start();
            finish();
            return;
        }

        if (!validateCredentials()) {
            return;
        }

        inputMethodManager.hideSoftInputFromWindow(passwordField.getWindowToken(), 0);

        signInElements.setVisibility(View.GONE);
        signingInElements.setVisibility(View.VISIBLE);

        signIn();
    }

    @Background
    void signIn() {
        try {
            final String emailAddress = emailField.getValue();
            final String password = passwordField.getValue();

            final AuthenticationResponseDto response = authenticationService.signIn(new SignInDto(emailAddress, password));
            credentials.username().put(response.getEmail());
            credentials.accessToken().put(response.getAccessToken());
            credentials.refreshToken().put(response.getRefreshToken());
            credentials.accessTokenExpires().put(response.getAccessTokenExpires().getTime());
            credentials.refreshTokenExpires().put(response.getRefreshTokenExpires().getTime());
            MainActivity_.intent(LoginActivity.this).start();
            finish();
        } catch (HttpStatusCodeException e) {
            Log.e(TAG, "signIn: ", e);
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                onSignInError(R.string.login_error_invalid_credentials);
                return;
            }

            onSignInError(R.string.login_error_general);
        } catch (Exception e) {
            Log.e(TAG, "signIn: ", e);
            onSignInError(R.string.login_error_general);
        }
    }

    @UiThread
    void onSignInError(int messageRes) {
        signInElements.setVisibility(View.VISIBLE);
        signingInElements.setVisibility(View.GONE);
        dialog.showWarning(messageRes);
    }

    @Click
    void resetPassword() {
        ResetPasswordActivity_.intent(this).start();
    }

    private boolean validateCredentials() {
        if (emailField.isEmpty()) {
            emailField.setError(R.string.registration_error_email_required);
            return false;
        }

        if (passwordField.isEmpty()) {
            passwordField.setError(R.string.registration_error_password_required);
            return false;
        }

        if (!android.util.Patterns.EMAIL_ADDRESS.matcher(emailField.getValue()).matches()) {
            emailField.setError(R.string.registration_error_invalid_email);
            return false;
        }

        return true;
    }

    @Background
    void verifyEmail(String code) {
        try {
            Log.i(TAG, "Verifying email - code: " + code);
            final EmailVerificationRequest request = new EmailVerificationRequest(code);
            authenticationService.verifyEmail(request);
            Toast.makeText(LoginActivity.this, "Email verified.", Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            Toast.makeText(LoginActivity.this, "Failed to verify email.", Toast.LENGTH_LONG).show();
        }
    }

}
