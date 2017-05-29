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

package com.wolkabout.hexiwear.view;

import android.content.Context;
import android.content.res.TypedArray;
import android.util.AttributeSet;
import android.widget.ImageView;
import android.widget.LinearLayout;

import com.wolkabout.hexiwear.R;
import com.wolkabout.hexiwear.model.Characteristic;

import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.ViewById;

@EViewGroup
public class Reading extends LinearLayout {

    @ViewById
    ImageView image;

    private Characteristic characteristic;
    private int drawable;

    public Reading(final Context context, final AttributeSet attrs) {
        super(context, attrs);
        final TypedArray typedArray = context.obtainStyledAttributes(attrs, R.styleable.Reading);
        drawable = typedArray.getResourceId(R.styleable.Reading_image, 0);
        final int readingTypeOrdinal = typedArray.getInt(R.styleable.Reading_readingType, 0);
        characteristic = Characteristic.byOrdinal(readingTypeOrdinal);
        typedArray.recycle();
    }

    @AfterViews
    void init() {
        image.setImageResource(drawable);
    }

    public Characteristic getReadingType() {
        return characteristic;
    }
}
