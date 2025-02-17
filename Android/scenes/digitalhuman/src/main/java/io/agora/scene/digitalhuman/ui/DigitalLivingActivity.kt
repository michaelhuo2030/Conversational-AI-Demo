package io.agora.scene.digitalhuman.ui

import android.content.Intent
import android.util.Log
import android.util.Size
import android.view.TextureView
import android.view.View
import android.widget.FrameLayout
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
import io.agora.rtc2.Constants.ERR_OK
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngineConfig
import io.agora.rtc2.RtcEngineEx
import io.agora.rtc2.video.VideoCanvas
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.digitalhuman.DigitalLogger
import io.agora.scene.digitalhuman.R
import io.agora.scene.digitalhuman.databinding.DigitalActivityLivingBinding
import io.agora.scene.digitalhuman.http.DigitalApiManager
import io.agora.scene.digitalhuman.rtc.AgentPresetType
import io.agora.scene.digitalhuman.rtc.DigitalAgentObserver
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.random.Random

class DigitalLivingActivity : BaseActivity<DigitalActivityLivingBinding>() {

    private val TAG = "DigitalLivingActivity"

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private lateinit var engine: RtcEngineEx

    private var loadingDialog: LoadingDialog? = null

    private var networkDialog: DigitalNetworkDialog? = null

    private var isLocalAudioMuted = false
    private var isLocalVideoMuted = false
    private var isRemoteVideoMuted = true
    private var rtcToken: String? = null
    private var channelName = ""
    private var localUid: Int = 0
    private val agentUID = 999
    private val avatarRtcUID = 998
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

    // Save video width and height
    private var mVideoSizes = mutableMapOf<Int, Size>()

    override fun onHandleOnBackPressed() {
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
        super.onHandleOnBackPressed()
    }

    override fun getViewBinding(): DigitalActivityLivingBinding = DigitalActivityLivingBinding.inflate(layoutInflater)

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

    override fun onPause() {
        super.onPause()
        if (isAgentStarted) {
            startRecordingService()
        }
    }

    private fun startRecordingService() {
        val intent = Intent(this, DigitalRtcForegroundService::class.java)
        startForegroundService(intent)
    }

    private var startAgentSuccess = false
    private fun onClickStartAgent() {
        if (!smallContainerIsLocal) {
            exchangeDragWindow()
        }
        loadingDialog?.setMessage(getString(R.string.digital_detail_agent_joining))
        loadingDialog?.show()
        DigitalAgoraManager.channelName = channelName
        DigitalAgoraManager.uid = localUid
        val params = AgentRequestParams(
            channelName = channelName,
            remoteRtcUid = localUid,
            agentRtcUid = agentUID,
            avatarRtcUid = avatarRtcUID,
            ttsVoiceId = DigitalAgoraManager.voiceType.value,
            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER
        )
        DigitalApiManager.startAgent(params) { isAgentOK ->
            if (isAgentOK) {
                startAgentSuccess = true
                if (rtcToken == null) {
                    getToken { isTokenOK ->
                        if (isTokenOK) {
                            joinChannel()
                        } else {
                            loadingDialog?.dismiss()
                            DigitalLogger.e(TAG, "Token error")
                            ToastUtil.show(getString(R.string.digital_detail_join_call_failed))
                        }
                    }
                } else {
                    joinChannel()
                }
            } else {
                loadingDialog?.dismiss()
                DigitalLogger.e(TAG, "Agent error")
                ToastUtil.show(getString(R.string.digital_detail_join_call_failed))
            }
        }
        scope.launch {
            delay(10000L)
            // agent start but not join channel
            if (!isAgentStarted && startAgentSuccess) {
                engine.stopPreview()
                engine.leaveChannel()
                DigitalApiManager.stopAgent { ok ->
                    ToastUtil.show(getString(R.string.digital_timeout))
                    startAgentSuccess = false
                    loadingDialog?.dismiss()
                    if (ok) {
                        isAgentStarted = false
                        networkStatus = null
                        DigitalAgoraManager.agentStarted = false
                        resetSceneState()
                    }
                }
            }
        }
    }

    private fun onClickEndCall() {
        engine.stopPreview()
        engine.leaveChannel()
        loadingDialog?.setMessage(getString(R.string.digital_detail_agent_ending))
        loadingDialog?.show()
        DigitalApiManager.stopAgent { ok ->
            loadingDialog?.dismiss()
            if (ok) {
                ToastUtil.show(getString(R.string.digital_detail_agent_leave))
                isAgentStarted = false
                networkStatus = null
                DigitalAgoraManager.agentStarted = false
                resetSceneState()
            } else {
                ToastUtil.show("Agent Leave Failed")
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
        DigitalLogger.d(
            TAG,
            "onClickStartAgent channelName: $channelName, localUid: $localUid, agentUID: $agentUID, avatarRtcUID: $avatarRtcUID"
        )
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        engine.setParameters("{\"che.audio.sf.enabled\":false}")
        DigitalAgoraManager.updateDenoise(true)
        engine.startPreview()
        val ret = engine.joinChannel(rtcToken, channelName, localUid, channelOption)
        if (ret != ERR_OK) {
            loadingDialog?.dismiss()
            ToastUtil.show(getString(R.string.digital_detail_join_call_failed))
            return
        }
        DigitalLogger.d(TAG, "Joining RTC channel: $channelName, uid: $localUid, ret: $ret")

    }

    private fun getToken(complete: (Boolean) -> Unit) {
        TokenGenerator.generateToken("",
            localUid.toString(),
            TokenGeneratorType.Token007,
            AgoraTokenType.Rtc,
            success = { token ->
                DigitalLogger.d(TAG, "getToken success")
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
                    if (uid == avatarRtcUID) {
                        setupRemoteView(uid, true)
                        updateRemoteViewState(isRemoteVideoMuted)
                        isAgentStarted = true
                        DigitalAgoraManager.agentStarted = true
                        loadingDialog?.dismiss()
                        ToastUtil.show(getString(R.string.digital_detail_join_call_succeed))
                    }
                }
                DigitalLogger.d(TAG, "remote user didJoinedOfUid uid: $uid")
            }

            override fun onUserOffline(uid: Int, reason: Int) {
                DigitalLogger.d(TAG, "remote user onUserOffline uid: $uid")
                if (uid == avatarRtcUID) {
                    runOnUiThread {
                        setupRemoteView(uid, false)
                        DigitalLogger.d(TAG, "start agent reconnect")
                        rtcToken = null
                        // reconnect
                        loadingDialog?.setMessage(getString(R.string.digital_detail_agent_joining))
                        loadingDialog?.show()
                        val params = AgentRequestParams(
                            channelName = channelName,
                            remoteRtcUid = localUid,
                            agentRtcUid = agentUID,
                            avatarRtcUid = avatarRtcUID,
                            ttsVoiceId = DigitalAgoraManager.voiceType.value,
                            audioScenario = Constants.AUDIO_SCENARIO_AI_SERVER
                        )
                        DigitalApiManager.startAgent(params) { isAgentOK ->
                            if (!isAgentOK) {
                                loadingDialog?.dismiss()
                                ToastUtil.show(getString(R.string.digital_detail_agent_leave))
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

            override fun onFirstRemoteVideoFrame(uid: Int, width: Int, height: Int, elapsed: Int) {
                super.onFirstRemoteVideoFrame(uid, width, height, elapsed)
                DigitalLogger.d(TAG, "onFirstRemoteVideoFrame uid: $uid, width: $width, height: $height")
                if (uid != avatarRtcUID) return
                runOnUiThread {
                    isRemoteVideoMuted = false
                    updateRemoteViewState(isRemoteVideoMuted)
                }
            }

            override fun onRemoteVideoStateChanged(uid: Int, state: Int, reason: Int, elapsed: Int) {
                super.onRemoteVideoStateChanged(uid, state, reason, elapsed)
                DigitalLogger.d(TAG, "onRemoteVideoStateChanged uid: $uid, state: $state, reason: $reason")
                if (uid != avatarRtcUID) return
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
                    if (it.uid == avatarRtcUID) {
                        runOnUiThread {
                        }
                    }
                }
            }

            override fun onNetworkQuality(uid: Int, txQuality: Int, rxQuality: Int) {
                if (uid == 0) {
                    runOnUiThread {
                        Constants.QUALITY_GOOD
                        updateNetworkStatus(rxQuality)
                        networkDialog?.updateNetworkStatus(rxQuality)
                    }
                }
            }

            override fun onVideoSizeChanged(
                source: Constants.VideoSourceType?,
                uid: Int,
                width: Int,
                height: Int,
                rotation: Int
            ) {
                super.onVideoSizeChanged(source, uid, width, height, rotation)
                mVideoSizes[uid] = Size(width, height)
                Log.i(TAG, "onVideoSizeChanged->uid:$uid,width:$width,height:$height,rotation:$rotation")
                runOnUiThread {
//                    adjustAssistantVideoSize(uid)
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
            localWindow.setUserName(getString(R.string.digital_youselft), false)
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
            engine.setupRemoteVideo(VideoCanvas(mRemoteVideoView, VideoCanvas.RENDER_MODE_FIT, uid))
        } else {
            engine.setupRemoteVideo(VideoCanvas(null, VideoCanvas.RENDER_MODE_FIT, uid))
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
            adjustAssistantVideoSize(avatarRtcUID)
        }
    }

    private fun adjustAssistantVideoSize(uid: Int) {
        if (uid != avatarRtcUID) return
        val videoWidth = mVideoSizes[avatarRtcUID]?.width ?: return
        val videoHeight = mVideoSizes[avatarRtcUID]?.height ?: return
        val remoteWindow = mBinding?.vDragBigWindow ?: return
        remoteWindow.post {
            val containerWidth: Int = remoteWindow.measuredWidth
            val containerHeight: Int = remoteWindow.measuredHeight
            Log.i(TAG, "adjustAssistantVideoSize->containerWidth:$containerWidth,containerHeight:$containerHeight")

            val videoRatio = videoHeight.toFloat() / videoWidth
            val containerRatio = containerHeight.toFloat() / containerWidth

            val targetWidth: Int
            val targetHeight: Int

            if (containerRatio > 1.0f) {
                // The container height is greater than the width, using the container height as the reference
                targetHeight = containerHeight
                targetWidth = (containerHeight / videoRatio).toInt()
                // Horizontal center
                val left = (containerWidth - targetWidth) / 2
                mRemoteVideoView.layout(
                    left,
                    0,
                    left + targetWidth,
                    targetHeight
                )
            } else {
                // The container width is greater than the height, using the container width as the reference
                targetWidth = containerWidth
                targetHeight = (containerWidth * videoRatio).toInt()
                mRemoteVideoView.layout(
                    0,
                    0,
                    targetWidth,
                    targetHeight
                )
            }

            Log.i(
                TAG,
                "adjustAssistantVideoSize->layout: width=$targetWidth, height=$targetHeight, containerRatio=$containerRatio"
            )
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
                onHandleOnBackPressed()
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