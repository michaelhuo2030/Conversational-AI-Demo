package io.agora.agent.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;

import java.util.Set;

import io.agora.agent.MApp;

public class SPUtil {
    private final static String PREFERENCES_NAME = "PREF_ONE_TO_ONE";

    private SPUtil() {
    }

    private static final class MInstanceHolder {
        static final SharedPreferences mInstance = MApp.instance().getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE);
    }

    private static SharedPreferences getSharedPreference() {
        return MInstanceHolder.mInstance;
    }

    public static boolean putBoolean(String key, Boolean value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putBoolean(key, value);
        return editor.commit();
    }

    public static boolean putInt(String key, int value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putInt(key, value);
        return editor.commit();
    }

    public static boolean putFloat(String key, float value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putFloat(key, value);
        return editor.commit();
    }

    public static boolean putLong(String key, long value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putLong(key, value);
        return editor.commit();
    }

    public static boolean putStringSet(String key, Set<String> value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putStringSet(key, value);
        return editor.commit();
    }

    public static boolean putString(String key, String value) {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.putString(key, value);
        return editor.commit();
    }

    public static String getString(String key, String defValue) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getString(key, defValue);
    }

    public static int getInt(String key, int defValue) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getInt(key, defValue);
    }

    public static float getFloat(String key, Float defValue) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getFloat(key, defValue);
    }

    public static boolean getBoolean(String key, Boolean defValue) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getBoolean(key, defValue);
    }

    public static long getLong(String key, long defValue) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getLong(key, defValue);
    }

    public static Set<String> getStringSet(String key) {
        SharedPreferences sharedPreference = getSharedPreference();
        return sharedPreference.getStringSet(key, null);
    }

    public static void removeKey(String key) {
        try {
            SharedPreferences sharedPreference = getSharedPreference();
            Editor editor = sharedPreference.edit();
            editor.remove(key);
            editor.apply();
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    public static void clear() {
        SharedPreferences sharedPreference = getSharedPreference();
        Editor editor = sharedPreference.edit();
        editor.clear();
        editor.apply();
    }
}
