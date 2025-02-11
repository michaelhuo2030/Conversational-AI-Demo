package io.agora.scene.common.constant

import io.agora.scene.common.BuildConfig
import io.agora.scene.common.util.LocalStorageUtil

object ServerConfig {

    const val Env_Mode = "env_mode"
    const val IS_DEBUG = "is_debug"

    var envRelease: Boolean = LocalStorageUtil.getBoolean(Env_Mode, true)
        set(newValue) {
            field = newValue
            LocalStorageUtil.putBoolean(Env_Mode, newValue)
        }

    var isDebug: Boolean = LocalStorageUtil.getBoolean(IS_DEBUG, false)
        set(newValue) {
            field = newValue
            LocalStorageUtil.putBoolean(IS_DEBUG, newValue)
        }

    @JvmStatic
    val toolBoxUrl: String
        get() {
            return if (envRelease) {
                BuildConfig.TOOLBOX_SERVER_HOST
            } else {
                BuildConfig.TOOLBOX_SERVER_HOST
            }
        }

    @JvmStatic
    val isMainlandVersion: Boolean = (!toolBoxUrl.contains("global"))

    @JvmStatic
    val siteUrl: String
        get() {
            return if (isMainlandVersion) {
                "https://www.agora.io/en/terms-of-service/"
            } else {
                "https://www.agora.io/en/terms-of-service/"
            }
        }

    @JvmStatic
    val rtcAppId: String
        get() = BuildConfig.AG_APP_ID

    @JvmStatic
    val rtcAppCert: String
        get() = BuildConfig.AG_APP_CERTIFICATE
}