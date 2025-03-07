package io.agora.scene.convoai.iot.manager

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.iot.model.CovIotDevice

/**
 * IoT设备管理器，负责设备信息的存储和读取
 */
class CovIotDeviceManager private constructor(private val context: Context) {
    private val TAG = "CovIotDeviceManager"
    
    // SharedPreferences 键值
    private val PREFS_NAME = "iot_devices_prefs"
    private val DEVICES_KEY = "saved_devices"
    
    private val sharedPrefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }
    
    /**
     * 从本地存储加载设备列表
     * @return 设备列表，如果没有则返回空列表
     */
    fun loadDevicesFromLocal(): List<CovIotDevice> {
        try {
            val devicesJson = sharedPrefs.getString(DEVICES_KEY, null)
            
            if (!devicesJson.isNullOrEmpty()) {
                val type = object : TypeToken<List<CovIotDevice>>() {}.type
                val loadedDevices = Gson().fromJson<List<CovIotDevice>>(devicesJson, type)
                
                CovLogger.d(TAG, "已从本地加载 ${loadedDevices.size} 个设备")
                return loadedDevices
            } else {
                CovLogger.d(TAG, "本地没有保存的设备")
            }
        } catch (e: Exception) {
            CovLogger.e(TAG, "加载设备失败: ${e.message}")
            e.printStackTrace()
        }
        return emptyList()
    }
    
    /**
     * 保存设备列表到本地存储
     * @param deviceList 要保存的设备列表
     * @return 保存是否成功
     */
    fun saveDevicesToLocal(deviceList: List<CovIotDevice>): Boolean {
        try {
            val devicesJson = Gson().toJson(deviceList)
            sharedPrefs.edit().putString(DEVICES_KEY, devicesJson).apply()
            
            CovLogger.d(TAG, "已保存 ${deviceList.size} 个设备到本地")
            return true
        } catch (e: Exception) {
            CovLogger.e(TAG, "保存设备失败: ${e.message}")
            e.printStackTrace()
            return false
        }
    }
    
    /**
     * 添加单个设备并保存
     * @param device 要添加的设备
     * @return 保存是否成功
     */
    fun addDevice(device: CovIotDevice): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        currentDevices.add(0, device) // 添加到列表开头
        return saveDevicesToLocal(currentDevices)
    }
    
    /**
     * 删除单个设备并保存
     * @param deviceId 要删除的设备ID
     * @return 保存是否成功
     */
    fun removeDevice(deviceId: String): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        val initialSize = currentDevices.size
        currentDevices.removeAll { it.id == deviceId }
        
        if (currentDevices.size < initialSize) {
            return saveDevicesToLocal(currentDevices)
        }
        return false
    }
    
    /**
     * 更新设备信息并保存
     * @param device 更新后的设备信息
     * @return 保存是否成功
     */
    fun updateDevice(device: CovIotDevice): Boolean {
        val currentDevices = loadDevicesFromLocal().toMutableList()
        val index = currentDevices.indexOfFirst { it.id == device.id }
        
        if (index != -1) {
            currentDevices[index] = device
            return saveDevicesToLocal(currentDevices)
        }
        return false
    }
    
    /**
     * 获取设备总数
     * @return 设备总数
     */
    fun getDeviceCount(): Int {
        return loadDevicesFromLocal().size
    }

    fun getDevice(deviceId: String): CovIotDevice? {
        return loadDevicesFromLocal().find { it.id == deviceId }
    }
    
    companion object {
        @Volatile
        private var instance: CovIotDeviceManager? = null
        
        fun getInstance(context: Context): CovIotDeviceManager {
            return instance ?: synchronized(this) {
                instance ?: CovIotDeviceManager(context.applicationContext).also { instance = it }
            }
        }
    }
} 