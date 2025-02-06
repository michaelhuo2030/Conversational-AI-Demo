package io.agora.scene.convoai.ui

import android.content.Intent
import android.graphics.Color
import android.graphics.PorterDuff
import android.util.Log
import android.view.View
import androidx.core.content.ContextCompat
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.convoai.http.AgentRequestParams
import io.agora.scene.convoai.rtc.CovAgoraManager
import io.agora.scene.convoai.utils.MessageParser
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER
import io.agora.rtc2.Constants.ERR_OK
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityLivingBinding
import io.agora.scene.convoai.http.ConvAIManager
import kotlin.random.Random

class CovLivingActivity : BaseActivity<CovActivityLivingBinding>() {

    private val TAG = "LivingActivity"

    private lateinit var engine: RtcEngineEx

    private var loadingDialog: LoadingDialog? = null

    private var parser = MessageParser()

    private var isLocalAudioMuted = false
    private var rtcToken: String? = null
    private var channelName = ""
    private var localUid: Int = 0
    private val agentUID = 999
    private var networkStatus: Int? = null
    private var isShowMessageList = false
        set(value) {
            if (field != value) {
                field = value
                updateCenterView()
            }
        }

    var isAgentStarted = false
        set(value) {
            if (field != value) {
                field = value
                updateCenterView()
            }
        }

    override fun getViewBinding(): CovActivityLivingBinding {
        return CovActivityLivingBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        updateCenterView()
        // data
        CovAgoraManager.resetData()
        createRtcEngine()
        loadingDialog = LoadingDialog(this)
        channelName = "agora_" + Random.nextInt(1, 10000000).toString()
        localUid = Random.nextInt(1000, 10000000)
        getToken { }
        PermissionHelp(this).checkMicPerm({}, {
            finish()
        }, true
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        engine.leaveChannel()
        ConvAIManager.stopAgent { ok ->
            if (ok) {
                Log.d(TAG, "Agent stopped successfully")
            } else {
                Log.d(TAG, "Failed to stop agent")
            }
        }
        RtcEngine.destroy()
        CovAgoraManager.resetData()
        loadingDialog?.dismiss()
    }

    override fun onPause() {
        super.onPause()
        if (isAgentStarted) {
            startRecordingService()
        }
    }

    private fun startRecordingService() {
        val intent = Intent("io.agora.agent.START_FOREGROUND_SERVICE")
        sendBroadcast(intent)
    }

    private fun getAgentParams(): AgentRequestParams {
        return AgentRequestParams(
            channelName = channelName,
            remoteRtcUid = localUid,
            agentRtcUid = agentUID,
            ttsVoiceId = if (CovAgoraManager.isMainlandVersion) null else CovAgoraManager.voiceType.value,
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER,
            enableAiVad = CovAgoraManager.isAiVad,
            forceThreshold = CovAgoraManager.isForceThreshold,
        )
    }

    private fun onClickStartAgent() {
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
        loadingDialog?.show()
        CovAgoraManager.channelName = channelName
        CovAgoraManager.uid = localUid

        ConvAIManager.startAgent(getAgentParams()) { isAgentOK ->
            if (isAgentOK) {
                if (rtcToken == null) {
                    getToken { isTokenOK ->
                        if (isTokenOK) {
                            joinChannel()
                        } else {
                            loadingDialog?.dismiss()
                            CovLogger.e(TAG, "Token error")
                            ToastUtil.show(io.agora.scene.common.R.string.cov_detail_join_call_failed)
                        }
                    }
                } else {
                    joinChannel()
                }
            } else {
                loadingDialog?.dismiss()
                CovLogger.e(TAG, "Agent error")
                ToastUtil.show( io.agora.scene.common.R.string.cov_detail_join_call_failed)
            }
        }
    }

    private fun onClickEndCall() {
        engine.leaveChannel()
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_ending))
        loadingDialog?.show()
        ConvAIManager.stopAgent { ok ->
            loadingDialog?.dismiss()
            if (ok) {
                ToastUtil.show(io.agora.scene.common.R.string.cov_detail_agent_leave)
                isAgentStarted = false
                networkStatus = null
                CovAgoraManager.agentStarted = false
                resetSceneState()
            } else {
                ToastUtil.show( "Agent Leave Failed")
            }
        }
    }

    private fun joinChannel() {
        CovLogger.d(TAG, "onClickStartAgent channelName: $channelName, localUid: $localUid, agentUID: $agentUID")
        val options = ChannelMediaOptions()
        options.clientRoleType = CLIENT_ROLE_BROADCASTER
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        engine.setParameters("{\"che.audio.sf.enabled\":false}")
        CovAgoraManager.updateDenoise(true)
        val ret = engine.joinChannel(rtcToken, channelName, localUid, options)
        CovLogger.d(TAG, "Joining RTC channel: $channelName, uid: $localUid")
        if (ret == ERR_OK) {
            CovLogger.d(TAG, "Join RTC room success")
        } else {
            CovLogger.e(TAG, "Join RTC room failed, ret: $ret")
        }
    }

    private fun getToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            localUid.toString(),
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

    private fun createRtcEngine() {
        val config = RtcEngineConfig()
        config.mContext = AgentApp.instance()
        config.mAppId = ServerConfig.rtcAppId
        config.mChannelProfile = Constants.CHANNEL_PROFILE_LIVE_BROADCASTING
        config.mAudioScenario = Constants.AUDIO_SCENARIO_CHORUS
        config.mEventHandler = object : IRtcEngineEventHandler() {
            override fun onError(err: Int) {
                super.onError(err)
                CovLogger.e(TAG, "Rtc Error code:$err, msg:" + RtcEngine.getErrorDescription(err))
            }

            override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
                CovLogger.d(TAG, "local user didJoinChannel uid: $uid")
                updateNetworkStatus(1)
            }

            override fun onLeaveChannel(stats: RtcStats?) {
                CovLogger.d(TAG, "local user didLeaveChannel")
                runOnUiThread {
                    updateNetworkStatus(0)
                }
            }

            override fun onUserJoined(uid: Int, elapsed: Int) {
                runOnUiThread {
                    if (uid == agentUID) {
                        isAgentStarted = true
                        CovAgoraManager.agentStarted = true
                        loadingDialog?.dismiss()
                        ToastUtil.show(io.agora.scene.common.R.string.cov_detail_join_call_succeed,)
                    }
                }
                CovLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                CovLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == agentUID) {
                    runOnUiThread {
                        CovLogger.d(TAG, "start agent reconnect")
                        rtcToken = null
                        // reconnect
                        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
                        loadingDialog?.show()
                        ConvAIManager.startAgent(getAgentParams()) { isAgentOK ->
                            if (!isAgentOK) {
                                loadingDialog?.dismiss()
                                ToastUtil.show(io.agora.scene.common.R.string.cov_detail_agent_leave)
                                engine.leaveChannel()
                                isAgentStarted = false
                                CovAgoraManager.agentStarted = false
                                resetSceneState()
                            }
                        }
                    }
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                super.onAudioVolumeIndication(speakers, totalVolume)
                speakers?.forEach {
                    if (it.uid == agentUID) {
                        runOnUiThread {
                            mBinding?.recordingAnimationView?.startVolumeAnimation(it.volume)
                        }
                    }
                }
            }

            override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
                data?.let {
                    val rawString = String(it, Charsets.UTF_8)
//                    ConvoAiLogger.d(TAG, "onStreamMessage rawString: $rawString")
                    val message = parser.parseStreamMessage(rawString)
//                    ConvoAiLogger.d(TAG, "onStreamMessage message: $message")
                    message?.let { msg ->
                        handleStreamMessage(msg)
                    }
                }
            }

            override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
                CovLogger.d(TAG, "onNetworkQuality uid: $uid, txQuality: $txQuality, rxQuality: $rxQuality")
                if (uid == 0) {
                    runOnUiThread {
                        updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onTokenPrivilegeWillExpire(token: String?) {
                CovLogger.d(TAG, "onTokenPrivilegeWillExpire")
                getToken { isOK ->
                    if (isOK) {
                        engine.renewToken(rtcToken)
                    } else {
                        onClickEndCall()
                    }
                }
            }
        }
        engine = (RtcEngine.create(config) as RtcEngineEx).apply {
            //set audio scenario 10，open AI-QoS
            setAudioScenario(Constants.AUDIO_SCENARIO_AI_CLIENT)
            enableAudioVolumeIndication(100, 10, true)
            adjustRecordingSignalVolume(100)
        }
        engine.loadExtensionProvider("ai_echo_cancellation_extension")
        engine.loadExtensionProvider("ai_echo_cancellation_ll_extension")
        engine.loadExtensionProvider("ai_noise_suppression_extension")
        engine.loadExtensionProvider("ai_noise_suppression_ll_extension")
        CovAgoraManager.rtcEngine = engine
    }

    private fun handleStreamMessage(message: Map<String, Any>) {
        val isFinal = message["is_final"] as? Boolean ?: false
        val streamId = message["stream_id"] as? Double ?: 0.0
        val text = message["text"] as? String ?: ""
        if (text.isEmpty()) {
            return
        }
        runOnUiThread {
            mBinding?.messageListView?.updateStreamContent((streamId != 0.0), text, isFinal)
        }
    }

    private fun resetSceneState() {
        mBinding?.apply {
            messageListView.clearMessages()
            if (isShowMessageList) {
                isShowMessageList = false
                btnCc.setBackgroundColor(Color.parseColor("#212121"))
            }
            if (isLocalAudioMuted) {
                isLocalAudioMuted = false
                engine.adjustRecordingSignalVolume(100)
                btnMic.setBackgroundResource(io.agora.scene.common.R.drawable.app_living_mic_on)
            }
        }

    }

    private fun updateCenterView() {
        if (!isAgentStarted) {
            mBinding?.apply {
                llCalling.visibility = View.INVISIBLE
                vNotJoined.root.visibility = View.VISIBLE
                llJoinCall.visibility = View.VISIBLE
                messageListView.visibility = View.INVISIBLE
                clAnimationContent.visibility = View.INVISIBLE
            }
            return
        }
        mBinding?.apply {
            llCalling.visibility = View.VISIBLE
            vNotJoined.root.visibility = View.INVISIBLE
            llJoinCall.visibility = View.INVISIBLE
            if (isShowMessageList) {
                messageListView.visibility = View.VISIBLE
                clAnimationContent.visibility = View.INVISIBLE
            } else {
                messageListView.visibility = View.INVISIBLE
                clAnimationContent.visibility = View.VISIBLE
            }
        }
    }

    private fun updateNetworkStatus(value: Int) {
        networkStatus = value
        mBinding?.apply {
            when (value) {
                1, 2 -> {
//                    btnInfo.setColorFilter(ContextCompat.getColor(this, R.color.my_tint_color), PorterDuff.Mode.SRC_IN)
                }
                3, 4 -> {
                    btnInfo.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_okay)
                }
                else -> {
                    btnInfo.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_poor)
                }
            }
        }

    }

    private fun setupView() {
        mBinding?.apply {
            setOnApplyWindowInsetsListener(root)
            btnBack.setOnClickListener {
                finish()
            }
            btnEndCall.setOnClickListener {
                onClickEndCall()
            }
            btnMic.setOnClickListener {
                isLocalAudioMuted = !isLocalAudioMuted
                engine.adjustRecordingSignalVolume(if (isLocalAudioMuted) 0 else 100)
                btnMic.setBackgroundResource(
                    if (isLocalAudioMuted) io.agora.scene.common.R.drawable.app_living_mic_off else io.agora.scene.common.R.drawable.app_living_mic_on
                )
            }
            btnSettings.setOnClickListener {
                CovSettingsDialog().show(supportFragmentManager, "AgentSettingsSheetDialog")
            }
            btnCc.setOnClickListener {
                isShowMessageList = !isShowMessageList
            }
            btnInfo.setOnClickListener {
                CovAgentInfoDialog().apply {
                }.show(supportFragmentManager, "StatsDialog")
            }
            llJoinCall.setOnClickListener {
                onClickStartAgent()
            }
        }
    }
}