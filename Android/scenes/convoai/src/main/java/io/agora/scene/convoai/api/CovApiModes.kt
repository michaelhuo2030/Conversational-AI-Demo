package io.agora.scene.convoai.api

import org.json.JSONObject

data class AgentRequestParams(
    val channelName: String,
    val agentRtcUid: String,
    val remoteRtcUid: String,
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
    val ttsVoiceId: String? = null,
    val enableAiVad: Boolean? = null,
    val enableBHVS: Boolean? = null,
    val presetName: String? = null,
    val graphId: String? = null,
    val parameters: JSONObject? = null,
)

data class CovAgentPreset(
    val index: Int,
    val name: String,
    val display_name: String,
    val preset_type: String,
    val default_language_code: String,
    val default_language_name: String,
    val support_languages: List<CovAgentLanguage>,
    val call_time_limit_second: Long,
) {
    fun isIndependent(): Boolean {
        return preset_type == "independent"
    }
}

data class CovAgentLanguage(
    val language_code: String,
    val language_name: String
)