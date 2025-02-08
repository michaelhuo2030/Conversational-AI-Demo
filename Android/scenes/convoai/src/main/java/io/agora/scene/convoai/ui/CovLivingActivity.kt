package io.agora.scene.convoai.ui

import android.content.Intent
import android.graphics.PorterDuff
import android.util.Log
import android.view.TextureView
import android.view.View
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.convoai.http.AgentRequestParams
import io.agora.scene.convoai.rtc.CovAgoraManager
import io.agora.scene.convoai.utils.MessageParser
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityLivingBinding
import io.agora.scene.convoai.http.ConvAIManager
import io.agora.scene.convoai.rtc.AgentConnectionState
import kotlin.random.Random


class CovLivingActivity : BaseActivity<CovActivityLivingBinding>() {

    private val TAG = "LivingActivity"

    private lateinit var engine: RtcEngineEx

    private var infoDialog: CovAgentInfoDialog? = null

    private var networkValue: Int = 0

    private var parser = MessageParser()

    private var isLocalAudioMuted = false
        set(value) {
            if (field != value) {
                field = value
                updateMicrophoneView()
            }
        }

    private var isShowMessageList = false
        set(value) {
            if (field != value) {
                field = value
                updateMessageList()
            }
        }

    var connectionState = AgentConnectionState.IDLE
        set(value) {
            if (field != value) {
                field = value
                CovAgoraManager.connectionState = value
                updateStateView()
            }
        }

    private var mCovBallAnim: CovBallAnim? = null

    override fun getViewBinding(): CovActivityLivingBinding {
        return CovActivityLivingBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        updateStateView()
        // data
        CovAgoraManager.resetData()
        createRtcEngine()
        setupBallAnimView()
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
        mCovBallAnim?.let {
            it.release()
            mCovBallAnim = null
        }
    }

    override fun onPause() {
        super.onPause()
        if (connectionState == AgentConnectionState.CONNECTED) {
            startRecordingService()
        }
    }

    private fun startRecordingService() {
        val intent = Intent(this, CovRtcForegroundService::class.java)
        startForegroundService(intent)
    }

    private fun getAgentParams(): AgentRequestParams {
        return AgentRequestParams(
            channelName = CovAgoraManager.channelName,
            remoteRtcUid = CovAgoraManager.uid,
            agentRtcUid = CovAgoraManager.agentUID,
            ttsVoiceId = if (CovAgoraManager.isMainlandVersion) null else CovAgoraManager.voiceType.value,
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER,
            enableAiVad = CovAgoraManager.isAiVad,
            forceThreshold = CovAgoraManager.isForceThreshold,
        )
    }

    private fun onClickStartAgent() {
        connectionState = AgentConnectionState.CONNECTING
        CovAgoraManager.channelName = "agora_" + Random.nextInt(1, 10000000).toString()
        CovAgoraManager.uid = Random.nextInt(1000, 10000000)
        ConvAIManager.startAgent(getAgentParams()) { isAgentOK ->
            if (isAgentOK) {
                if (connectionState == AgentConnectionState.IDLE) {
                    return@startAgent
                }
                CovAgoraManager.updateToken { isTokenOK ->
                    if (isTokenOK) {
                        if (connectionState == AgentConnectionState.IDLE) {
                            return@updateToken
                        }
                        CovAgoraManager.joinChannel()
                    } else {
                        connectionState = AgentConnectionState.IDLE
                        CovLogger.e(TAG, "Token error")
                        ToastUtil.show(R.string.cov_detail_join_call_failed)
                    }
                }
            } else {
                connectionState = AgentConnectionState.IDLE
                CovLogger.e(TAG, "Agent error")
                ToastUtil.show(R.string.cov_detail_join_call_failed)
            }
        }
    }

    private fun onClickEndCall() {
        connectionState = AgentConnectionState.IDLE
        resetSceneState()
        ToastUtil.show(R.string.cov_detail_agent_leave)
        engine.leaveChannel()
        mCovBallAnim?.updateAgentState(AgentState.STATIC)
        ConvAIManager.stopAgent {}
    }

    private fun createRtcEngine() {
        engine = CovAgoraManager.createRtcEngine(object : IRtcEngineEventHandler() {
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
                    updateNetworkStatus(1)
                }
            }

            override fun onUserJoined(uid: Int, elapsed: Int) {
                runOnUiThread {
                    if (uid == CovAgoraManager.agentUID) {
                        connectionState = AgentConnectionState.CONNECTED
                        ToastUtil.show(R.string.cov_detail_join_call_succeed)
                    }
                }
                CovLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                CovLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == CovAgoraManager.agentUID) {
                    runOnUiThread {
                        CovLogger.d(TAG, "start agent reconnect")
//                        rtcToken = null
//
//                        ConvAIManager.startAgent(getAgentParams()) { isAgentOK ->
//                            if (!isAgentOK) {
//                                ToastUtil.show(R.string.cov_detail_agent_leave)
//                                engine.leaveChannel()
//                                connectionState = AgentConnectionState.IDLE
//                                resetSceneState()
//                            }
//                        }
                    }
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                super.onAudioVolumeIndication(speakers, totalVolume)
                speakers?.forEach {
                    when (it.uid) {
                        CovAgoraManager.agentUID -> {
                            runOnUiThread {
                                // mBinding?.recordingAnimationView?.startVolumeAnimation(it.volume)
                                if (it.volume > 0) {
                                    mCovBallAnim?.updateAgentState(AgentState.SPEAKING,it.volume)
                                } else {
                                    mCovBallAnim?.updateAgentState(AgentState.LISTENING,it.volume)
                                }
                            }
                        }
                        0 -> {
                            runOnUiThread {
                                if (it.volume > 50) {
                                    // todo  0～10000
                                    mBinding?.btnMic?.setImageLevel(it.volume*50)
                                } else {
                                    mBinding?.btnMic?.setImageLevel(0)
                                }
                            }
                        }
                    }
                }
            }

            override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
                data?.let {
                    val rawString = String(it, Charsets.UTF_8)
                    val message = parser.parseStreamMessage(rawString)
                    message?.let { msg ->
                        handleStreamMessage(msg)
                    }
                }
            }

            override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
                if (uid == 0) {
                    runOnUiThread {
                        updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onTokenPrivilegeWillExpire(token: String?) {
                CovLogger.d(TAG, "onTokenPrivilegeWillExpire")
                CovAgoraManager.updateToken { isOK ->
                    if (isOK) {
                        engine.renewToken(CovAgoraManager.rtcToken)
                    } else {
                        onClickEndCall()
                    }
                }
            }
        })
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
            }
            if (isLocalAudioMuted) {
                isLocalAudioMuted = false
                engine.adjustRecordingSignalVolume(100)
            }
        }
    }

    private fun updateStateView() {
        mBinding?.apply {
            when (connectionState) {
                AgentConnectionState.IDLE -> {
                    llCalling.visibility = View.INVISIBLE
                    llJoinCall.visibility = View.VISIBLE
                    vConnecting.visibility = View.GONE
                }
                AgentConnectionState.CONNECTING -> {
                    llCalling.visibility = View.VISIBLE
                    llJoinCall.visibility = View.INVISIBLE
                    vConnecting.visibility = View.VISIBLE
                }
                AgentConnectionState.CONNECTED -> {
                    llCalling.visibility = View.VISIBLE
                    llJoinCall.visibility = View.INVISIBLE
                    vConnecting.visibility = View.GONE
                }
            }
        }
    }

    private fun updateMicrophoneView() {
        mBinding?.apply {
            if (isLocalAudioMuted) {
                btnMic.setImageResource(io.agora.scene.common.R.drawable.scene_detail_microphone0)
                btnMic.setBackgroundResource(io.agora.scene.common.R.color.ai_brand_white10)
            } else {
                btnMic.setImageResource(io.agora.scene.common.R.drawable.scene_detail_microphone)
                btnMic.setBackgroundResource(io.agora.scene.common.R.color.ai_block1)
            }
        }
    }

    private fun updateMessageList() {
        mBinding?.apply {
            if (isShowMessageList) {
                messageListView.visibility = View.VISIBLE
                btnCc.setColorFilter(getColor(io.agora.scene.common.R.color.ai_brand_main6), PorterDuff.Mode.SRC_IN)
            } else {
                messageListView.visibility = View.INVISIBLE
                btnCc.setColorFilter(getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
            }
        }
    }

    private fun updateNetworkStatus(value: Int) {
        networkValue = value
        infoDialog?.updateNetworkStatus(value)
        mBinding?.apply {
            when (value) {
                1, 2 -> {
                    btnInfo.setColorFilter(this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                }
                3, 4 -> {
                    btnInfo.setColorFilter(this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_yellow6), PorterDuff.Mode.SRC_IN)
                }
                else -> {
                    btnInfo.setColorFilter(this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_red6), PorterDuff.Mode.SRC_IN)
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
            }
            btnSettings.setOnClickListener {
                CovSettingsDialog().show(supportFragmentManager, "AgentSettingsSheetDialog")
            }
            btnCc.setOnClickListener {
                isShowMessageList = !isShowMessageList
            }
            btnInfo.setOnClickListener {
                infoDialog = CovAgentInfoDialog {
                    infoDialog = null
                }
                infoDialog?.updateNetworkStatus(networkValue)
                infoDialog?.show(supportFragmentManager, "InfoDialog")
            }
            llJoinCall.setOnClickListener {
                onClickStartAgent()
            }
        }
    }

    private fun setupBallAnimView() {
        val binding = mBinding ?: return
        mCovBallAnim = CovBallAnim(this, binding.videoContainer).apply {
            setupMediaPlayer(object : MediaPlayerCallback {
                override fun onError(error: Exception) {
                    CovLogger.e(TAG, "MediaPlayer error：$error")
                }
            })
        }
    }
}