package io.agora.scene.common

import android.app.Application
import android.util.Log
import com.tencent.mmkv.MMKV
import io.agora.scene.common.util.AgoraLogger

class AgentApp : Application() {

    companion object {
        private const val TAG = "AgentApp"
        private lateinit var app: Application

        @JvmStatic
        fun instance(): Application {
            return app
        }
    }

    override fun onCreate() {
        super.onCreate()
        app = this
        initMMKV()
        AgoraLogger.initXLog(this)
    }

    private fun initMMKV() {
        val rootDir = MMKV.initialize(this)
        Log.i(TAG, "mmkv root: $rootDir")
    }


}