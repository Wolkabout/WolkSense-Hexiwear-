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

package com.wolkabout.hexiwear;

import android.app.Application;
import android.content.Intent;

import com.wolkabout.hexiwear.activity.LoginActivity_;
import com.wolkabout.wolkrestandroid.Credentials_;
import com.wolkabout.wolkrestandroid.DefaultErrorHandler;

import org.androidannotations.annotations.AfterInject;
import org.androidannotations.annotations.Bean;
import org.androidannotations.annotations.EApplication;
import org.androidannotations.annotations.sharedpreferences.Pref;

@EApplication
public class HexiwearApplication extends Application {

    @Pref
    Credentials_ credentials;

    @Bean
    DefaultErrorHandler defaultErrorHandler;

    @AfterInject
    void setUpServices() {
        defaultErrorHandler.setErrorHandler(new DefaultErrorHandler.ErrorHandler() {
            @Override
            public void onAuthenticationError() {
                if (credentials.username().get().equals("Demo")) {
                    return;
                }

                LoginActivity_.intent(HexiwearApplication.this).flags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK).start();
            }
        });
    }

}
