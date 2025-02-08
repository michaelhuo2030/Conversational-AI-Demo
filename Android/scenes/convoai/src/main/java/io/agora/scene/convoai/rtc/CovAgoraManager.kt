package io.agora.scene.convoai.rtc

import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER
import io.agora.rtc2.Constants.ERR_OK
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.convoai.CovLogger

object CovAgoraManager {

    private val TAG = "CovAgoraManager"

    val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion

    // Settings
    private var presetType = AgentPresetType.VERSION1
    var voiceType = if (isMainlandVersion)
        AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
    var llmType = AgentLLMType.OPEN_AI
    var languageType = AgentLanguageType.EN
    var isAiVad = true
    var isForceThreshold = true
    var connectionState = AgentConnectionState.IDLE
    var rtcToken: String? = null

    private var isDenoise = false

    // Status
    var uid = 0
    var channelName = ""
    val agentUID = 999
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

    fun updateToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            uid.toString(),
            TokenGeneratorType.Token007,
            AgoraTokenType.Rtc,
            success = { token ->
                CovLogger.d(TAG, "getToken success")
                rtcToken = token
                complete.invoke(true)
            },
            failure = { e ->
                CovLogger.d(TAG, "getToken error $e")
                complete.invoke(false)
            })
    }

    fun createRtcEngine(rtcCallback: IRtcEngineEventHandler): RtcEngineEx {
        val config = RtcEngineConfig()
        config.mContext = AgentApp.instance()
        config.mAppId = ServerConfig.rtcAppId
        config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING
        config.mAudioScenario = Constants.AUDIO_SCENARIO_AI_SERVER
        config.mEventHandler = rtcCallback
        rtcEngine = (RtcEngine.create(config) as RtcEngineEx).apply {
            //set audio scenario 10，open AI-QoS
            setAudioScenario(Constants.AUDIO_SCENARIO_AI_CLIENT)
            enableAudioVolumeIndication(200, 10, true)
            adjustRecordingSignalVolume(100)
        }
        rtcEngine?.loadExtensionProvider("ai_echo_cancellation_extension")
        rtcEngine?.loadExtensionProvider("ai_echo_cancellation_ll_extension")
        rtcEngine?.loadExtensionProvider("ai_noise_suppression_extension")
        rtcEngine?.loadExtensionProvider("ai_noise_suppression_ll_extension")
        return rtcEngine!!
    }

    fun joinChannel() {
        CovLogger.d(TAG, "onClickStartAgent channelName: $channelName, localUid: $uid, agentUID: $agentUID")
        val options = ChannelMediaOptions()
        options.clientRoleType = CLIENT_ROLE_BROADCASTER
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false
        rtcEngine?.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        rtcEngine?.setParameters("{\"che.audio.sf.enabled\":false}")
        updateDenoise(true)
        val ret = rtcEngine?.joinChannel(rtcToken, channelName, uid, options)
        CovLogger.d(TAG, "Joining RTC channel: $channelName, uid: $uid")
        if (ret == ERR_OK) {
            CovLogger.d(TAG, "Join RTC room success")
        } else {
            CovLogger.e(TAG, "Join RTC room failed, ret: $ret")
        }
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