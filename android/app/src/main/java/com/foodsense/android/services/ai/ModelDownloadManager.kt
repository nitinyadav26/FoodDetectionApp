package com.foodsense.android.services.ai

import android.content.Context
import androidx.compose.runtime.mutableStateOf
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.concurrent.TimeUnit

// Manages download, storage, and lifecycle of the on-device Gemma 4 E4B model.
// The model file is stored in the app's internal files directory.
class ModelDownloadManager(private val context: Context) {

    enum class DownloadState { IDLE, DOWNLOADING, VERIFYING, COMPLETE, FAILED }

    val downloadProgress = mutableStateOf(0f)
    val downloadState = mutableStateOf(DownloadState.IDLE)
    val isModelAvailable = mutableStateOf(false)

    private val modelDir = File(context.filesDir, MODEL_DIR)
    private val modelFile = File(modelDir, MODEL_FILENAME)
    val modelPath: String get() = modelFile.absolutePath

    @Volatile
    private var cancelled = false

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    init {
        checkModelAvailable()
    }

    fun modelSizeOnDisk(): Long {
        return if (modelFile.exists()) modelFile.length() else 0L
    }

    suspend fun startDownload() = withContext(Dispatchers.IO) {
        if (downloadState.value == DownloadState.DOWNLOADING) return@withContext

        cancelled = false
        downloadState.value = DownloadState.DOWNLOADING
        downloadProgress.value = 0f

        try {
            modelDir.mkdirs()
            val tempFile = File(modelDir, "$MODEL_FILENAME.tmp")

            val request = Request.Builder()
                .url(MODEL_URL)
                .get()
                .build()

            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    downloadState.value = DownloadState.FAILED
                    return@withContext
                }

                val body = response.body ?: run {
                    downloadState.value = DownloadState.FAILED
                    return@withContext
                }

                val totalBytes = body.contentLength()
                var bytesDownloaded = 0L

                tempFile.outputStream().use { output ->
                    body.byteStream().use { input ->
                        val buffer = ByteArray(8192)
                        var bytesRead: Int
                        while (input.read(buffer).also { bytesRead = it } != -1) {
                            if (cancelled) {
                                tempFile.delete()
                                downloadState.value = DownloadState.IDLE
                                return@withContext
                            }
                            output.write(buffer, 0, bytesRead)
                            bytesDownloaded += bytesRead
                            if (totalBytes > 0) {
                                downloadProgress.value = bytesDownloaded.toFloat() / totalBytes.toFloat()
                            }
                        }
                    }
                }
            }

            if (cancelled) {
                tempFile.delete()
                downloadState.value = DownloadState.IDLE
                return@withContext
            }

            // Verify the file exists and has content
            downloadState.value = DownloadState.VERIFYING
            if (tempFile.exists() && tempFile.length() > 0) {
                tempFile.renameTo(modelFile)
                downloadState.value = DownloadState.COMPLETE
                isModelAvailable.value = true
            } else {
                tempFile.delete()
                downloadState.value = DownloadState.FAILED
            }
        } catch (_: Exception) {
            downloadState.value = DownloadState.FAILED
        }
    }

    fun cancelDownload() {
        cancelled = true
    }

    fun deleteModel() {
        modelFile.delete()
        isModelAvailable.value = false
        downloadState.value = DownloadState.IDLE
        downloadProgress.value = 0f
    }

    fun checkModelAvailable() {
        isModelAvailable.value = modelFile.exists() && modelFile.length() > 0
        if (isModelAvailable.value) {
            downloadState.value = DownloadState.COMPLETE
        }
    }

    companion object {
        private const val MODEL_DIR = "gemma_model"
        private const val MODEL_FILENAME = "gemma-4-E4B-it.litertlm"
        private const val MODEL_URL =
            "https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm"
    }
}
