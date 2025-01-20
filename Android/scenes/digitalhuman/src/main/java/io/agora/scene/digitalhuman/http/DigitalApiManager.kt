package io.agora.scene.digitalhuman.http

import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.HttpLogger
import io.agora.scene.common.net.SecureOkHttpClient
import io.agora.scene.digitalhuman.DigitalLogger
import kotlinx.coroutines.*
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

data class AgentRequestParams(
    val channelName: String,
    val agentRtcUid: Int = 999,
    val remoteRtcUid: Int = 998,
    val rtcCodec: Int? = null,
    val audioScenario: Int? = null,
    val greeting: String? = null,
    val prompt: String? = null,
    val maxHistory: Int? = null,
    val asrLanguage: String? = null,
    val vadInterruptThreshold: Float? = null,
    val vadPrefixPaddingMs: Int? = null,
    val vadSilenceDurationMs: Int? = null,
    val vadThreshold: Int? = null,
    val vadVoiceThreshold: Int? = null,
    val idleTimeout: Int? = null,
    val ttsVoiceId: String? = null
)

object DigitalApiManager {

    private val TAG = "DigitalApiManager"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val okHttpClient by lazy {
        SecureOkHttpClient.create()
            .addInterceptor(HttpLogger())
            .build()
    }

    private var agentId: String? = null

    private fun createRequest(url: String, requestBody: RequestBody): Request {
        return Request.Builder()
            .url(url)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
    }

    fun startAgent(params: AgentRequestParams, succeed: (Boolean) -> Unit) {
        scope.launch {
            try {
                val result = startAgentSuspend(params)
                succeed(result)
            } catch (e: Exception) {
                DigitalLogger.e(TAG, "Start agent failed: $e")
                succeed(false)
            }
        }
    }

    private suspend fun startAgentSuspend(params: AgentRequestParams): Boolean = withContext(Dispatchers.IO) {
        val requestURL = "${ServerConfig.toolBoxUrl}/v1/digitalHuman/start"
        DigitalLogger.d(TAG, "Start agent request: $requestURL, channelName: ${params.channelName}")
        
        val postBody = JSONObject().apply {
            put("app_id", ServerConfig.rtcAppId)
            put("channel_name", params.channelName)
            put("agent_rtc_uid", params.agentRtcUid)
            put("remote_rtc_uid", params.remoteRtcUid)
            params.rtcCodec?.let { put("rtc_codec", it) }
            params.audioScenario?.let { put("audio_scenario", it) }
            
            val customLlm = JSONObject().apply {
                params.greeting?.let { put("greeting", it) }
                params.prompt?.let { put("prompt", it) }
                params.maxHistory?.let { put("max_history", it) }
            }
            if (customLlm.length() > 0) {
                put("custom_llm", customLlm)
            }
            
            val asr = JSONObject().apply {
                params.asrLanguage?.let { put("language", it) }
            }
            if (asr.length() > 0) {
                put("asr", asr)
            }
            
            val vad = JSONObject().apply {
                params.vadInterruptThreshold?.let { put("interrupt_threshold", it) }
                params.vadPrefixPaddingMs?.let { put("prefix_padding_ms", it) }
                params.vadSilenceDurationMs?.let { put("silence_duration_ms", it) }
                params.vadThreshold?.let { put("threshold", it) }
                params.vadVoiceThreshold?.let { put("bs_voice_threshold", it) }
            }
            if (vad.length() > 0) {
                put("vad", vad)
            }
            
            params.idleTimeout?.let { put("idle_timeout", it) }
            
            val tts = JSONObject().apply {
                params.ttsVoiceId?.let { put("voice_id", it) }
            }
            if (tts.length() > 0) {
                put("tts", tts)
            }
        }

        val request = createRequest(requestURL, postBody.toString().toRequestBody(null))
        
        suspendCoroutine { continuation ->
            okHttpClient.newCall(request).enqueue(object : Callback {
                override fun onResponse(call: Call, response: Response) {
                    val json = response.body.string()
                    DigitalLogger.d(TAG, "Start agent response: $json")
                    
                    if (response.code != 200) {
                        continuation.resume(false)
                        return
                    }
                    
                    try {
                        val jsonObj = JSONObject(json)
                        val code = jsonObj.optInt("code")
                        val aid = jsonObj.optJSONObject("data")?.optString("agent_id")
                        if (code == 0 && !aid.isNullOrEmpty()) {
                            agentId = aid
                            continuation.resume(true)
                        } else {
                            DigitalLogger.e(TAG, "Request failed with code: $code, aid: $aid")
                            continuation.resume(false)
                        }
                    } catch (e: JSONException) {
                        DigitalLogger.e(TAG, "JSON parse error: ${e.message}")
                        continuation.resume(false)
                    }
                }

                override fun onFailure(call: Call, e: IOException) {
                    DigitalLogger.e(TAG, "Start agent failed: $e")
                    continuation.resume(false)
                }
            })
        }
    }

    fun stopAgent(succeed: (Boolean) -> Unit) {
        scope.launch {
            try {
                val result = stopAgentSuspend()
                succeed(result)
            } catch (e: Exception) {
                DigitalLogger.e(TAG, "Stop agent failed: $e")
                succeed(false)
            }
        }
    }

    private suspend fun stopAgentSuspend(): Boolean = withContext(Dispatchers.IO) {
        if (agentId.isNullOrEmpty()) return@withContext false
        
        val requestURL = "${ServerConfig.toolBoxUrl}/v1/digitalHuman/stop"
        val postBody = JSONObject().apply {
            put("app_id", ServerConfig.rtcAppId)
            put("agent_id", agentId)
        }
        
        val request = createRequest(requestURL, postBody.toString().toRequestBody(null))
        
        suspendCoroutine { continuation ->
            okHttpClient.newCall(request).enqueue(object : Callback {
                override fun onResponse(call: Call, response: Response) {
                    val json = response.body.string()
                    DigitalLogger.d(TAG, "Stop agent response: $json")
                    agentId = null
                    continuation.resume(true)
                }

                override fun onFailure(call: Call, e: IOException) {
                    DigitalLogger.e(TAG, "Stop agent failed: $e")
                    agentId = null
                    continuation.resume(false)
                }
            })
        }
    }

    fun updateAgent(voiceId: String, succeed: (Boolean) -> Unit) {
        scope.launch {
            try {
                val result = updateAgentSuspend(voiceId)
                succeed(result)
            } catch (e: Exception) {
                DigitalLogger.e(TAG, "Update agent failed: $e")
                succeed(false)
            }
        }
    }

    private suspend fun updateAgentSuspend(voiceId: String): Boolean = withContext(Dispatchers.IO) {
        if (agentId.isNullOrEmpty()) return@withContext false
        
        val requestURL = "${ServerConfig.toolBoxUrl}/v1/convoai/update"
        DigitalLogger.d(TAG, "Update agent request: $requestURL, agent_id: $agentId")
        
        val postBody = JSONObject().apply {
            put("app_id", ServerConfig.rtcAppId)
            put("voice_id", voiceId)
            put("agent_id", agentId)
        }
        
        val request = createRequest(requestURL, postBody.toString().toRequestBody(null))
        
        suspendCoroutine { continuation ->
            okHttpClient.newCall(request).enqueue(object : Callback {
                override fun onResponse(call: Call, response: Response) {
                    val json = response.body.string()
                    DigitalLogger.d(TAG, "Update agent response: $json")
                    continuation.resume(response.code == 200)
                }

                override fun onFailure(call: Call, e: IOException) {
                    DigitalLogger.e(TAG, "Update agent failed: $e")
                    continuation.resume(false)
                }
            })
        }
    }

    fun destroy() {
        scope.cancel()
    }
}