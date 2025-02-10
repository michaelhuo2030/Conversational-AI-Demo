package io.agora.scene.convoai.manager

import io.agora.scene.common.constant.ServerConfig
import kotlin.random.Random

object CovAgentManager {

    private val TAG = "CovAgentManager"

    val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion
    
    // Settings
    private var presetList: List<CovAgentPreset>? = null
    private var preset: CovAgentPreset? = null
    var language: CovAgentLanguage? = null

    var enableAiVad = false
    var enableBHVS = true
    var connectionState = AgentConnectionState.IDLE

    // values
    val uid = Random.nextInt(1000, 10000000)
    var agentUID = 999
    var channelName: String = ""

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
        enableAiVad = false
        enableBHVS = true
    }
}