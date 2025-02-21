package io.agora.scene.common.util

import android.util.Log
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.ApiManager
import io.agora.scene.common.net.ApiManagerService
import io.agora.scene.common.net.BaseResponse
import io.agora.scene.common.net.UploadLogResponse
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.util.UUID

object LogUploader {

    private const val TAG = "LogUploader"

    private val apiService by lazy {
        ApiManager.getService(ApiManagerService::class.java)
    }

    private val scope = CoroutineScope(Job() + Dispatchers.Main)

    fun <T> request(
        block: suspend () -> BaseResponse<T>,
        onSuccess: (T) -> Unit,
        onError: (Exception) -> Unit = {},
    ): Job {
        return scope.launch(Dispatchers.Main) {
            runCatching {
                block()
            }.onSuccess { response ->
                runCatching {
                    if (response.isSuccess) {
                        response.data?.let {
                            onSuccess(it)
                        } ?: run {
                            onError(Exception("Response data is null"))
                        }
                    } else {
                        onError(Exception("Error: ${response.message} (Code: ${response.code})"))
                    }
                }.onFailure { exception ->
                    Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                    onError(Exception("Request failed due to: ${exception.localizedMessage}"))
                }
            }.onFailure { exception ->
                Log.e(TAG, "Request failed: ${exception.localizedMessage}", exception)
                onError(Exception("Request failed due to: ${exception.localizedMessage}"))
            }
        }
    }

    // Get all log file paths
    private fun getAllLogFiles(): List<String> {
        val filesDir = AgentApp.instance().getExternalFilesDir("") ?: return emptyList()
        val logPaths = mutableListOf<String>()
        collectFiles(filesDir, logPaths)
        return logPaths
    }

    // Recursively collect files
    private fun collectFiles(directory: File, paths: MutableList<String>) {
        try {
            directory.listFiles()?.forEach { file ->
                when {
                    file.isFile -> paths.add(file.absolutePath)
                    file.isDirectory -> collectFiles(file, paths)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to collect files: ${e.message}")
        }
    }

    @Volatile
    private var isUploading = false

    fun uploadLog(zipName: String) {
        if (isUploading) return
        isUploading = true
        
        val filesDir = AgentApp.instance().getExternalFilesDir("") ?: return
        
        // Delete all existing zip files in the directory
        filesDir.listFiles()?.forEach { file ->
            if (file.name.endsWith(".zip")) {
                FileUtils.deleteFile(file.absolutePath)
            }
        }
        
        val allLogZipFile = File(filesDir, "${zipName}.zip")
        
        // Get all log file paths
        val logPaths = getAllLogFiles()
        if (logPaths.isEmpty()) {
            isUploading = false
            Log.w(TAG, "No log files found")
            return
        }

        // Compress all files
        FileUtils.compressFiles(logPaths, allLogZipFile.absolutePath, object : FileUtils.ZipCallback {
            override fun onSuccess(path: String) {
                requestUploadLog(File(path),
                    onSuccess = {
                        FileUtils.deleteFile(allLogZipFile.absolutePath)
                        isUploading = false
                        Log.d(TAG, "Upload log success: ${it.logId}")
                    },
                    onError = {
//                        FileUtils.deleteFile(allLogZipFile.absolutePath)
                        isUploading = false
                        Log.e(TAG, "Upload log failed: ${it.message}")
                    })
            }

            override fun onError(error: Exception) {
                isUploading = false
                Log.e(TAG, "Upload log compression failed: ${error.message}")
            }
        })
    }

    fun requestUploadLog(file: File, onSuccess: (UploadLogResponse) -> Unit, onError: (Exception) -> Unit) {
        if (!file.exists()) {
            onError(Exception("Log file not found"))
            return
        }

        try {
            val fileBody = file.asRequestBody("multipart/form-data".toMediaTypeOrNull())
            val partFile = MultipartBody.Part.createFormData("file", file.name, fileBody)
            val traceId = UUID.randomUUID().toString().replace("-", "")
            
            request(
                block = {
                    apiService.requestUploadLog(ServerConfig.rtcAppId, traceId, partFile)
                },
                onSuccess = onSuccess,
                onError = onError
            )
        } catch (e: Exception) {
            onError(e)
            Log.e(TAG, "Failed to prepare upload request: ${e.message}")
        }
    }
}