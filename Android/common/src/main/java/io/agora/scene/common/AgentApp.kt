package io.agora.scene.common

import android.app.Application
import android.util.Log
import com.tencent.mmkv.MMKV
import io.agora.scene.common.util.AgoraLogger
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.lang.Exception

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
        try {
            initFile("ball_small_video.mov")
        }catch (e: Exception){
            e.printStackTrace()
        }
    }

    private fun initMMKV() {
        val rootDir = MMKV.initialize(this)
        Log.i(TAG, "mmkv root: $rootDir")
    }

    @Throws(IOException::class)
    open fun initFile(fileName: String) {
        val inputStream = assets.open(fileName)
        val out = File(filesDir.absolutePath + File.separator + fileName)
        val outputStream: OutputStream = FileOutputStream(out)
        val buffer = ByteArray(10240)
        while (true) {
            val len = inputStream.read(buffer)
            if (len < 0) break
            outputStream.write(buffer, 0, len)
        }
        outputStream.flush()
        outputStream.close()
        inputStream.close()
    }
}