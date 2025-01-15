package io.agora.scene.common.util

import com.tencent.mmkv.MMKV

object LocalStorageUtil {

    private val mmkv by lazy {
        MMKV.defaultMMKV()
    }

    fun putStringSet(key:String,set: Set<String>){
        mmkv.putStringSet(key,set)
    }

    fun getStringSet(key:String): MutableSet<String>? {
        return mmkv.getStringSet(key, emptySet())
    }

    fun putBoolean(key:String,value:Boolean){
        mmkv.putBoolean(key,value)
    }

    fun getBoolean(key:String,default:Boolean = false): Boolean {
        return mmkv.getBoolean(key, default)
    }
}