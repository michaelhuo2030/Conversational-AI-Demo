package io.agora.scene.convoai.ui

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.SurfaceTexture
import android.media.MediaPlayer
import android.view.Surface
import android.view.TextureView
import android.view.ViewGroup
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout


interface MediaPlayerCallback {
    fun onError(error: Exception)
}

enum class AgentState {
    /** 静止状态，不播放视频和动画 */
    STATIC,

    /** 正在监听状态，播放慢速动画 */
    LISTENING,

    /** AI 说话动画进行中 */
    SPEAKING
}

class CovBallAnim constructor(
    private val context: Context,
    private val videoContainer: FrameLayout
) {

    companion object {
        private const val MIN_VOLUME = 0
        private const val MAX_VOLUME = 255
        private const val HIGH_VOLUME = 200
        private const val MEDIUM_VOLUME = 150
        private const val LOW_VOLUME = 100

        // Scale range constants
        private const val SCALE_HIGH = 0.9f
        private const val SCALE_MEDIUM = 0.94f
        private const val SCALE_LOW = 0.96f

        // Animation duration constants
        private const val DURATION_HIGH = 200L
        private const val DURATION_MEDIUM = 300L
        private const val DURATION_LOW = 400L

        private const val VIDEO_FILE_NAME = "ball_small_video.mov"
        private const val BOUNCE_SCALE = 0.03f  // 弹跳时额外的缩放量
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

                    AgentState.LISTENING -> setVideoSpeed(0.7f)
                    AgentState.SPEAKING -> setVideoSpeed(2.0f)
                }
            }
        }


    private data class AnimParams(
        val minScale: Float = 1f,
        val duration: Long = 200L
    )

    private var currentAnimParams: AnimParams = AnimParams()

    private fun calculateMinScale(volume: Int): Float {
        return when {
            volume > HIGH_VOLUME -> SCALE_HIGH
            volume > MEDIUM_VOLUME -> SCALE_MEDIUM
            volume > LOW_VOLUME -> SCALE_LOW
            else -> SCALE_LOW
        }
    }

    private fun calculateDuration(volume: Int): Long {
        return when {
            volume > HIGH_VOLUME -> DURATION_HIGH
            volume > MEDIUM_VOLUME -> DURATION_MEDIUM
            volume > LOW_VOLUME -> DURATION_LOW
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
                            val errorMessage = "MediaPlayer error: what=$what, extra=$extra"
                            mediaPlayerCallback?.onError(Exception(errorMessage))
                            true
                        }
                        setOnPreparedListener { mp ->
                            mp.setVolume(0f, 0f)
                            mp.isLooping = true
                            mp.seekTo(0);  // 定位到第一帧
                            mp.setOnSeekCompleteListener { mp.pause() } // 确保第一帧停住
                        }
                        prepareAsync()
                    }
                } catch (e: Exception) {
                    mediaPlayerCallback?.onError(e)
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
            mediaPlayerCallback?.onError(e)
        }
    }

    fun updateAgentState(newState: AgentState, volume: Int = 0) {
        val oldState = currentState
        currentState = newState

        when (newState) {
            AgentState.STATIC -> {

            }

            AgentState.LISTENING -> {
                if (oldState == AgentState.STATIC) {
                    if (mediaPlayer?.isPlaying == false) {
                        mediaPlayer?.start()
                    }
                }
            }

            AgentState.SPEAKING -> {
                if (oldState == AgentState.STATIC) {
                    if (mediaPlayer?.isPlaying == false) {
                        mediaPlayer?.start()
                    }
                }
                startAgentAnimation(volume)
            }
        }
    }

    private fun startAgentAnimation(currentVolume: Int) {
        if (scaleAnimator?.isStarted == true) {
            return
        }

        val safeVolume = currentVolume.coerceIn(MIN_VOLUME, MAX_VOLUME)
        val params = AnimParams(
            minScale = calculateMinScale(safeVolume),
            duration = calculateDuration(safeVolume)
        )

        val updateListener = ValueAnimator.AnimatorUpdateListener { animator ->
            val scale = animator.animatedValue as Float
            updateParentScale(scale)
        }

        val animations = listOf(
            ValueAnimator.ofFloat(1f, params.minScale).apply {
                duration = params.duration
                interpolator = DecelerateInterpolator()
                addUpdateListener(updateListener)
            },
            ValueAnimator.ofFloat(params.minScale, params.minScale + BOUNCE_SCALE).apply {
                duration = params.duration / 3
                interpolator = AccelerateInterpolator()
                addUpdateListener(updateListener)
            },
            ValueAnimator.ofFloat(params.minScale + BOUNCE_SCALE, params.minScale).apply {
                duration = params.duration / 3
                interpolator = DecelerateInterpolator()
                addUpdateListener(updateListener)
            },
            ValueAnimator.ofFloat(params.minScale, 1f).apply {
                duration = params.duration
                interpolator = AccelerateInterpolator()
                addUpdateListener(updateListener)
            }
        )

        val animatorSet = AnimatorSet().apply {
            playSequentially(animations)
            addListener(object : Animator.AnimatorListener {
                override fun onAnimationStart(animation: Animator) {
                }

                override fun onAnimationEnd(animation: Animator) {
                    // 动画结束后更新状态
                    if (currentState != AgentState.SPEAKING) {
                        animation.cancel()
                    }
                }

                override fun onAnimationCancel(animation: Animator) {
                    updateParentScale(1.0f)
                }

                override fun onAnimationRepeat(animation: Animator) {}
            })
        }

        scaleAnimator = animatorSet
        animatorSet.start()
    }

    private fun updateParentScale(scale: Float) {
        (videoContainer.parent as? ViewGroup)?.apply {
            scaleX = scale
            scaleY = scale
        }
    }

    fun release() {
        mediaPlayer?.let {
            it.stop()
            it.release()
            mediaPlayer = null
        }

        scaleAnimator?.let {
            it.cancel()
            scaleAnimator = null
        }
        mediaPlayerCallback = null
        currentState = AgentState.STATIC

        // 释放 TextureView 资源
        videoContainer.removeAllViews()
    }
}