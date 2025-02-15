package io.agora.scene.common.constant

import androidx.annotation.IntDef
import io.agora.scene.common.util.LocalStorageUtil

@Target(AnnotationTarget.CLASS, AnnotationTarget.PROPERTY, AnnotationTarget.VALUE_PARAMETER, AnnotationTarget.TYPE)
@Retention(AnnotationRetention.SOURCE)
@IntDef(
    ServerEnv.PROD,
    ServerEnv.STAGING,
    ServerEnv.DEV,
)
annotation class ServerEnv {
    /**
     * 业务服务器环境
     * PROD 暂无
     * STAGING 连接 CONVoAI PROD 环境
     * STAGING_DEV 连接 CONVoAI STAGING 环境
     *
     */
    companion object {
        const val PROD = 0
        const val STAGING = 1
        const val DEV = 2
    }
}

data class AgentKey(
    var appId: String = "",
    var appCert: String = "",
)


object ServerConfig {

    const val IS_DEBUG = "is_debug"

    private const val GLOBAL_CONVOAI_PROD_TOOLBOX_HOST = "https://toolbox-global.la3d.agoralab.co"
    private const val GLOBAL_CONVOAI_PROD_TOOLBOX_STAGING_HOST = "https://toolbox-global-staging.la3d.agoralab.co"
    private const val GLOBAL_CONVOAI_STAGING_TOOLBOX_STAGING_HOST =
        "https://toolbox-global-staging-convoai-dev.ty3.agoralab.co"

    private const val CONVOAI_PROD_TOOLBOX_HOST = "https://toolbox.sh3t.agoralab.co"
    private const val CONVOAI_PROD_TOOLBOX_STAGING_HOST = "https://toolbox-staging.sh3t.agoralab.co"
    private const val CONVOAI_STAGING_TOOLBOX_STAGING_HOST = "https://toolbox-staging-convoai-dev.gz3.agoralab.co"

    var isDebug: Boolean = LocalStorageUtil.getBoolean(IS_DEBUG, false)
        set(newValue) {
            field = newValue
            LocalStorageUtil.putBoolean(IS_DEBUG, newValue)
            if (!newValue){
                toolboxEnv = ServerEnv.STAGING
            }
        }

    @ServerEnv
    var toolboxEnv: Int = ServerEnv.STAGING

    @JvmStatic
    val toolBoxUrl: String
        get() {
            return if (isMainlandVersion) {
                when (toolboxEnv) {
                    ServerEnv.PROD -> CONVOAI_PROD_TOOLBOX_HOST
                    ServerEnv.STAGING -> CONVOAI_PROD_TOOLBOX_STAGING_HOST
                    ServerEnv.DEV -> CONVOAI_STAGING_TOOLBOX_STAGING_HOST
                    else -> CONVOAI_PROD_TOOLBOX_HOST
                }
            } else {
                when (toolboxEnv) {
                    ServerEnv.PROD -> GLOBAL_CONVOAI_PROD_TOOLBOX_HOST
                    ServerEnv.STAGING -> GLOBAL_CONVOAI_PROD_TOOLBOX_STAGING_HOST
                    ServerEnv.DEV -> GLOBAL_CONVOAI_STAGING_TOOLBOX_STAGING_HOST
                    else -> GLOBAL_CONVOAI_PROD_TOOLBOX_HOST
                }
            }
        }

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
    var isMainlandVersion: Boolean = false
        private set

    private var mProdKey = AgentKey()
    private var mStagingKey = AgentKey()
    private var mDevKey = AgentKey()

    @JvmStatic
    val rtcAppId: String
        get() {
            return when (toolboxEnv) {
                ServerEnv.PROD -> mProdKey.appId
                ServerEnv.STAGING -> mStagingKey.appId
                ServerEnv.DEV -> mDevKey.appId
                else -> mProdKey.appId
            }
        }

    @JvmStatic
    val rtcAppCert: String
        get() {
            return when (toolboxEnv) {
                ServerEnv.PROD -> mProdKey.appCert
                ServerEnv.STAGING -> mStagingKey.appCert
                ServerEnv.DEV -> mDevKey.appCert
                else -> mProdKey.appCert
            }
        }

    fun initConfig(
        isMainland: Boolean,
        prodKey: AgentKey = AgentKey(),
        stagingKey: AgentKey = AgentKey(),
        devKey: AgentKey= AgentKey(),
    ) {
        mProdKey = prodKey
        mStagingKey = stagingKey
        mDevKey = devKey
        isMainlandVersion = isMainland
    }
}