package io.agora.scene.convoai.ui

import android.animation.Animator
import android.animation.ValueAnimator
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.TextureView
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import io.agora.mediaplayer.Constants.MediaPlayerReason
import io.agora.mediaplayer.Constants.MediaPlayerState
import io.agora.mediaplayer.IMediaPlayer
import io.agora.mediaplayer.data.MediaPlayerSource
import io.agora.rtc2.RtcEngine
import io.agora.scene.common.BuildConfig
import io.agora.scene.convoai.manager.CovMediaPlayerObserver
import io.agora.mediaplayer.Constants
import java.io.File

enum class AgentState {
    /** Idle state, no video or animation is playing */
    STATIC,

    /** Listening state, playing slow animation */
    LISTENING,

    /** AI speaking animation in progress */
    SPEAKING
}

class CovBallAnim constructor(
    private val context: Context,
    private val videoView: TextureView
) {

    companion object {
        private object VolumeConstants {
            const val MIN_VOLUME = 0
            const val MAX_VOLUME = 255
            const val HIGH_VOLUME = 200
            const val MEDIUM_VOLUME = 120
            const val LOW_VOLUME = 80
        }

        private object ScaleConstants {
            const val SCALE_HIGH = 1.1f
            const val SCALE_MEDIUM = 1.06f
            const val SCALE_LOW = 1.04f
        }

        private const val TAG = "CovBallAnim"

        // Animation duration constants
        private const val DURATION_HIGH = 400L
        private const val DURATION_MEDIUM = 500L
        private const val DURATION_LOW = 600L

        private const val VIDEO_START_NAME = "ball_video_start1.mov"
        private const val VIDEO_ROTATING_NAME = "ball_video_rotating1.mov"
        private const val BOUNCE_SCALE = 0.02f  // Additional scale factor during bounce
    }

    private var scaleAnimator: Animator? = null

    private var rtcMediaPlayer: IMediaPlayer? = null

    private var currentState = AgentState.STATIC
        private set(value) {
            if (field != value) {
                field = value
                when (value) {
                    AgentState.STATIC -> {
                        rtcMediaPlayer?.setPlaybackSpeed(100)
                    }

                    AgentState.LISTENING -> {
                        rtcMediaPlayer?.setPlaybackSpeed(150)
                    }

                    AgentState.SPEAKING -> {
                        rtcMediaPlayer?.setPlaybackSpeed(250)
                    }
                }
            }
        }


    private data class AnimParams(
        val minScale: Float = 1f,
        val duration: Long = 200L
    )

    private var currentAnimParams: AnimParams = AnimParams()
    private var pendingAnimParams: AnimParams? = null

    private val animatorListener = object : Animator.AnimatorListener {
        override fun onAnimationEnd(animation: Animator) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "onAnimationEnd $scaleAnimator")
            }
            // Use the latest pending execution parameters
            pendingAnimParams?.let { params ->
                if (currentState == AgentState.SPEAKING) {
                    if (BuildConfig.DEBUG) {
                        Log.d(TAG, "onAnimationRepeat call new Animation $scaleAnimator")
                    }
                    startNewAnimation(params)
                }
                pendingAnimParams = null
            }
        }

        override fun onAnimationStart(animation: Animator) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "onAnimationStart $scaleAnimator")
            }
        }

        override fun onAnimationCancel(animation: Animator) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "onAnimationCancel $scaleAnimator")
            }
            updateParentScale(1.0f)
        }

        override fun onAnimationRepeat(animation: Animator) {
            if (BuildConfig.DEBUG) {
                Log.d(TAG, "onAnimationRepeat $scaleAnimator")
            }
            // Check the state, stop the animation if it's not in the SPEAKING state
            if (currentState != AgentState.SPEAKING) {
                pendingAnimParams = null
                Log.d(TAG, "onAnimationRepeat call cancel $scaleAnimator")
                animation.cancel()
            }
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private fun calculateMinScale(volume: Int): Float {
        return when {
            volume > VolumeConstants.HIGH_VOLUME -> ScaleConstants.SCALE_HIGH
            volume > VolumeConstants.MEDIUM_VOLUME -> ScaleConstants.SCALE_MEDIUM
            volume > VolumeConstants.LOW_VOLUME -> ScaleConstants.SCALE_LOW
            else -> ScaleConstants.SCALE_LOW
        }
    }

    private fun calculateDuration(volume: Int): Long {
        return when {
            volume > VolumeConstants.HIGH_VOLUME -> DURATION_HIGH
            volume > VolumeConstants.MEDIUM_VOLUME -> DURATION_MEDIUM
            volume > VolumeConstants.LOW_VOLUME -> DURATION_LOW
            else -> DURATION_LOW
        }
    }

    private fun getVideoSrc(fileName: String): String {
        return context.filesDir.absolutePath + File.separator + fileName
    }

    fun setupMediaPlayer(rtcEngine: RtcEngine) {
        rtcMediaPlayer = rtcEngine.createMediaPlayer()?.apply {
            setView(videoView)
            registerPlayerObserver(mediaPlayerObserver)
            val source = MediaPlayerSource().apply {
                url = getVideoSrc(VIDEO_START_NAME)
            }
            openWithMediaSource(source)
        }
    }

    private val mediaPlayerObserver = object : CovMediaPlayerObserver() {
        override fun onPlayerStateChanged(state: MediaPlayerState?, reason: MediaPlayerReason?) {
            Log.d(TAG, "$state $reason")
            if (state == MediaPlayerState.PLAYER_STATE_OPEN_COMPLETED) {
                rtcMediaPlayer?.apply {
                    mute(true)
                    play()
                    preloadSrc(getVideoSrc(VIDEO_ROTATING_NAME), 0)
                }
            } else if (state == MediaPlayerState.PLAYER_STATE_PLAYBACK_ALL_LOOPS_COMPLETED) {
                rtcMediaPlayer?.apply {
                    playPreloadedSrc(getVideoSrc(VIDEO_ROTATING_NAME))
                    mute(true)
                    setLoopCount(-1)
                }
            }
        }

        override fun onPreloadEvent(src: String?, event: Constants.MediaPlayerPreloadEvent?) {
            super.onPreloadEvent(src, event)
            Log.d(TAG, "onPreloadEvent: $src $event")
        }
    }

    fun updateAgentState(newState: AgentState, volume: Int = 0) {
        Log.d(TAG, "updateAgentState newState:$newState currentState:$currentState ${Thread.currentThread()}")
        if (Looper.myLooper() == Looper.getMainLooper()) {
            updateAgentStateInternal(newState, volume)
        } else {
            mainHandler.post {
                updateAgentStateInternal(newState, volume)
            }
        }
    }

    private fun updateAgentStateInternal(newState: AgentState, volume: Int) {
        val oldState = currentState
        currentState = newState
        handleStateTransition(oldState, newState, volume)
    }

    private fun handleStateTransition(oldState: AgentState, newState: AgentState, volume: Int = 0) {
        when (newState) {
            AgentState.STATIC -> {
                // Handle the static state
            }

            AgentState.LISTENING, AgentState.SPEAKING -> {
                // TODO: oldState == AgentState.STATIC
//                if (oldState == AgentState.STATIC) {
//                    rtcMediaPlayer?.play()
//                }
                if (newState == AgentState.SPEAKING) {
                    startAgentAnimation(volume)
                }
            }
        }
    }

    private fun startAgentAnimation(currentVolume: Int) {
        val safeVolume = currentVolume.coerceIn(VolumeConstants.MIN_VOLUME, VolumeConstants.MAX_VOLUME)
        val newParams = AnimParams(
            minScale = calculateMinScale(safeVolume),
            duration = calculateDuration(safeVolume)
        )

        // If the animation parameters are the same and the animation is already running, do nothing.
        if (newParams.minScale == currentAnimParams.minScale && scaleAnimator?.isRunning == true) {
            return
        }

        // Save the latest animation parameters
        pendingAnimParams = newParams

        // If an animation is currently running, wait for it to finish
        if (scaleAnimator?.isRunning == true) {
            // The animation already has a listener, just wait for it to complete
            return
        }

        // If no animation is running, start a new one immediately
        startNewAnimation(newParams)
        pendingAnimParams = null
    }

    private fun startNewAnimation(params: AnimParams) {
        currentAnimParams = params

        val updateListener = ValueAnimator.AnimatorUpdateListener { animator ->
            val scale = animator.animatedValue as Float
            updateParentScale(scale)
        }

        val mainAnim = ValueAnimator.ofFloat(
            1f, params.minScale, params.minScale + BOUNCE_SCALE,
            params.minScale, 1f
        ).apply {
            duration = params.duration
            repeatCount = ValueAnimator.INFINITE
            interpolator = DecelerateInterpolator()
            addUpdateListener(updateListener)
            addListener(animatorListener)
        }

        scaleAnimator = mainAnim
        mainAnim.start()
    }

    private fun updateParentScale(scale: Float) {
        (videoView.parent as? ViewGroup)?.apply {
            scaleX = scale
            scaleY = scale
        }
    }

    fun release() {
        rtcMediaPlayer?.let {
            it.stop()
            it.destroy()
            rtcMediaPlayer = null
        }

        scaleAnimator?.let {
            it.removeListener(animatorListener)  // Remove the listener
            it.cancel()
            scaleAnimator = null
        }
        currentState = AgentState.STATIC
    }
}