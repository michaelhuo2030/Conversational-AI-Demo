package io.agora.scene.convoai.api

import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonObject
import io.agora.scene.common.constant.SSOUserManager
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.common.net.HttpLogger
import io.agora.scene.common.net.SecureOkHttpClient
import io.agora.scene.convoai.CovLogger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import okhttp3.Call
import okhttp3.Callback
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException
import kotlin.time.Duration.Companion.seconds

object CovAgentApiManager {

    private val TAG = "CovServerManager"

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val okHttpClient by lazy {
        SecureOkHttpClient.create(
            readTimeout = 120.seconds,
            writeTimeout = 120.seconds,
            connectTimeout = 120.seconds
        )
            .addInterceptor(HttpLogger())
            .build()
    }

    var agentId: String? = null
        private set

    var currentHost: String? = null
        private set


    private const val SERVICE_VERSION = "v3"

    fun startAgent(params: AgentRequestParams, completion: (error: Exception?, channelName: String) -> Unit) {
        val channelName = params.channelName
        val requestURL = "${ServerConfig.toolBoxUrl}/$SERVICE_VERSION/convoai/start"
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            postBody.put("channel_name", params.channelName)
            postBody.put("agent_rtc_uid", params.agentRtcUid)
            postBody.put("remote_rtc_uid", params.remoteRtcUid)
            params.rtcCodec?.let { postBody.put("rtc_codec", it) }
            params.audioScenario?.let { postBody.put("audio_scenario", it) }

            val customLlm = JSONObject()
            params.greeting?.let { customLlm.put("greeting", it) }
            params.prompt?.let { customLlm.put("prompt", it) }
            params.maxHistory?.let { customLlm.put("max_history", it) }
            if (customLlm.length() > 0) {
                postBody.put("custom_llm", customLlm)
            }

            val asr = JSONObject()
            params.asrLanguage?.let { asr.put("language", it) }
            if (asr.length() > 0) {
                postBody.put("asr", asr)
            }

            val vad = JSONObject()
            params.vadInterruptThreshold?.let { vad.put("interrupt_threshold", it) }
            params.vadPrefixPaddingMs?.let { vad.put("prefix_padding_ms", it) }
            params.vadSilenceDurationMs?.let { vad.put("silence_duration_ms", it) }
            params.vadThreshold?.let { vad.put("threshold", it) }
            if (vad.length() > 0) {
                postBody.put("vad", vad)
            }

            params.bsVoiceThreshold?.let { postBody.put("bs_voice_threshold", it) }
            params.idleTimeout?.let { postBody.put("idle_timeout", it) }
            params.presetName?.let { postBody.put("preset_name", it) }

            val advancedFeatures = JSONObject()
            params.enableAiVad?.let { advancedFeatures.put("enable_aivad", it) }
            params.enableBHVS?.let { advancedFeatures.put("enable_bhvs", it) }
            postBody.put("advanced_features", advancedFeatures)

            val tts = JSONObject()
            params.ttsVoiceId?.let { tts.put("voice_id", it) }
            if (tts.length() > 0) {
                postBody.put("tts", tts)
            }
            params.graphId?.let { postBody.put("graph_id", it) }
            params.parameters?.let { postBody.put("parameters", it) }
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        Log.d(TAG, postBody.toString())
        
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)
        
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                val httpCode = response.code
                if (httpCode != 200) {
                    runOnMainThread {
                        completion.invoke(Exception("httpCode: $httpCode"), channelName)
                    }
                } else {
                    try {
                        val jsonObj = JSONObject(json)
                        val code = jsonObj.optInt("code")
                        val aid = jsonObj.optJSONObject("data")?.optString("agent_id")

                        currentHost = jsonObj.optJSONObject("data")?.optString("agent_url")
                        if (code == 0 && !aid.isNullOrEmpty()) {
                            agentId = aid
                            runOnMainThread {
                                completion.invoke(null, channelName)
                            }
                        } else {
                            runOnMainThread {
                                completion.invoke(Exception("responseCode: $code"), channelName)
                            }
                        }
                    } catch (e: JSONException) {
                        CovLogger.e(TAG, "JSON parse error: ${e.message}")
                        runOnMainThread {
                            completion.invoke(e, channelName)
                        }
                    }
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "Start agent failed: $e")
                runOnMainThread {
                    completion.invoke(e, channelName)
                }
            }
        })
    }

    private fun buildRequest(url: String, method: String = "GET", body: RequestBody? = null): Request {
        val builder = Request.Builder()
            .url(url)
            .addHeader("Content-Type", "application/json")

        // Add authorization header for v3 and v4
        if (SERVICE_VERSION.startsWith("v3") || SERVICE_VERSION.startsWith("v4")) {
            builder.addHeader("Authorization", "Bearer ${SSOUserManager.getToken()}")
        }

        when (method.uppercase()) {
            "POST" -> builder.post(body ?: RequestBody.create(null, ""))
            "GET" -> builder.get()
            // Add other methods if needed
        }

        return builder.build()
    }

    fun fetchPresets(completion: (error: Exception?, List<CovAgentPreset>) -> Unit) {
        val requestURL = "${ServerConfig.toolBoxUrl}/$SERVICE_VERSION/convoai/presetAgents"
        val request = buildRequest(requestURL)
        
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                val gson = Gson()
                val jsonObject = gson.fromJson(json, JsonObject::class.java)
                val code = jsonObject.get("code").asInt
                if (code == 0) {
                    val data =
                        gson.fromJson(jsonObject.getAsJsonArray("data"), Array<CovAgentPreset>::class.java).toList()
                    runOnMainThread {
                        completion.invoke(null, data)
                    }
                } else {
                    runOnMainThread {
                        completion.invoke(null, emptyList())
                    }
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "fetch presets failed: $e")
                runOnMainThread {
                    completion.invoke(e, emptyList())
                }
            }
        })
    }

    fun ping(channelName: String, preset: String) {
        val requestURL = "${ServerConfig.toolBoxUrl}/$SERVICE_VERSION/convoai/ping"
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            postBody.put("channel_name", channelName)
            postBody.put("preset_name", preset)
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)
        
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "agent ping failed: $e")
            }
        })
    }

    fun stopAgent(channelName: String, preset: String?, completion: (error: Exception?) -> Unit) {
        if (agentId.isNullOrEmpty()) {
            runOnMainThread {
                completion.invoke(Exception("AgentId is null"))
            }
            return
        }
        val requestURL = "${ServerConfig.toolBoxUrl}/$SERVICE_VERSION/convoai/stop"
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            postBody.put("channel_name", channelName)
            preset?.let { postBody.put("preset_name", it) }
            postBody.put("agent_id", agentId)
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = buildRequest(requestURL, "POST", requestBody)
        
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                runOnMainThread {
                    agentId = null
                    completion.invoke(null)
                }
            }

            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "Stop agent failed: $e")
                runOnMainThread {
                    agentId = null
                    completion.invoke(e)
                }
            }
        })
    }

    private fun runOnMainThread(r: Runnable) {
        mainScope.launch {
            r.run()
        }
    }
}