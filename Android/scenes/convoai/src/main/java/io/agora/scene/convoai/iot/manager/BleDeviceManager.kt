package io.agora.scene.convoai.iot.manager

import io.iot.dn.ble.model.BleDevice

/**
 * 蓝牙设备管理器单例类
 * 用于存储和管理扫描到的蓝牙设备
 */
object BleDeviceManager {
    // 存储所有扫描到的设备，键为设备地址，值为BleDevice对象
    private val deviceMap = mutableMapOf<String, BleDevice>()
    
    /**
     * 添加设备到管理器
     * @param device 蓝牙设备
     */
    fun addDevice(device: BleDevice) {
        deviceMap[device.address] = device
    }
    
    /**
     * 根据设备地址获取设备
     * @param address 设备地址
     * @return 对应的BleDevice对象，如果不存在则返回null
     */
    fun getDevice(address: String): BleDevice? {
        return deviceMap[address]
    }
    
    /**
     * 获取所有设备
     * @return 所有存储的设备列表
     */
    fun getAllDevices(): List<BleDevice> {
        return deviceMap.values.toList()
    }
    
    /**
     * 清空设备列表
     */
    fun clearDevices() {
        deviceMap.clear()
    }
    
    /**
     * 移除指定设备
     * @param address 设备地址
     */
    fun removeDevice(address: String) {
        deviceMap.remove(address)
    }
} 