package io.agora.scene.convoai.ui

import android.animation.Animator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.SurfaceTexture
import android.media.MediaPlayer
import android.util.Log
import android.view.Surface
import android.view.TextureView
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import io.agora.scene.common.BuildConfig

sealed class MediaPlayerError {
    data class PrepareError(val exception: Exception) : MediaPlayerError()
    data class PlaybackError(val what: Int, val extra: Int) : MediaPlayerError()
}

interface MediaPlayerCallback {
    fun onError(error: MediaPlayerError)
}

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
    private val videoContainer: FrameLayout
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
            const val SCALE_HIGH = 0.9f
            const val SCALE_MEDIUM = 0.94f
            const val SCALE_LOW = 0.96f
        }

        private const val TAG = "CovBallAnim"

        // Animation duration constants
        private const val DURATION_HIGH = 300L
        private const val DURATION_MEDIUM = 400L
        private const val DURATION_LOW = 500L

        private const val VIDEO_FILE_NAME = "ball_small_video.mov"
        private const val BOUNCE_SCALE = 0.02f  // Additional scale factor during bounce
    }

    private var scaleAnimator: Animator? = null

    private var mediaPlayer: MediaPlayer? = null

    private var mediaPlayerCallback: MediaPlayerCallback? = null

    private var currentState = AgentState.STATIC
        private set(value) {
            if (field != value) {
                field = value
                when (value) {
                    AgentState.STATIC -> {
                        setVideoSpeed(0f)
                    }

                    AgentState.LISTENING -> setVideoSpeed(1.0f)
                    AgentState.SPEAKING -> setVideoSpeed(2.0f)
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
            // Check the state, stop the animation if it’s not in the SPEAKING state
            if (currentState != AgentState.SPEAKING) {
                pendingAnimParams = null
                Log.d(TAG, "onAnimationRepeat call cancel $scaleAnimator")
                animation.cancel()
            }
        }
    }

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

    fun setupMediaPlayer(callback: MediaPlayerCallback) {
        this.mediaPlayerCallback = callback
        val surfaceView = TextureView(context).apply {
            videoContainer.removeAllViews()
            videoContainer.addView(this)
        }
        createMediaPlayer(surfaceView)
    }

    private fun createMediaPlayer(surfaceView: TextureView) {
        mediaPlayer = MediaPlayer()

        surfaceView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
            override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
                try {
                    val path = context.filesDir.absolutePath + "/$VIDEO_FILE_NAME"
                    mediaPlayer?.apply {
                        reset()
                        setDataSource(path)
                        setSurface(Surface(surface))
                        setOnErrorListener { _, what, extra ->
                            mediaPlayerCallback?.onError(MediaPlayerError.PlaybackError(what, extra))
                            true
                        }
                        setOnPreparedListener { mp ->
                            mp.setVolume(0f, 0f)
                            mp.isLooping = true
                            mp.seekTo(0)  // Position to the first frame
                        }
                        prepareAsync()
                    }
                } catch (e: Exception) {
                    mediaPlayerCallback?.onError(MediaPlayerError.PrepareError(e))
                }
            }

            override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {}

            override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
                return false
            }

            override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}
        }
    }

//    private fun getFirstVideoFrame(path:String):Bitmap?{
//        val retriever = MediaMetadataRetriever()
//        retriever.setDataSource(path)
//        val firstFrame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
//        retriever.release()
//        return firstFrame
//    }

    private fun setVideoSpeed(speed: Float) {
        try {
            val params = mediaPlayer?.playbackParams ?: return
            params.setSpeed(speed)
            mediaPlayer?.playbackParams = params
        } catch (e: Exception) {
            mediaPlayerCallback?.onError(MediaPlayerError.PlaybackError(0, 0))
        }
    }

    fun updateAgentState(newState: AgentState, volume: Int = 0) {
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
                if (oldState == AgentState.STATIC && mediaPlayer?.isPlaying == false) {
                    mediaPlayer?.start()
                }
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
        (videoContainer.parent as? ViewGroup)?.apply {
            scaleX = scale
            scaleY = scale
        }
    }

    fun release() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
                mediaPlayer = null
            }

            scaleAnimator?.let {
                it.removeListener(animatorListener)  // Remove the listener
                it.cancel()
                scaleAnimator = null
            }
            mediaPlayerCallback = null
            currentState = AgentState.STATIC

            // Release TextureView resources
            videoContainer.removeAllViews()
        } catch (e: Exception) {
            mediaPlayerCallback?.onError(MediaPlayerError.PrepareError(e))
        }
    }
}