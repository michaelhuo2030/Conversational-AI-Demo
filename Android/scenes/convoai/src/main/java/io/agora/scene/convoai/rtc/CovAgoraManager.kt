package io.agora.scene.convoai.rtc

import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.constant.ServerConfig

object CovAgoraManager {

    val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion

    // Settings
    var speakerType = AgentSpeakerType.SPEAKER1
    var microphoneType = AgentMicrophoneType.MICROPHONE1
    private var presetType = AgentPresetType.VERSION1
    var voiceType = if (isMainlandVersion)
        AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
    var llmType = AgentLLMType.OPEN_AI
    var languageType = AgentLanguageType.EN

    var isAiVad = true
    var isForceThreshold = true

    private var isDenoise = false

    // Status
    var uid = 0
    var channelName = ""
    var agentStarted = false
    var rtcEngine: RtcEngineEx? = null

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

    fun getDenoiseStatus(): Boolean {
        return isDenoise
    }

    fun updateDenoise(isOn: Boolean) {
        isDenoise = isOn
        if (isDenoise) {
            rtcEngine?.apply {
                setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
                setParameters("{\"che.audio.sf.enabled\":true}")
                setParameters("{\"che.audio.sf.ainlpToLoadFlag\":1}")
                setParameters("{\"che.audio.sf.nlpAlgRoute\":1}")
                setParameters("{\"che.audio.sf.ainlpModelPref\":11}")
                setParameters("{\"che.audio.sf.ainsToLoadFlag\":1}")
                setParameters("{\"che.audio.sf.nsngAlgRoute\":12}")
                setParameters("{\"che.audio.sf.ainsModelPref\":11}")
                setParameters("{\"che.audio.sf.nsngPredefAgg\":11}")
                setParameters("{\"che.audio.agc.enable\":false}")
            }
        } else {
            rtcEngine?.apply {
                setParameters("{\"che.audio.sf.enabled\":false}")
            }
        }
    }

    fun currentPresetType(): AgentPresetType {
        return presetType
    }

    fun resetData() {
        rtcEngine = null
        updatePreset(if (isMainlandVersion) AgentPresetType.XIAO_AI else AgentPresetType.DEFAULT)
        isDenoise = false
        isAiVad = true
        isForceThreshold = true
    }
}