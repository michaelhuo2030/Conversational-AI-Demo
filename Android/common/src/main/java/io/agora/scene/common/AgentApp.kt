package io.agora.scene.common

import android.app.Application
import android.util.Log
import com.tencent.mmkv.MMKV
import io.agora.scene.common.util.AgoraLogger
import io.agora.scene.common.util.CommonLogger
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import io.agora.scene.common.debugMode.DebugButton
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.debugMode.DebugConfigSettings

class AgentApp : Application() {

    companion object {
        private const val TAG = "AgentApp"
        private lateinit var app: Application

        @JvmStatic
        fun instance(): Application {
            return app
        }
    }

    private fun fetchAppData() {
        DataProviderLoader.getDataProvider() ?.let {
            DebugConfigSettings.init(this, it.isMainland())
            ServerConfig.initBuildConfig(
                isMainland = it.isMainland(),
                envName = it.envName(),
                toolboxHost = it.toolboxHost(),
                rtcAppId = it.rtcAppId(),
                rtcAppCert = it.rtcAppCert())
        }?: run {
            CommonLogger.d(TAG,"No data provider found")
        }
    }

    override fun onCreate() {
        super.onCreate()
        fetchAppData()
        app = this
        AgoraLogger.initXLog(this)
        initMMKV()
        try {
            extractResourceToCache("common_resource.zip")
            initFile("ball_video_start.mov")
            initFile("ball_video_rotating.mov")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to init files", e)
        }

        // Use ProcessLifecycleOwner to monitor application-level lifecycle
        ProcessLifecycleOwner.get().lifecycle.addObserver(object : LifecycleEventObserver {
            override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
                when (event) {
                    Lifecycle.Event.ON_START -> {
                        // App comes to foreground
                        DebugButton.getInstance(applicationContext).restoreVisibility()
                    }
                    Lifecycle.Event.ON_STOP -> {
                        // App goes to background
                        DebugButton.getInstance(applicationContext).temporaryHide()
                    }
                    else -> {}
                }
            }
        })
    }

    private fun initMMKV() {
        val rootDir = MMKV.initialize(this)
        CommonLogger.d(TAG, "mmkv root: $rootDir")
    }

    @Throws(IOException::class)
    private fun extractResourceToCache(zipFileName: String) {
        val dirName = zipFileName.substringBeforeLast(".zip")
        val resourceDir = File(cacheDir, dirName)
        
        if (resourceDir.exists()) {
            CommonLogger.d(TAG, "Resources already exist at: ${resourceDir.absolutePath}")
            return
        }

        // 先将 zip 文件复制到缓存目录
        val zipFile = File(cacheDir, zipFileName)
        assets.open(zipFileName).use { input ->
            FileOutputStream(zipFile).use { output ->
                input.copyTo(output)
            }
        }

        // 从缓存目录中的 zip 文件解压
        ZipInputStream(zipFile.inputStream()).use { zipIn ->
            var entry: ZipEntry?=null
            val buffer = ByteArray(4096)
            
            while (zipIn.nextEntry?.also { entry = it } != null) {
                val newFile = File(cacheDir, entry!!.name)

                if (entry!!.isDirectory) {
                    newFile.mkdirs()
                    continue
                }

                newFile.parentFile?.mkdirs()

                FileOutputStream(newFile).use { fos ->
                    var len: Int
                    while (zipIn.read(buffer).also { len = it } > 0) {
                        fos.write(buffer, 0, len)
                    }
                }
                // 设置解压后文件的创建/修改时间为原文件的时间戳
                val lastModified = entry!!.time // 获取原始文件的最后修改时间
                newFile.setLastModified(lastModified) // 设置解压后文件的时间戳
            }
        }

        // 删除临时 zip 文件
        zipFile.delete()
        
        CommonLogger.d(TAG, "Extracted resources to: ${resourceDir.absolutePath}")
    }

    @Throws(IOException::class)
    private fun initFile(fileName: String, isCache: Boolean = false) {
        assets.open(fileName).use { inputStream ->
            val outFile = if (isCache) {
                File(cacheDir, fileName)
            } else {
                File(filesDir, fileName)
            }
            
            FileOutputStream(outFile).use { outputStream ->
                inputStream.copyTo(outputStream, bufferSize = 10240)
            }
        }
    }
}