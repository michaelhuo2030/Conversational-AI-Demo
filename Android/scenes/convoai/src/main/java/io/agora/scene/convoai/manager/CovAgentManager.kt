package io.agora.scene.convoai.manager

import android.util.Log
import com.google.gson.Gson
import com.google.gson.JsonObject
import io.agora.scene.common.constant.ServerConfig
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

object CovAgentManager {

    private val TAG = "CovAgentManager"

    val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private val okHttpClient by lazy {
        SecureOkHttpClient.create()
            .addInterceptor(HttpLogger())
            .build()
    }

    private var agentId: String? = null

    // Settings
    private var presetList: List<CovAgentPreset>? = null
    private var preset: CovAgentPreset? = null
    var language: CovAgentLanguage? = null

    var enableAiVad = false
    var enableBHVS = true
    var connectionState = AgentConnectionState.IDLE

    var agentUID = 999
    private const val SERVICE_VERSION = "v2"
    private var channelName: String? = null

    fun setPresetList(l: List<CovAgentPreset>) {
        presetList = l
        setPreset(presetList?.firstOrNull())
    }

    fun getPresetList(): List<CovAgentPreset>? {
        return presetList
    }

    fun setPreset(p: CovAgentPreset?) {
        preset = p
        if (p?.default_language_code?.isNotEmpty() == true) {
            language = p.support_languages.firstOrNull { it.language_code == p.default_language_code }
        } else {
            language = p?.support_languages?.firstOrNull()
        }
        if (p?.name == "spoken_english_practice") {
            agentUID = 1234
        } else {
            agentUID = 999
        }
    }

    fun getLanguages(): List<CovAgentLanguage>? {
        return preset?.support_languages
    }

    fun getPreset(): CovAgentPreset? {
        return preset
    }

    fun resetData() {
        enableAiVad = true
        enableBHVS = true
    }

    fun startAgent(params: AgentRequestParams, succeed: (Boolean) -> Unit) {
        channelName = params.channelName
        val requestURL = "${ServerConfig.toolBoxUrl}/${SERVICE_VERSION}/convoai/start"
        CovLogger.d(TAG, "Start agent request: $requestURL, channelName: ${params.channelName}")
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
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        Log.d(TAG, postBody.toString())
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                CovLogger.d(TAG, "Start agent response: $json")
                if (response.code != 200) {
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
                            CovLogger.d(TAG, "Start agent request: $requestURL, agent_id: $agentId")
                            runOnMainThread {
                                succeed.invoke(true)
                            }
                        } else {
                            CovLogger.e(TAG, "Request failed with code: $code, aid: $aid")
                            runOnMainThread {
                                succeed.invoke(false)
                            }
                        }
                    } catch (e: JSONException) {
                        CovLogger.e(TAG, "JSON parse error: ${e.message}")
                        runOnMainThread {
                            succeed.invoke(false)
                        }
                    }
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "Start agent failed: $e")
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
        val requestURL = "${ServerConfig.toolBoxUrl}/${SERVICE_VERSION}/convoai/stop"
        CovLogger.d(TAG, "Stop agent request: $requestURL, agent_id: $agentId")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            postBody.put("agent_id", agentId)
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                CovLogger.d(TAG, "Stop agent response: $json")
                runOnMainThread {
                    agentId = null
                    succeed.invoke(true)
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "Stop agent failed: $e")
                runOnMainThread {
                    agentId = null
                    succeed.invoke(true)
                }
            }
        })
    }

    fun updateAgent(voiceId: String? = null, succeed: (Boolean) -> Unit) {
        if (agentId.isNullOrEmpty()) {
            runOnMainThread {
                succeed.invoke(false)
            }
            return
        }
        val requestURL = "${ServerConfig.toolBoxUrl}/${SERVICE_VERSION}/convoai/update"
        CovLogger.d(TAG, "Update agent request: $requestURL, agent_id: $agentId")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            postBody.put("agent_id", agentId)
            voiceId?.let {postBody.put("voice_id", it)}
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                CovLogger.d(TAG, "Update agent response: $json")
                if (response.code != 200) {
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
                CovLogger.e(TAG, "Update agent failed: $e")
                runOnMainThread {
                    succeed.invoke(false)
                }
            }
        })
    }

    fun fetchPresets(succeed: (Boolean) -> Unit) {
        if (presetList != null) {
            succeed(true)
            return
        }
        val requestURL = "${ServerConfig.toolBoxUrl}/${SERVICE_VERSION}/convoai/presetAgents"
        CovLogger.d(TAG, "fetchPresets start: $requestURL")
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .get()
            .build()
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                CovLogger.d(TAG, "fetchPresets result: $json")
                val gson = Gson()
                val jsonObject = gson.fromJson(json, JsonObject::class.java)
                val code = jsonObject.get("code").asInt
                if (code == 0) {
                    val data = gson.fromJson(jsonObject.getAsJsonArray("data"), Array<CovAgentPreset>::class.java).toList()
                    setPresetList(data)
                    runOnMainThread {
                        succeed.invoke(true)
                    }
                } else {
                    CovLogger.d(TAG, "fetch presets failed: $code")
                    runOnMainThread {
                        succeed.invoke(false)
                    }
                }
            }
            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "fetch presets failed: $e")
                runOnMainThread {
                    succeed.invoke(false)
                }
            }
        })
    }

    fun ping(succeed: (Boolean) -> Unit) {
        val requestURL = "${ServerConfig.toolBoxUrl}/${SERVICE_VERSION}/convoai/ping"
        CovLogger.d(TAG, "ping: $requestURL, agent_id: $agentId, channel_name: $channelName")
        val postBody = JSONObject()
        try {
            postBody.put("app_id", ServerConfig.rtcAppId)
            channelName?.let {postBody.put("channel_name", it)}
            preset?.name?.let {postBody.put("preset_name", it)}
        } catch (e: JSONException) {
            CovLogger.e(TAG, "postBody error ${e.message}")
        }
        val requestBody = RequestBody.create(null, postBody.toString())
        val request = Request.Builder()
            .url(requestURL)
            .addHeader("Content-Type", "application/json")
            .post(requestBody)
            .build()
        okHttpClient.newCall(request).enqueue(object : Callback {
            override fun onResponse(call: Call, response: Response) {
                val json = response.body.string()
                CovLogger.d(TAG, "agent ping response: $json")
            }
            override fun onFailure(call: Call, e: IOException) {
                CovLogger.e(TAG, "agent ping failed: $e")
            }
        })
    }

    private fun runOnMainThread(r: Runnable) {
        mainScope.launch {
            r.run()
        }
    }
}