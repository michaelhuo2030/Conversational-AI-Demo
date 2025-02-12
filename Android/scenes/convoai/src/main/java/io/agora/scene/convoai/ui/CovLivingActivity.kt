package io.agora.scene.convoai.ui

import android.content.Intent
import android.graphics.PorterDuff
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.core.content.res.ResourcesCompat
import androidx.core.view.isVisible
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.convoai.manager.CovRtcManager
import io.agora.scene.convoai.utils.MessageParser
import io.agora.rtc2.Constants
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.BuildConfig
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.copyToClipboard
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovActivityLivingBinding
import io.agora.scene.convoai.manager.AgentConnectionState
import io.agora.scene.convoai.manager.AgentRequestParams
import io.agora.scene.convoai.manager.CovAgentManager
import io.agora.scene.convoai.manager.CovAgentPreset
import io.agora.scene.convoai.manager.CovServerManager
import kotlinx.coroutines.*
import java.util.UUID
import kotlin.coroutines.*

class CovLivingActivity : BaseActivity<CovActivityLivingBinding>() {

    private val TAG = "LivingActivity"

    private var infoDialog: CovAgentInfoDialog? = null

    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    private var waitingAgentJob: Job? = null

    private var pingJob: Job? = null

    // Add a coroutine scope for log processing
    private val logScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private var networkValue: Int = 0

    private var parser = MessageParser()

    private var rtcToken: String? = null

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
                    waitingAgentJob?.cancel()
                    waitingAgentJob = null

                    // 使用协程替代 Timer 进行 ping
                    pingJob = coroutineScope.launch {
                        while (isActive) {
                            val presetName = CovAgentManager.getPreset()?.name ?: return@launch
                            CovServerManager.ping(CovAgentManager.channelName, presetName) {}
                            delay(10000) // 10秒间隔
                        }
                    }
                } else if (connectionState == AgentConnectionState.IDLE) {
                    // 取消 ping
                    pingJob?.cancel()
                    pingJob = null
                    waitingAgentJob?.cancel()
                    waitingAgentJob = null
                } else if (connectionState == AgentConnectionState.CONNECTED_INTERRUPT) {
                    mCovBallAnim?.updateAgentState(AgentState.STATIC)
                }
            }
        }

    // Add a flag to indicate whether the call was ended by the user
    private var isUserEndCall = false

    private var mCovBallAnim: CovBallAnim? = null

    private var mDebugSettingBean: CovDebugDialog.DebugSettingBean? = null

    override fun getViewBinding(): CovActivityLivingBinding {
        return CovActivityLivingBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        updateStateView()
        CovAgentManager.resetData()
        val rtcEngine = createRtcEngine()
        setupBallAnimView(rtcEngine)
        PermissionHelp(this).checkMicPerm({}, {
            finish()
        }, true)

        // Fetch token and presets when entering the scene
        coroutineScope.launch {
            val deferreds = listOf(
                async { updateTokenAsync() },
                async { fetchPresetsAsync() }
            )
            deferreds.awaitAll()
        }
    }

    override fun onHandleOnBackPressed() {
        super.onHandleOnBackPressed()
    }

    override fun finish() {
        logScope.cancel()
        coroutineScope.cancel()

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
        super.finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        CovLogger.d(TAG,"activity onDestroy")
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
            channelName = CovAgentManager.channelName,
            remoteRtcUid = CovAgentManager.uid.toString(),
            agentRtcUid = CovAgentManager.agentUID.toString(),
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER,
            enableAiVad = CovAgentManager.enableAiVad,
            enableBHVS = CovAgentManager.enableBHVS,
            presetName = CovAgentManager.getPreset()?.name,
            asrLanguage = CovAgentManager.language?.language_code,
        )
    }

    private fun onClickStartAgent() {
        // Immediately show the connecting status
        connectionState = AgentConnectionState.CONNECTING
        CovAgentManager.channelName = "agent_" + UUID.randomUUID().toString().replace("-", "")

        coroutineScope.launch(Dispatchers.IO) {
            val needToken = rtcToken == null
            val needPresets = CovAgentManager.getPresetList().isNullOrEmpty()

            if (needToken || needPresets) {
                val deferreds = buildList {
                    if (needToken) add(async { updateTokenAsync() })
                    if (needPresets) add(async { fetchPresetsAsync() })
                }
                // Check whether all tasks are successful
                val results = deferreds.awaitAll()
                if (results.any { !it }) {
                    withContext(Dispatchers.Main) {
                        connectionState = AgentConnectionState.IDLE
                        ToastUtil.show(getString(R.string.cov_detail_join_call_failed), Toast.LENGTH_LONG)
                    }
                    return@launch
                }
            }
            withContext(Dispatchers.Main) {
                mBinding?.messageListView?.updateAgentName(CovAgentManager.getPreset()?.display_name ?: "")
            }

            CovRtcManager.joinChannel(rtcToken ?: "", CovAgentManager.channelName, CovAgentManager.uid)
            val startRet = startAgentAsync()

            withContext(Dispatchers.Main) {
                val channelName = startRet.first
                if (channelName != CovAgentManager.channelName) {
                    return@withContext
                }
                val isAgentOK = startRet.second
                if (isAgentOK) {
                    // Startup timeout check
                    waitingAgentJob = launch {
                        delay(10000)
                        if (connectionState == AgentConnectionState.CONNECTING) {
                            stopAgentAndLeaveChannel()
                            CovLogger.e(TAG, "Agent connection timeout")
                            ToastUtil.show(getString(R.string.cov_detail_join_call_failed), Toast.LENGTH_LONG)
                        }
                    }
                } else {
                    connectionState = AgentConnectionState.IDLE
                    CovRtcManager.leaveChannel()
                    CovLogger.e(TAG, "Agent start error")
                    ToastUtil.show(getString(R.string.cov_detail_join_call_failed), Toast.LENGTH_LONG)
                }
            }
        }
    }

    private suspend fun startAgentAsync(): Pair<String, Boolean> = suspendCoroutine { cont ->
        CovServerManager.startAgent(getAgentParams()) { channelName, isAgentOK ->
            cont.resume(Pair(channelName, isAgentOK))
        }
    }

    private suspend fun updateTokenAsync(): Boolean = suspendCoroutine { cont ->
        updateToken { isTokenOK ->
            cont.resume(isTokenOK)
        }
    }

    private suspend fun fetchPresetsAsync(): Boolean = suspendCoroutine { cont ->
        CovServerManager.fetchPresets { presets ->
            if (presets.isNullOrEmpty()) {
                cont.resume(false)
            } else {
                CovAgentManager.setPresetList(presets)
                cont.resume(true)
            }
        }
    }

    private fun onClickEndCall() {
        isUserEndCall = true
        stopAgentAndLeaveChannel()
        ToastUtil.show(getString(R.string.cov_detail_agent_leave))
    }

    private fun stopAgentAndLeaveChannel() {
        CovRtcManager.leaveChannel()
        if (connectionState == AgentConnectionState.IDLE) {
            return
        }
        connectionState = AgentConnectionState.IDLE
        mCovBallAnim?.updateAgentState(AgentState.STATIC)
        CovServerManager.stopAgent(CovAgentManager.channelName ,CovAgentManager.getPreset()?.name) {}
        resetSceneState()
    }

    private fun updateToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            CovAgentManager.uid.toString(),
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

    private fun createRtcEngine(): RtcEngineEx {
        return CovRtcManager.createRtcEngine(object : IRtcEngineEventHandler() {
            override fun onError(err: Int) {
                super.onError(err)
                logScope.launch {
                    CovLogger.e(TAG, "Rtc Error code:$err")
                }
            }

            override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
                logScope.launch {
                    CovLogger.d(TAG, "local user didJoinChannel uid: $uid")
                }
                runOnUiThread {
                    updateNetworkStatus(1)
                }
            }

            override fun onLeaveChannel(stats: RtcStats?) {
                logScope.launch {
                    CovLogger.d(TAG, "local user didLeaveChannel")
                }
                runOnUiThread {
                    updateNetworkStatus(1)
                }
            }

            override fun onUserJoined(uid: Int, elapsed: Int) {
                logScope.launch {
                    CovLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
                }
                runOnUiThread {
                    if (uid == CovAgentManager.agentUID) {
                        connectionState = AgentConnectionState.CONNECTED
                        ToastUtil.show(getString(R.string.cov_detail_join_call_succeed))
                    }
                }
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                logScope.launch {
                    CovLogger.d(TAG, "remote user onUserOffline uid: $uid")
                }
                runOnUiThread {
                    if (uid == CovAgentManager.agentUID) {
                        mCovBallAnim?.updateAgentState(AgentState.STATIC)
                        if (!isUserEndCall) {
                            ToastUtil.show(getString(R.string.cov_detail_agent_state_error), Toast.LENGTH_LONG)
                        }
                    }
                }
            }

            override fun onConnectionStateChanged(state: Int, reason: Int) {
                runOnUiThread {
                    when (state) {
                        Constants.CONNECTION_STATE_CONNECTED -> {
                            if (reason == Constants.CONNECTION_CHANGED_REJOIN_SUCCESS) {
                                connectionState = AgentConnectionState.CONNECTED
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
                                connectionState = AgentConnectionState.CONNECTED_INTERRUPT
                                ToastUtil.show(getString(R.string.cov_detail_net_state_error), Toast.LENGTH_LONG)
                            }
                        }

                        Constants.CONNECTION_STATE_FAILED -> {
                            if (reason == Constants.CONNECTION_CHANGED_JOIN_FAILED) {
                                CovLogger.d(TAG, "onConnectionStateChanged: login")
                                connectionState = AgentConnectionState.CONNECTED_INTERRUPT
                                ToastUtil.show(getString(R.string.cov_detail_net_state_error), Toast.LENGTH_LONG)
                            }
                        }
                    }
                }
            }

            override fun onRemoteAudioStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
                super.onRemoteAudioStateChanged(uid, state, reason, elapsed)
                runOnUiThread{
                    if (uid == CovAgentManager.agentUID) {
                        if (BuildConfig.DEBUG) {
                            Log.d(TAG, "onRemoteAudioStateChanged $uid $state $reason")
                        }
                        if (state == Constants.REMOTE_AUDIO_STATE_STOPPED) {
                            mCovBallAnim?.updateAgentState(AgentState.LISTENING)
                        }
                    }
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                runOnUiThread {
                    speakers?.forEach {
                        when (it.uid) {
                            CovAgentManager.agentUID -> {
                                if (BuildConfig.DEBUG) {
                                    Log.d(TAG, "onAudioVolumeIndication ${it.uid} ${it.volume}")
                                }
                                // mBinding?.recordingAnimationView?.startVolumeAnimation(it.volume)
                                if (it.volume > 0) {
                                    mCovBallAnim?.updateAgentState(AgentState.SPEAKING, it.volume)
                                } else {
                                    mCovBallAnim?.updateAgentState(AgentState.LISTENING, it.volume)
                                }
                            }

                            0 -> {
                                updateUserVolumeAnim(it.volume)
                            }
                        }
                    }
                }
            }

            override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
                data?.let { bytes ->
                    try {
                        val rawString = String(bytes, Charsets.UTF_8)
                        val message = parser.parseStreamMessage(rawString)
                        message?.let { msg ->
                            CovLogger.d(TAG, "onStreamMessage: $msg")
                            val isFinal = msg["is_final"] as? Boolean ?: false
                            val streamId = msg["stream_id"] as? Double ?: 0.0
                            val turnId = msg["turn_id"] as? Double ?: 0.0
                            val text = msg["text"] as? String ?: ""
                            if (text.isNotEmpty()) {
                                runOnUiThread {
                                    mBinding?.messageListView?.updateStreamContent(
                                        (streamId != 0.0), turnId, text, isFinal
                                    )
                                }
                            }
                        }
                    } catch (e: Exception) {
                        CovLogger.e(TAG, "Process stream message error: ${e.message}")
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
                updateToken { isOK ->
                    if (isOK) {
                        CovRtcManager.renewRtcToken(rtcToken ?: "")
                    } else {
                        stopAgentAndLeaveChannel()
                        ToastUtil.show("renew token error")
                    }
                }
            }
        })
    }

    private fun updateUserVolumeAnim(volume: Int) {
        if (volume > 10) {
            // todo  0～10000 icon high 20 top 6
            var level = volume * 20 + 3500
            if (level > 8500) level = 8500
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
                AgentConnectionState.CONNECTED,
                AgentConnectionState.CONNECTED_INTERRUPT -> {
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

    private val onPresetCallback = object :CovSettingsDialog.Callback{
        override fun onPreset(preset: CovAgentPreset) {
            mBinding?.apply {
                if (preset.isIndependent()){
                    btnCc.isEnabled = false
                    btnCc.setBackgroundColor(ResourcesCompat.getColor(resources,
                        io.agora.scene.common.R.color.ai_disable,null))
                    btnCc.setColorFilter(getColor(io.agora.scene.common.R.color.ai_disable1), PorterDuff.Mode.SRC_IN)
                }else{
                    btnCc.isEnabled = true
                    btnCc.setBackgroundResource(io.agora.scene.common.R.drawable.btn_bg_block1_selector)
                    btnCc.setColorFilter(getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                }
            }
        }
    }

    private fun setupView() {
        mBinding?.apply {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            setOnApplyWindowInsetsListener(root)
            mDebugSettingBean = CovDebugDialog.DebugSettingBean(object : CovDebugDialog.Callback {
                override fun onAudioDumpEnable(enable: Boolean) {
                    CovRtcManager.onAudioDump(enable)
                }

                override fun onDebugEnable(enable: Boolean) {
                    btnDebug.isVisible = ServerConfig.isDebug
                }

                override fun onClickCopy() {
                    val messageContents = messageListView.getAllMessages()
                        .filter { it.isMe }
                        .map { it.content }
                        .joinToString("\n")
                    this@CovLivingActivity.copyToClipboard(messageContents)
                    ToastUtil.show(getString(R.string.cov_copy_succeed))
                }
            })
            btnDebug.isVisible = ServerConfig.isDebug
            btnDebug.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    CovLogger.d(TAG,"showCovDebugDialog called")
                    val debug = mDebugSettingBean?:return
                    val dialog = CovDebugDialog(debug)
                    dialog.show(supportFragmentManager, "debugSettings")
                }
            })
            btnBack.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onHandleOnBackPressed()
                }
            })
            btnEndCall.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickEndCall()
                }
            })
            btnMic.setOnClickListener {
                isLocalAudioMuted = !isLocalAudioMuted
                CovRtcManager.muteLocalAudio(isLocalAudioMuted)
            }
            btnSettings.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (CovAgentManager.getPresetList().isNullOrEmpty()) {
                        coroutineScope.launch {
                            val success = fetchPresetsAsync()
                            if (success) {
                                val dialog = CovSettingsDialog().apply {
                                    onCallBack = onPresetCallback
                                }
                                dialog.show(supportFragmentManager, "AgentSettingsSheetDialog")
                            } else {
                                ToastUtil.show(getString(R.string.cov_detail_net_state_error))
                            }
                        }
                    } else {
                        val dialog = CovSettingsDialog().apply {
                            onCallBack = onPresetCallback
                        }
                        dialog.show(supportFragmentManager, "AgentSettingsSheetDialog")
                    }
                }
            })
            btnCc.setOnClickListener {
                isShowMessageList = !isShowMessageList
            }
            btnInfo.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    infoDialog = CovAgentInfoDialog {
                        infoDialog = null
                    }
                    infoDialog?.updateNetworkStatus(networkValue)
                    infoDialog?.show(supportFragmentManager, "InfoDialog")
                }
            })
            llJoinCall.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onClickStartAgent()
                }
            })
        }
    }

    private fun setupBallAnimView(rtcEngine: RtcEngineEx) {
        val binding = mBinding ?: return
        mCovBallAnim = CovBallAnim(this, binding.videoView).apply {
            setupMediaPlayer(rtcEngine)
        }
    }
}