package io.agora.scene.common.debugMode

import android.content.Context
import com.google.gson.Gson
import io.agora.scene.common.constant.EnvConfig
import java.io.BufferedReader

data class DevEnvConfig(
    val china: List<EnvConfig>,
    val global: List<EnvConfig>
)

object DebugConfigSettings {

    private const val DEV_CONFIG_FILE = "dev_env_config.json"
    private var instance: DevEnvConfig? = null
    private var isMainLand: Boolean = true

    var isDebug: Boolean = false
        private set

    fun enableDebugMode(isDebug: Boolean) {
        this.isDebug = isDebug
    }

    var isAudioDumpEnabled: Boolean = true
        private set

    fun enableAudioDump(isAudioDumpEnabled: Boolean) {
        this.isAudioDumpEnabled = isAudioDumpEnabled
    }

    @JvmStatic
    fun init(context: Context, isMainLand: Boolean) {
        if (instance != null) return
        this.isMainLand = isMainLand
        try {
            val jsonString = context.assets.open(DEV_CONFIG_FILE).bufferedReader().use(BufferedReader::readText)
            instance = Gson().fromJson(jsonString, DevEnvConfig::class.java)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    @JvmStatic
    fun getServerConfig(): List<EnvConfig> {
        val envConfigList = if (isMainLand) instance?.china else instance?.global
        return envConfigList ?: emptyList()
    }

    fun reset() {
        isDebug = false
        isAudioDumpEnabled = false
    }
}