package io.agora.scene.convoai.ui

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.view.View
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator

interface BallAnimCallback {
    fun onAnimationStart()
    fun onAnimationEnd()
}

class CovBallAnim constructor(private val view: View) {
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
    }

    private var sizeAnimator: Animator? = null
    var animCallback: BallAnimCallback? = null

    private enum class AnimState {
        IDLE, RUNNING, STOPPING
    }
    private var currentState = AnimState.IDLE
        private set(value) {
            if (field != value) {
                field = value
                when (value) {
                    AnimState.RUNNING -> animCallback?.onAnimationStart()
                    AnimState.IDLE -> animCallback?.onAnimationEnd()
                    else -> {} // STOPPING state does not trigger callback
                }
            }
        }

    // Extract animation parameter calculation to separate method
    private fun calculateAnimationParams(volume: Int): AnimParams {
        val safeVolume = volume.coerceIn(MIN_VOLUME, MAX_VOLUME)
        return AnimParams(
            minScale = calculateMinScale(safeVolume),
            duration = calculateDuration(safeVolume)
        )
    }
    
    private data class AnimParams(
        val minScale: Float,
        val duration: Long
    )

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

    fun startAgentSpeaker(currentVolume: Int) {
        when (currentState) {
            AnimState.RUNNING -> return
            AnimState.STOPPING -> currentState = AnimState.RUNNING
            AnimState.IDLE -> startSizeAnimation(currentVolume)
        }
    }

    fun stopAgentSpeaker() {
        when (currentState) {
            AnimState.RUNNING -> currentState = AnimState.STOPPING
            AnimState.STOPPING -> {} // Already stopping
            AnimState.IDLE -> {} // Already stopped
        }
    }

    private fun startSizeAnimation(currentVolume: Int) {
        val params = calculateAnimationParams(currentVolume)
        sizeAnimator?.cancel()
        
        val anim1 = ValueAnimator.ofFloat(1f, params.minScale).apply {
            duration = params.duration
            interpolator = DecelerateInterpolator()
        }

        val anim2 = ValueAnimator.ofFloat(params.minScale, params.minScale + 0.03f).apply {
            duration = params.duration / 3
            interpolator = AccelerateInterpolator()
        }

        val anim3 = ValueAnimator.ofFloat(params.minScale + 0.03f, params.minScale).apply {
            duration = params.duration / 3
            interpolator = DecelerateInterpolator()
        }

        val anim4 = ValueAnimator.ofFloat(params.minScale, 1f).apply {
            duration = params.duration
            interpolator = AccelerateInterpolator()
        }

        val updateListener = ValueAnimator.AnimatorUpdateListener { animator ->
            val scale = animator.animatedValue as Float
            view.apply {
                scaleX = scale
                scaleY = scale
            }
        }

        anim1.addUpdateListener(updateListener)
        anim2.addUpdateListener(updateListener)
        anim3.addUpdateListener(updateListener)
        anim4.addUpdateListener(updateListener)

        val animatorSet = AnimatorSet().apply {
            playSequentially(anim1, anim2, anim3, anim4)
            addListener(object : Animator.AnimatorListener {
                override fun onAnimationStart(animation: Animator) {
                    currentState = AnimState.RUNNING
                }

                override fun onAnimationEnd(animation: Animator) {
                    when (currentState) {
                        AnimState.RUNNING -> start() // Continue playing
                        AnimState.STOPPING -> {
                            resetViewScale()
                            currentState = AnimState.IDLE
                        }
                        AnimState.IDLE -> {} // Should not happen
                    }
                }

                override fun onAnimationCancel(animation: Animator) {
                    resetViewScale()
                    currentState = AnimState.IDLE
                }

                override fun onAnimationRepeat(animation: Animator) {}
            })
        }
        sizeAnimator = animatorSet
        animatorSet.start()
    }

    private fun resetViewScale() {
        view.apply {
            scaleX = 1f
            scaleY = 1f
        }
    }

    fun release() {
        sizeAnimator?.cancel()
        sizeAnimator = null
        animCallback = null
        currentState = AnimState.IDLE
    }
}