package io.agora.scene.digitalhuman.ui

import android.content.Intent
import android.util.Log
import android.view.TextureView
import android.view.View
import android.widget.FrameLayout
import android.widget.Toast
import androidx.core.view.isVisible
import io.agora.scene.common.AgentApp
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.net.AgoraTokenType
import io.agora.scene.common.net.TokenGenerator
import io.agora.scene.common.net.TokenGeneratorType
import io.agora.scene.common.ui.BaseActivity
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.util.PermissionHelp
import io.agora.scene.digitalhuman.http.AgentRequestParams
import io.agora.scene.digitalhuman.rtc.DigitalAgoraManager
import io.agora.rtc2.ChannelMediaOptions
import io.agora.rtc2.Constants
import io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.rtc2.video.VideoCanvas
import io.agora.scene.digitalhuman.DigitalLogger
import io.agora.scene.digitalhuman.databinding.DigitalActivityLivingBinding
import io.agora.scene.digitalhuman.http.DigitalApiManager
import io.agora.scene.digitalhuman.rtc.AgentPresetType
import io.agora.scene.digitalhuman.rtc.DigitalAgentObserver
import kotlin.random.Random

class DigitalLivingActivity : BaseActivity<DigitalActivityLivingBinding>() {

    private val TAG = "LivingActivity"

    private lateinit var engine: RtcEngineEx

    private var loadingDialog: LoadingDialog? = null

    private var networkDialog: DigitalNetworkDialog? = null

    private var isLocalAudioMuted = false
    private var isLocalVideoMuted = false
    private var isRemoteVideoMuted = false
    private var rtcToken: String? = null
    private var channelName = ""
    private var localUid: Int = 0
    private val agentUID = 999
    private var networkStatus: Int? = null

    var isAgentStarted = false
        set(value) {
            if (field != value) {
                field = value
                updateCenterView()
            }
        }

    private val mLocalVideoView: TextureView by lazy {
        TextureView(this)
    }

    private val mRemoteVideoView: TextureView by lazy {
        TextureView(this)
    }

    override fun getViewBinding(): DigitalActivityLivingBinding {
        return DigitalActivityLivingBinding.inflate(layoutInflater)
    }

    override fun initView() {
        setupView()
        updateCenterView()
        // data
        DigitalAgoraManager.resetData()
        createRtcEngine()
        loadingDialog = LoadingDialog(this)
        channelName = "agora_" + Random.nextInt(1, 10000000).toString()
        localUid = Random.nextInt(1000, 10000000)
        getToken { }
        PermissionHelp(this).checkCameraAndMicPerms({}, {
            finish()
        }, true
        )
        DigitalAgoraManager.registerDigitalAgentObserver(digitalAgentObserver)
    }

    private val digitalAgentObserver = object : DigitalAgentObserver {
        override fun onPresetType(type: AgentPresetType) {
            mBinding?.apply {
                val remoteWindow = vDragBigWindow
                remoteWindow.setUserName(DigitalAgoraManager.presetType.value, true)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        engine.leaveChannel()
        DigitalApiManager.stopAgent { ok ->
            if (ok) {
                Log.d(TAG, "Agent stopped successfully")
            } else {
                Log.d(TAG, "Failed to stop agent")
            }
            DigitalApiManager.destroy()
        }
        RtcEngineEx.destroy()
        DigitalAgoraManager.unRegisterDigitalAgentObserver(digitalAgentObserver)
        DigitalAgoraManager.resetData()
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

    private fun onClickStartAgent() {
        if (!smallContainerIsLocal){
            exchangeDragWindow()
        }
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
        loadingDialog?.show()
        DigitalAgoraManager.channelName = channelName
        DigitalAgoraManager.uid = localUid
        val params = AgentRequestParams(
            channelName = channelName,
            remoteRtcUid = localUid,
            agentRtcUid = agentUID,
            ttsVoiceId = DigitalAgoraManager.voiceType.value,
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER
        )
        DigitalApiManager.startAgent(params) { isAgentOK ->
            if (isAgentOK) {
                if (rtcToken == null) {
                    getToken { isTokenOK ->
                        if (isTokenOK) {
                            joinChannel()
                        } else {
                            loadingDialog?.dismiss()
                            DigitalLogger.e(TAG, "Token error")
                            Toast.makeText(
                                this, io.agora.scene.common.R.string.cov_detail_join_call_failed, Toast.LENGTH_SHORT
                            ).show()
                        }
                    }
                } else {
                    joinChannel()
                }
            } else {
                loadingDialog?.dismiss()
                DigitalLogger.e(TAG, "Agent error")
                Toast.makeText(
                    this,
                    io.agora.scene.common.R.string.cov_detail_join_call_failed, Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    private fun onClickEndCall() {
        engine.stopPreview()
        engine.leaveChannel()
        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_ending))
        loadingDialog?.show()
        DigitalApiManager.stopAgent { ok ->
            loadingDialog?.dismiss()
            if (ok) {
                Toast.makeText(this, io.agora.scene.common.R.string.cov_detail_agent_leave, Toast.LENGTH_SHORT).show()
                isAgentStarted = false
                networkStatus = null
                DigitalAgoraManager.agentStarted = false
                resetSceneState()
            } else {
                Toast.makeText(this, "Agent Leave Failed", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private val channelOption: ChannelMediaOptions by lazy {
        ChannelMediaOptions().apply {
            clientRoleType = CLIENT_ROLE_BROADCASTER
            publishMicrophoneTrack = true
            publishCameraTrack = true
            autoSubscribeAudio = true
            autoSubscribeVideo = true
        }
    }

    private fun joinChannel() {
        mBinding?.apply {
            vDragSmallWindow.canvasContainerAddView(mLocalVideoView)
            vDragBigWindow.canvasContainerAddView(mRemoteVideoView)
        }
        DigitalLogger.e(
            TAG,
            "onClickStartAgent: rtcToken: $rtcToken, channelName: $channelName, localUid: $localUid, agentUID: $agentUID"
        )
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        engine.setParameters("{\"che.audio.sf.enabled\":false}")
        DigitalAgoraManager.updateDenoise(true)
        engine.startPreview()
        val ret = engine.joinChannel(rtcToken, channelName, localUid, channelOption)
        DigitalLogger.d(TAG, "Joining RTC channel: $channelName, uid: $localUid, ret: $ret")
    }

    private fun getToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            localUid.toString(),
            TokenGeneratorType.Token007,
            AgoraTokenType.Rtc,
            success = { token ->
                DigitalLogger.d(TAG, "getToken success $token")
                rtcToken = token
                complete.invoke(true)
            },
            failure = { e ->
                DigitalLogger.d(TAG, "getToken error $e")
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
                DigitalLogger.e(TAG, "Rtc Error code:$err, msg:" + RtcEngineEx.getErrorDescription(err))
            }

            override fun onJoinChannelSuccess(channel: String?, uid: Int, elapsed: Int) {
                DigitalLogger.d(TAG, "local user didJoinChannel uid: $uid")
                runOnUiThread {
                    updateNetworkStatus(Constants.QUALITY_EXCELLENT)
                    setupLocalView(true)
                    updateLocalViewState(isLocalVideoMuted)
                }
            }

            override fun onLeaveChannel(stats: RtcStats?) {
                DigitalLogger.d(TAG, "local user didLeaveChannel")
                runOnUiThread {
                    updateNetworkStatus(Constants.QUALITY_UNKNOWN)
                    setupLocalView(false)
                }
            }

            override fun onUserJoined(uid: Int, elapsed: Int) {
                runOnUiThread {
                    if (uid == agentUID) {
                        setupRemoteView(uid, true)
                        updateRemoteViewState(isRemoteVideoMuted)
                        isAgentStarted = true
                        DigitalAgoraManager.agentStarted = true
                        loadingDialog?.dismiss()
                        Toast.makeText(
                            this@DigitalLivingActivity,
                            io.agora.scene.common.R.string.cov_detail_join_call_succeed,
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }
                DigitalLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                DigitalLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == agentUID) {
                    runOnUiThread {
                        setupRemoteView(uid, false)
                        DigitalLogger.d(TAG, "start agent reconnect")
                        rtcToken = null
                        // reconnect
                        loadingDialog?.setMessage(getString(io.agora.scene.common.R.string.cov_detail_agent_joining))
                        loadingDialog?.show()
                        val params = AgentRequestParams(
                            channelName = channelName,
                            remoteRtcUid = localUid,
                            agentRtcUid = agentUID,
                            ttsVoiceId = DigitalAgoraManager.voiceType.value,
                            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER
                        )
                        DigitalApiManager.startAgent(params) { isAgentOK ->
                            if (!isAgentOK) {
                                loadingDialog?.dismiss()
                                Toast.makeText(
                                    this@DigitalLivingActivity,
                                    io.agora.scene.common.R.string.cov_detail_agent_leave,
                                    Toast.LENGTH_SHORT
                                ).show()
                                engine.leaveChannel()
                                isAgentStarted = false
                                DigitalAgoraManager.agentStarted = false
                                resetSceneState()
                            }
                        }
                    }
                }
            }

            override fun onLocalVideoStateChanged(source: Constants.VideoSourceType?, state: Int, reason: Int) {
                super.onLocalVideoStateChanged(source, state, reason)
                runOnUiThread { }
            }

            override fun onRemoteVideoStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
                super.onRemoteVideoStateChanged(uid, state, reason, elapsed)
                if (uid != DigitalAgoraManager.uid) return
                runOnUiThread {
                    if (reason == Constants.REMOTE_VIDEO_STATE_REASON_REMOTE_MUTED) {
                        isRemoteVideoMuted = true
                    } else if (reason == Constants.REMOTE_VIDEO_STATE_REASON_REMOTE_UNMUTED) {
                        isRemoteVideoMuted = false
                    }
                    updateRemoteViewState(isRemoteVideoMuted)
                }
            }

            override fun onAudioVolumeIndication(
                speakers: Array<out AudioVolumeInfo>?, totalVolume: Int
            ) {
                super.onAudioVolumeIndication(speakers, totalVolume)
                speakers?.forEach {
                    if (it.uid == agentUID) {
                        runOnUiThread {
                        }
                    }
                }
            }

            override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
                DigitalLogger.d(TAG, "onNetworkQuality uid: $uid, txQuality: $txQuality, rxQuality: $rxQuality")
                if (uid == 0) {
                    runOnUiThread {
                        Constants.QUALITY_GOOD
                        updateNetworkStatus(rxQuality)
                        networkDialog?.updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onTokenPrivilegeWillExpire(token: String?) {
                DigitalLogger.d(TAG, "onTokenPrivilegeWillExpire")
                getToken { isOK ->
                    if (isOK) {
                        engine.renewToken(rtcToken)
                    } else {
                        onClickEndCall()
                    }
                }
            }
        }
        engine = (RtcEngineEx.create(config) as RtcEngineEx).apply {
            //set audio scenario 10，open AI-QoS
            setAudioScenario(Constants.AUDIO_SCENARIO_AI_CLIENT)
            enableAudioVolumeIndication(100, 10, true)
            enableVideo()
            adjustRecordingSignalVolume(100)
        }
        DigitalAgoraManager.rtcEngine = engine
    }

    private fun setupLocalView(join: Boolean) {
        if (join) {
            engine.setupLocalVideo(VideoCanvas(mLocalVideoView, VideoCanvas.RENDER_MODE_HIDDEN, 0))
        } else {
            engine.setupLocalVideo(VideoCanvas(null, VideoCanvas.RENDER_MODE_HIDDEN, 0))
        }
    }

    private fun updateLocalViewState(isLocalVideoMuted: Boolean) {
        mBinding?.apply {
            val localWindow = vDragSmallWindow
            localWindow.setUserName(getString(io.agora.scene.common.R.string.digital_youselft), false)
            localWindow.setUserAvatar(isLocalVideoMuted)
            if (smallContainerIsLocal) {
                localWindow.switchCamera.setOnClickListener(null)
                localWindow.switchCamera.isVisible = false
            } else {
                localWindow.switchCamera.setOnClickListener {
                    engine.switchCamera()
                }
                localWindow.switchCamera.isVisible = true
            }
            btnCamera.setBackgroundResource(
                if (isLocalVideoMuted) io.agora.scene.common.R.drawable.app_living_camera_off else io.agora.scene.common.R.drawable.app_living_camera_on
            )
            localWindow.canvasContainer.isVisible = !isLocalVideoMuted
        }
    }

    private fun setupRemoteView(uid: Int, join: Boolean) {
        if (join) {
            engine.setupRemoteVideo(VideoCanvas(mRemoteVideoView, VideoCanvas.RENDER_MODE_HIDDEN, uid))
        } else {
            engine.setupRemoteVideo(VideoCanvas(null, VideoCanvas.RENDER_MODE_HIDDEN, uid))
        }
    }

    private fun updateRemoteViewState(isRemoteVideoMuted: Boolean) {
        mBinding?.apply {
            val remoteWindow = vDragBigWindow
            remoteWindow.setUserName(DigitalAgoraManager.presetType.value, true)
            remoteWindow.setUserAvatar(isRemoteVideoMuted)
            remoteWindow.switchCamera.setOnClickListener(null)
            remoteWindow.switchCamera.isVisible = false
            remoteWindow.canvasContainer.isVisible = !isRemoteVideoMuted
        }
    }

    private fun resetSceneState() {
        mBinding?.apply {
            if (isLocalAudioMuted) {
                isLocalAudioMuted = false
                engine.adjustRecordingSignalVolume(100)
                btnMic.setBackgroundResource(io.agora.scene.common.R.drawable.app_living_mic_on)
            }
            if (isLocalVideoMuted) {
                isLocalVideoMuted = false
            }
        }

    }

    private fun updateCenterView() {
        if (!isAgentStarted) {
            mBinding?.apply {
                llCalling.visibility = View.INVISIBLE
                vNotJoined.root.visibility = View.VISIBLE
                llJoinCall.visibility = View.VISIBLE
                layoutContainer.visibility = View.INVISIBLE
            }
            return
        }
        mBinding?.apply {
            llCalling.visibility = View.VISIBLE
            vNotJoined.root.visibility = View.INVISIBLE
            llJoinCall.visibility = View.INVISIBLE
            layoutContainer.visibility = View.VISIBLE
        }
    }

    private fun updateNetworkStatus(value: Int) {
        networkStatus = value
        mBinding?.apply {
            when (value) {
                Constants.QUALITY_EXCELLENT, Constants.QUALITY_GOOD -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_good)
                }

                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_okay)
                }

                else -> {
                    btnWifi.setImageResource(io.agora.scene.common.R.drawable.scene_detail_net_poor)
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
            llEndCall.setOnClickListener {
                onClickEndCall()
            }
            btnMic.setOnClickListener {
                isLocalAudioMuted = !isLocalAudioMuted
                engine.adjustRecordingSignalVolume(if (isLocalAudioMuted) 0 else 100)
                btnMic.setBackgroundResource(
                    if (isLocalAudioMuted) io.agora.scene.common.R.drawable.app_living_mic_off else io.agora.scene.common.R.drawable.app_living_mic_on
                )
            }
            btnCamera.setOnClickListener {
                isLocalVideoMuted = !isLocalVideoMuted
                if (isLocalVideoMuted) {
                    engine.stopPreview()
                    engine.muteLocalVideoStream(true)
                } else {
                    engine.startPreview()
                    engine.muteLocalVideoStream(false)
                }
                updateLocalViewState(isLocalVideoMuted)
            }
            btnSettings.setOnClickListener {
                DigitalSettingsDialog().show(supportFragmentManager, "SettingsDialog")
            }
            btnInfo.setOnClickListener {
                DigitalAgentInfoDialog().apply {
                    isConnected = (networkStatus != Constants.QUALITY_DOWN)
                }.show(supportFragmentManager, "InfoDialog")
            }
            btnWifi.setOnClickListener {
                if (!DigitalAgoraManager.agentStarted) {
                    return@setOnClickListener
                }
                networkDialog = DigitalNetworkDialog().apply {
                    networkStatus?.let { updateNetworkStatus(it) }
                    show(supportFragmentManager, "NetworkDialog")
                    setOnDismissListener {
                        networkDialog = null
                    }
                }
            }
            llJoinCall.setOnClickListener {
                onClickStartAgent()
            }
            vDragSmallWindow.setOnViewClick {
                exchangeDragWindow()
            }
        }
    }

    private var smallContainerIsLocal = true

    private fun exchangeDragWindow() {
        val binding = mBinding ?: return
        val paramsBig = FrameLayout.LayoutParams(binding.vDragBigWindow.width, binding.vDragBigWindow.height)
        paramsBig.topMargin = binding.vDragBigWindow.top
        paramsBig.leftMargin = binding.vDragBigWindow.left
        val paramsSmall = FrameLayout.LayoutParams(binding.vDragSmallWindow.width, binding.vDragSmallWindow.height)
        paramsSmall.topMargin = binding.vDragSmallWindow.top
        paramsSmall.leftMargin = binding.vDragSmallWindow.left
        binding.vDragBigWindow.layoutParams = paramsSmall
        binding.vDragSmallWindow.layoutParams = paramsBig
        if (binding.vDragBigWindow.layoutParams.height > binding.vDragSmallWindow.layoutParams.height) {
            binding.vDragSmallWindow.bringToFront()
            binding.vDragSmallWindow.setSmallType(true)
            binding.vDragSmallWindow.setOnViewClick {
                exchangeDragWindow()
            }
            binding.vDragBigWindow.setOnViewClick(null)
            binding.vDragBigWindow.setSmallType(false)
        } else {
            binding.vDragBigWindow.bringToFront()
            binding.vDragBigWindow.setSmallType(true)
            binding.vDragBigWindow.setOnViewClick {
                exchangeDragWindow()
            }
            binding.vDragSmallWindow.setOnViewClick(null)
            binding.vDragSmallWindow.setSmallType(false)
        }
        smallContainerIsLocal = !smallContainerIsLocal

        updateLocalViewState(isLocalVideoMuted)
        updateRemoteViewState(isRemoteVideoMuted)
    }
}