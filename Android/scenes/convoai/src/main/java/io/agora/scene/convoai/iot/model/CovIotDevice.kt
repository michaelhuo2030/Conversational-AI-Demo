package io.agora.scene.convoai.iot.model

import io.iot.dn.ble.model.BleDevice

data class CovIotDevice(
    val id: String,
    var name: String,
    val bleDevice: BleDevice,
    val currentPreset: String, // display_name
    val currentLanguage: String, // name
    val enableAIVAD: Boolean
)