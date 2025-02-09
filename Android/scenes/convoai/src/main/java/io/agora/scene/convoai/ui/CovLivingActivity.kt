package io.agora.scene.convoai.ui

import android.content.Intent
import android.graphics.PorterDuff
import android.util.Log
import android.view.View
import android.widget.Toast
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.convoai.manager.CovRtcManager
import io.agora.scene.convoai.utils.MessageParser
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.scene.common.BuildConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityLivingBinding
import io.agora.scene.convoai.manager.AgentConnectionState
import io.agora.scene.convoai.manager.AgentRequestParams
import io.agora.scene.convoai.manager.CovAgentManager
import kotlinx.coroutines.*
import kotlin.coroutines.*
import kotlin.random.Random

class CovLivingActivity : BaseActivity<CovActivityLivingBinding>() {

    private val TAG = "LivingActivity"

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
                CovAgentManager.connectionState = value
                updateStateView()
                if (connectionState == AgentConnectionState.CONNECTED) {
                    waitingAgentJob?.let {
                        it.cancel()
                        waitingAgentJob = null
                    }
                }
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
        updateToken {  }
        CovAgentManager.resetData()
        CovAgentManager.fetchPresets()
        createRtcEngine()
        setupBallAnimView()
        PermissionHelp(this).checkMicPerm({}, {
            finish()
        }, true)
    }

    override fun onDestroy() {
        super.onDestroy()
        // if agent is connected, leave channel
        if (connectionState == AgentConnectionState.CONNECTED) {
            stopAgentAndLeaveChannel()
        }
        CovRtcManager.resetData()
        CovAgentManager.resetData()
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
            channelName = CovRtcManager.channelName,
            remoteRtcUid = CovRtcManager.uid.toString(),
            agentRtcUid = CovAgentManager.agentUID.toString(),
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER,
            enableAiVad = CovAgentManager.enableAiVad,
            enableBHVS = CovAgentManager.enableBHVS,
            presetName = CovAgentManager.getPreset()?.name
        )
    }

    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    private var waitingAgentJob:Job?=null

    private fun onClickStartAgent() {
        mBinding?.messageListView?.updateAgentName(CovAgentManager.getPreset()?.name ?: "")
        connectionState = AgentConnectionState.CONNECTING
        CovRtcManager.channelName = "agora_" + Random.nextInt(1, 10000000).toString()
        coroutineScope.launch {
            CovLogger.d(TAG, "onClickStartAgent call startAgent")
            val agentDeferred = async(start = CoroutineStart.DEFAULT) { startAgentAsync() }
            val tokenDeferred = async(start = CoroutineStart.DEFAULT) { CovRtcManager.rtcToken?.let { true } ?: updateTokenAsync() }

            //先等待token完成，立即调用 joinChannel
            CovLogger.d(TAG, "onClickStartAgent await token 11")
            val isTokenOK = tokenDeferred.await()
            CovLogger.d(TAG, "onClickStartAgent await token 22")
            if (!isTokenOK) {
                connectionState = AgentConnectionState.IDLE
                CovLogger.e(TAG, "Token error")
                ToastUtil.show(R.string.cov_detail_join_call_failed, Toast.LENGTH_LONG)
                return@launch
            }
            CovLogger.d(TAG, "onClickStartAgent call join")
            CovRtcManager.joinChannel()

            CovLogger.d(TAG, "onClickStartAgent await agent 11")
            val isAgentOK = agentDeferred.await()
            CovLogger.d(TAG, "onClickStartAgent await agent 22")
            if (isAgentOK) {
                // check agent connection after 10s
                waitingAgentJob = launch(Dispatchers.Main) {
                    delay(10000)
                    if (connectionState == AgentConnectionState.CONNECTING) {
                        stopAgentAndLeaveChannel()
                        CovLogger.e(TAG, "Agent connection timeout")
                        ToastUtil.show(R.string.cov_detail_join_call_failed, Toast.LENGTH_LONG)
                    }
                }
            } else {
                connectionState = AgentConnectionState.IDLE
                CovLogger.e(TAG, "Agent error")
                ToastUtil.show(R.string.cov_detail_join_call_failed, Toast.LENGTH_LONG)
            }
        }
    }

    private suspend fun startAgentAsync(): Boolean = suspendCoroutine { cont ->
        CovAgentManager.startAgent(getAgentParams()) { isAgentOK ->
            cont.resume(isAgentOK)
        }
    }

    private suspend fun updateTokenAsync(): Boolean = suspendCoroutine { cont ->
        updateToken { isTokenOK ->
            cont.resume(isTokenOK)
        }
    }

    private fun onClickEndCall() {
        stopAgentAndLeaveChannel()
        ToastUtil.show(R.string.cov_detail_agent_leave)
    }

    private fun stopAgentAndLeaveChannel() {
        CovRtcManager.leaveChannel()
        if (connectionState == AgentConnectionState.IDLE) {
            return
        }
        connectionState = AgentConnectionState.IDLE
        mCovBallAnim?.updateAgentState(AgentState.STATIC)
        CovAgentManager.stopAgent {}
        resetSceneState()
    }

    private fun updateToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            CovRtcManager.uid.toString(),
            TokenGeneratorType.Token007,
            AgoraTokenType.Rtc,
            success = { token ->
                CovLogger.d(TAG, "getToken success")
                CovRtcManager.rtcToken = token
                complete.invoke(true)
            },
            failure = { e ->
                CovLogger.d(TAG, "getToken error $e")
                complete.invoke(false)
            })
    }

    private fun createRtcEngine() {
        CovRtcManager.createRtcEngine(object : IRtcEngineEventHandler() {
            override fun onError(err: Int) {
                super.onError(err)
                CovLogger.e(TAG, "Rtc Error code:$err")
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
                    if (uid == CovAgentManager.agentUID) {
                        connectionState = AgentConnectionState.CONNECTED
                        ToastUtil.show(R.string.cov_detail_join_call_succeed)
                    }
                }
                CovLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                CovLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == CovAgentManager.agentUID) {
                    runOnUiThread {
                        mCovBallAnim?.updateAgentState(AgentState.STATIC, 0)
                        CovLogger.d(TAG, "start agent reconnect")
                        // toast error message, guide user to click to end call
                        ToastUtil.show(R.string.cov_detail_agent_leave)
                    }
                }
            }

            override fun onConnectionStateChanged(state: Int, reason: Int) {
                when (state) {
                    Constants.CONNECTION_STATE_CONNECTED -> {
                        if (reason == Constants.CONNECTION_CHANGED_REJOIN_SUCCESS) {
                            CovLogger.d(TAG, "onConnectionStateChanged: login")
                        }
                    }
                    Constants.CONNECTION_STATE_CONNECTING -> {
                        CovLogger.d(TAG, "onConnectionStateChanged: connecting")
                    }
                    Constants.CONNECTION_STATE_DISCONNECTED -> {
                        CovLogger.d(TAG, "onConnectionStateChanged: disconnected")
                    }
                    Constants.CONNECTION_STATE_RECONNECTING -> {
                        if (reason == Constants.CONNECTION_CHANGED_INTERRUPTED) {
                            CovLogger.d(TAG, "onConnectionStateChanged: login")
                        }
                    }
                    Constants.CONNECTION_STATE_FAILED -> {
                        if (reason == Constants.CONNECTION_CHANGED_JOIN_FAILED) {
                            CovLogger.d(TAG, "onConnectionStateChanged: login")
                        }
                    }
                }

                if (state == Constants.CONNECTION_STATE_FAILED) {
                    runOnUiThread {
                        stopAgentAndLeaveChannel()
                        ToastUtil.show(R.string.cov_detail_join_call_failed, Toast.LENGTH_LONG)
                    }
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                super.onAudioVolumeIndication(speakers, totalVolume)
                speakers?.forEach {
                    when (it.uid) {
                        CovAgentManager.agentUID -> {
                            runOnUiThread {
                                if (BuildConfig.DEBUG){
                                    Log.d(TAG,"onAudioVolumeIndication ${it.uid} ${it.volume}")
                                }
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
                                updateUserVolumeAnim(it.volume)
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
                        CovLogger.d(TAG, "onNetworkQuality $rxQuality")
                        updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onTokenPrivilegeWillExpire(token: String?) {
                CovLogger.d(TAG, "onTokenPrivilegeWillExpire")
                updateToken { isOK ->
                    if (isOK) {
                        CovRtcManager.renewRtcToken()
                    } else {
                        stopAgentAndLeaveChannel()
                        ToastUtil.show("renew token error")
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

    private fun updateUserVolumeAnim(volume: Int){
        if (volume > 10) {
            // todo  0～10000
            var level = volume * 50 + 1000
            if (level > 10000) level = 10000
            mBinding?.btnMic?.setImageLevel(level)
        } else {
            mBinding?.btnMic?.setImageLevel(0)
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
                CovRtcManager.muteLocalAudio(isLocalAudioMuted)
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
                btnMic.setBackgroundResource(io.agora.scene.common.R.drawable.btn_bg_brand_white_selector)
            } else {
                btnMic.setImageResource(io.agora.scene.common.R.drawable.agent_user_speaker)
                btnMic.setBackgroundResource(io.agora.scene.common.R.drawable.btn_bg_block1_selector)
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
                3, 4 -> {
                    btnInfo.setColorFilter(
                        this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_yellow6),
                        PorterDuff.Mode.SRC_IN
                    )
                }

                5, 6 -> {
                    btnInfo.setColorFilter(
                        this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_red6),
                        PorterDuff.Mode.SRC_IN
                    )
                }

                else -> {
                    btnInfo.setColorFilter(
                        this@CovLivingActivity.getColor(io.agora.scene.common.R.color.ai_icontext1),
                        PorterDuff.Mode.SRC_IN
                    )
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
                CovRtcManager.muteLocalAudio(isLocalAudioMuted)
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
        mCovBallAnim = CovBallAnim(this, binding.videoView).apply {
            CovRtcManager.rtcEngine?.let {
                setupMediaPlayer(it)
            }
        }
    }
}