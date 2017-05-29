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
import android.support.design.widget.TextInputLayout;
import android.support.v4.content.ContextCompat;
import android.text.InputFilter;
import android.text.InputType;
import android.text.TextUtils;
import android.text.method.PasswordTransformationMethod;
import android.util.AttributeSet;
import android.view.inputmethod.EditorInfo;
import android.widget.TextView;

import com.wolkabout.hexiwear.R;

import org.androidannotations.annotations.AfterTextChange;
import org.androidannotations.annotations.AfterViews;
import org.androidannotations.annotations.EViewGroup;
import org.androidannotations.annotations.UiThread;
import org.androidannotations.annotations.ViewById;

@EViewGroup(R.layout.view_input)
public class Input extends TextInputLayout {

    @ViewById
    TextView text;

    private String defaultText;
    private String hint;
    private int drawable;
    private int maxLength;
    private int textColor;
    private String actionLabel;
    private Type type;

    public Input(final Context context, final AttributeSet attrs) {
        super(context, attrs);
        final TypedArray typedArray = context.obtainStyledAttributes(attrs, R.styleable.Input);
        defaultText = typedArray.getString(R.styleable.Input_text);
        hint = typedArray.getString(R.styleable.Input_hint);
        drawable = typedArray.getResourceId(R.styleable.Input_drawable, 0);
        maxLength = typedArray.getResourceId(R.styleable.Input_maxLength, 100);
        actionLabel = typedArray.getString(R.styleable.Input_actionLabel);
        textColor = typedArray.getColor(R.styleable.Input_textColor, ContextCompat.getColor(getContext(), R.color.primary_text));

        final int typeOrdinal = typedArray.getInt(R.styleable.Input_type, InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);
        type = Type.byOrdinal(typeOrdinal);

        typedArray.recycle();
    }

    @AfterViews
    void init() {
        setHint(hint);
        text.setCompoundDrawablesWithIntrinsicBounds(drawable, 0, 0, 0);
        text.setFilters(new InputFilter[]{new InputFilter.LengthFilter(maxLength)});
        text.setInputType(type.flag);
        text.setTextColor(textColor);

        if (!TextUtils.isEmpty(defaultText)) {
            text.setText(defaultText);
        }

        if (type == Type.PASSWORD) {
            text.setTransformationMethod(PasswordTransformationMethod.getInstance());
            setPasswordVisibilityToggleEnabled(true);
        }

        if (!TextUtils.isEmpty(actionLabel)) {
            text.setImeActionLabel(actionLabel, EditorInfo.IME_ACTION_UNSPECIFIED);
        }
    }

    public void setText(String value) {
        text.setText(value);
    }

    public void setText(int stringResource) {
        text.setText(getContext().getString(stringResource));
    }

    public String getValue() {
        return text.getText().toString();
    }

    public boolean isEmpty() {
        return text.getText().toString().isEmpty();
    }

    @UiThread
    public void clear() {
        text.setText("");
    }

    @UiThread
    public void setError(String error) {
        setErrorEnabled(true);
        super.setError(error);
        text.requestFocus();
    }

    @UiThread
    public void setError(int errorResource) {
        setErrorEnabled(true);
        super.setError(getContext().getString(errorResource));
        text.requestFocus();
    }

    @UiThread
    public void clearError() {
        if (!isErrorEnabled()) {
            return;
        }

        setErrorEnabled(false);
        super.setError(null);
    }

    @AfterTextChange(R.id.text)
    void clearErrorOnTextChange() {
        clearError();
    }

    public void setPasswordVisibility(boolean visible) {
        text.setTransformationMethod(visible ? null : PasswordTransformationMethod.getInstance());
    }

    public void setOnEditorActionListener(TextView.OnEditorActionListener listener) {
        text.setOnEditorActionListener(listener);
    }

    @Override
    public void setEnabled(boolean enabled) {
        text.setEnabled(enabled);
        super.setEnabled(enabled);
    }

    private enum Type {
        NAME(InputType.TYPE_TEXT_VARIATION_PERSON_NAME | InputType.TYPE_TEXT_FLAG_CAP_WORDS),
        TEXT(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS),
        EMAIL(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS),
        PASSWORD(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD),
        NUMBER(InputType.TYPE_CLASS_NUMBER);

        private int flag;

        Type(int flag) {
            this.flag = flag;
        }

        static Type byOrdinal(int ordinal) {
            return Type.values()[ordinal];
        }
    }

}