package io.agora.scene.common.util

import android.content.Context
import android.content.res.AssetManager
import android.text.TextUtils
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.Executors
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * File utilities for handling file operations
 */
object FileUtils {

    private const val TAG = "FileUtils"
    private const val BUFFER_SIZE = 1024
    private val singleThreadExecutor: java.util.concurrent.Executor = Executors.newSingleThreadExecutor()

    val FILE_SEPARATOR: String = File.separator

    /**
     * Copies a file from the application's assets to internal storage
     * 
     * @param context Android context
     * @param assetsName Path to file in assets
     * @param storagePath Destination path in internal storage
     * @return The path to the copied file, or null if copy failed
     */
    fun copyFileFromAssets(context: Context, assetsName: String, storagePath: String): String? {
        // Validate input parameters
        if (TextUtils.isEmpty(assetsName) || assetsName.endsWith(FILE_SEPARATOR)) {
            return null
        }

        // Normalize storage path
        val normalizedPath = when {
            TextUtils.isEmpty(storagePath) -> return null
            storagePath.endsWith(FILE_SEPARATOR) -> storagePath.substring(0, storagePath.length - 1)
            else -> storagePath
        }

        val storageFilePath = "$normalizedPath$FILE_SEPARATOR$assetsName"

        val assetManager: AssetManager = context.assets
        try {
            val file = File(storageFilePath)
            if (file.exists()) {
                return storageFilePath
            }
            file.parentFile?.mkdirs()
            val inputStream: java.io.InputStream = assetManager.open(assetsName)
            readInputStream(storageFilePath, inputStream)
        } catch (e: java.io.IOException) {
            CommonLogger.e(TAG, "Failed to copy file from assets $e")
            return null
        }
        return storageFilePath
    }

    /**
     * Read data from input stream and write to output stream
     *
     * @param storagePath Target file path
     * @param inputStream Input stream
     */
    private fun readInputStream(storagePath: String, inputStream: java.io.InputStream) {
        val file = File(storagePath)
        try {
            if (!file.exists()) {
                FileOutputStream(file).use { fos ->
                    inputStream.use { input ->
                        input.copyTo(fos)
                    }
                }
            }
        } catch (e: java.io.IOException) {
            CommonLogger.e(TAG, "Failed to read input stream $e")
        }
    }


    fun deleteFile(filePath: String): Boolean {
        val file = File(filePath)
        if (file.exists()) {
            return file.delete()
        }
        return false
    }

    /**
     * Compresses a directory or file
     */
    fun zipCompress(inputFile: String, outputFile: String?) {
        ZipOutputStream(FileOutputStream(outputFile)).use { zipOut ->
            BufferedOutputStream(zipOut).use { bufferedOut ->
                compressFileOrDirectory(File(inputFile), bufferedOut, zipOut)
            }
        }
    }

    private fun compressFileOrDirectory(
        input: File,
        bufferedOut: BufferedOutputStream,
        zipOut: ZipOutputStream,
        parentPath: String = ""
    ) {
        val entryPath = if (parentPath.isEmpty()) input.name 
                        else "$parentPath/${input.name}"
        
        if (input.isDirectory) {
            input.listFiles()?.forEach { child ->
                compressFileOrDirectory(child, bufferedOut, zipOut, entryPath)
            }
        } else {
            zipOut.putNextEntry(ZipEntry(entryPath))
            FileInputStream(input).use { fis ->
                fis.copyTo(bufferedOut)
            }
        }
    }

    /**
     * Unzips a file to specified directory
     */
    fun unzipFile(inputFile: String, destDirPath: String) {
        val destDir = File(destDirPath)
        ZipInputStream(FileInputStream(inputFile)).use { zipIn ->
            generateSequence { zipIn.nextEntry }
                .filterNot { it.isDirectory }
                .forEach { entry ->
                    val file = File(destDir, entry.name)
                    file.parentFile?.mkdirs()
                    FileOutputStream(file).use { fos ->
                        zipIn.copyTo(fos)
                    }
                }
        }
    }

    /**
     * Compresses multiple files into a single zip file
     *
     * @param sourceFilePaths List of files to compress
     * @param destinationFilePath Output zip file path
     * @param callback Callback to handle completion or errors
     */
    fun compressFiles(
        sourceFilePaths: List<String>,
        destinationFilePath: String,
        callback: ZipCallback
    ) {
        singleThreadExecutor.execute {
            try {
                FileOutputStream(destinationFilePath).use { fos ->
                    ZipOutputStream(fos).use { zipOut ->
                        for (sourceFilePath in sourceFilePaths) {
                            val sourceFile = File(sourceFilePath)
                            if (!sourceFile.exists()) {
                                CommonLogger.w("FileUtils", "Source file does not exist: $sourceFilePath")
                                continue
                            }
                            
                            FileInputStream(sourceFile).use { fis ->
                                zipOut.putNextEntry(java.util.zip.ZipEntry(sourceFile.name))
                                fis.copyTo(zipOut)
                                zipOut.closeEntry()
                            }
                        }
                    }
                }
                callback.onSuccess(destinationFilePath)
                CommonLogger.d(TAG, "Files compressed successfully")
            } catch (e: Exception) {
                CommonLogger.e(TAG, "Compression failed ${e.message}")
                callback.onError(e)
            }
        }
    }

    interface ZipCallback {
        fun onSuccess(path: String)
        fun onError(error: Exception)
    }
}
