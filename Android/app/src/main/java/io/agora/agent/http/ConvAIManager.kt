package io.agora.agent.http

import android.os.Handler
import android.os.Looper
import io.agora.agent.BuildConfig
import io.agora.agent.utils.AgentLogger
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException

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
    val bsVoiceThreshold: Int? = null,
    val idleTimeout: Int? = null,
    val ttsVoiceId: String? = null
)

object ConvAIManager {

    val TAG = "ConvAIManager"

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    private var agentId: String? = null

    fun startAgent(params: AgentRequestParams, succeed: (Boolean) -> Unit) {
        val requestURL = "${BuildConfig.TOOLBOX_SERVER_HOST}/v1/convoai/start"
        AgentLogger.d(TAG, "Start agent request: $requestURL, channelName: ${params.channelName}")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", BuildConfig.AG_APP_ID)
            postBody.put("channel_name", params.channelName)
            postBody.put("agent_rtc_uid", params.agentRtcUid)
            postBody.put("remote_rtc_uid", params.remoteRtcUid)
            params.rtcCodec?.let { postBody.put("rtc_codec", it) }
            params.audioScenario?.let { postBody.put("audio_scenario", it) }
            params.greeting?.let { postBody.put("custom_llm.greeting", it) }
            params.prompt?.let { postBody.put("custom_llm.prompt", it) }
            params.maxHistory?.let { postBody.put("custom_llm.max_history", it) }
            params.asrLanguage?.let { postBody.put("asr.language", it) }
            params.vadInterruptThreshold?.let { postBody.put("vad.interrupt_threshold", it) }
            params.vadPrefixPaddingMs?.let { postBody.put("vad.prefix_padding_ms", it) }
            params.vadSilenceDurationMs?.let { postBody.put("vad.silence_duration_ms", it) }
            params.vadThreshold?.let { postBody.put("vad.threshold", it) }
            params.bsVoiceThreshold?.let { postBody.put("bs_voice_threshold", it) }
            params.idleTimeout?.let { postBody.put("idle_timeout", it) }
            params.ttsVoiceId?.let { postBody.put("tts.voice_id", it) }
        } catch (e: JSONException) {
            AgentLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        OkHttpClient().newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body?.string()
                AgentLogger.d(TAG, "Start agent response: $json")
                if (json == null || response.code != 200) {
                    runOnMainThread {
                        succeed.invoke(false)
                    }
                } else {
                    try {
                        val jsonObj = JSONObject(json)
                        val code = jsonObj.optInt("code")
                        val aid = jsonObj.optJSONObject("data")?.optString("agent_id")
                        if (code == 0 && !aid.isNullOrEmpty()) {
                            agentId = aid
                            runOnMainThread {
                                succeed.invoke(true)
                            }
                        } else {
                            AgentLogger.e(TAG, "Request failed with code: $code, aid: $aid")
                            runOnMainThread {
                                succeed.invoke(false)
                            }
                        }
                    } catch (e: JSONException) {
                        AgentLogger.e(TAG, "JSON parse error: ${e.message}")
                        runOnMainThread {
                            succeed.invoke(false)
                        }
                    }
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                AgentLogger.e(TAG, "Start agent failed: $e")
                runOnMainThread {
                    succeed.invoke(false)
                }
            }
        })
    }

    fun stopAgent(succeed: (Boolean) -> Unit) {
        if (agentId.isNullOrEmpty()) {
            runOnMainThread {
                succeed.invoke(false)
            }
            return
        }
        val requestURL = "${BuildConfig.TOOLBOX_SERVER_HOST}/v1/convoai/stop"
        AgentLogger.d(TAG, "Stop agent request: $requestURL, agent_id: $agentId")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", BuildConfig.AG_APP_ID)
            postBody.put("agent_id", agentId)
        } catch (e: JSONException) {
            AgentLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        OkHttpClient().newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body?.string()
                AgentLogger.d(TAG, "Stop agent response: $json")
                runOnMainThread {
                    agentId = null
                    succeed.invoke(true)
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                AgentLogger.e(TAG, "Stop agent failed: $e")
                runOnMainThread {
                    agentId = null
                    succeed.invoke(true)
                }
            }
        })
    }

    fun updateAgent(voiceId: String, succeed: (Boolean) -> Unit) {
        if (agentId.isNullOrEmpty()) {
            runOnMainThread {
                succeed.invoke(false)
            }
            return
        }
        val requestURL = "${BuildConfig.TOOLBOX_SERVER_HOST}/v1/convoai/update"
        AgentLogger.d(TAG, "Update agent request: $requestURL, agent_id: $agentId")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", BuildConfig.AG_APP_ID)
            postBody.put("voice_id", voiceId)
            postBody.put("agent_id", agentId)
        } catch (e: JSONException) {
            AgentLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        OkHttpClient().newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body?.string()
                AgentLogger.d(TAG, "Update agent response: $json")
                if (json == null || response.code != 200) {
                    runOnMainThread {
                        succeed.invoke(false)
                    }
                } else {
                    runOnMainThread {
                        succeed.invoke(true)
                    }
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                AgentLogger.e(TAG, "Update agent failed: $e")
                runOnMainThread {
                    succeed.invoke(false)
                }
            }
        })
    }

    private fun runOnMainThread(r: Runnable) {
        if (Thread.currentThread() == mainHandler.looper.thread) {
            r.run()
        } else {
            mainHandler.post(r)
        }
    }
}