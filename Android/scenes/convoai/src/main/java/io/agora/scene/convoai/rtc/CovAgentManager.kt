package io.agora.scene.convoai.rtc

import io.agora.scene.common.constant.ServerConfig

object CovAgentManager {

    private val TAG = "CovAgentManager"

    val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion

    // Settings
    private var presetType = AgentPresetType.VERSION1
    var voiceType = if (isMainlandVersion)
        AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
    var llmType = AgentLLMType.OPEN_AI
    var languageType = AgentLanguageType.EN
    var isAiVad = true
    var isForceThreshold = true
    var enableBHVS = false
    var connectionState = AgentConnectionState.IDLE

    var rtcToken: String? = null

    // Status
    var uid = 0
    var channelName = ""
    val agentUID = 999

    fun updatePreset(type: AgentPresetType) {
        presetType = type
        when (type) {
            AgentPresetType.VERSION1 -> {
                voiceType = if (isMainlandVersion)
                    AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
            AgentPresetType.XIAO_AI -> {
                voiceType = AgentVoiceType.FEMALE_SHAONV
                llmType = AgentLLMType.MINIMAX
                languageType = AgentLanguageType.CN
            }
            AgentPresetType.TBD -> {
                voiceType = AgentVoiceType.TBD
                llmType = AgentLLMType.MINIMAX
                languageType = AgentLanguageType.CN
            }
            AgentPresetType.DEFAULT -> {
                voiceType = AgentVoiceType.ANDREW
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
            AgentPresetType.AMY -> {
                voiceType = AgentVoiceType.EMMA
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
        }
    }

    fun getPresetType(): AgentPresetType {
        return presetType
    }

    fun resetData() {
        updatePreset(if (isMainlandVersion) AgentPresetType.XIAO_AI else AgentPresetType.DEFAULT)
        isAiVad = true
        isForceThreshold = true
    }
}