package io.agora.scene.convoai.ui

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.view.View
import android.view.animation.AccelerateInterpolator
import android.view.animation.DecelerateInterpolator

class CovBallAnim constructor(val view:View) {

    private var sizeAnimator: Animator? = null
    private var isAgentStop = false

    var animatorListener:Animator.AnimatorListener?=null

    fun startAgentSpeaker(currentVolume:Int) {
        if (sizeAnimator?.isStarted == true) {
            // 如果动画正在运行，只需要更新状态
            isAgentStop = false
            return
        }
        // 开始新动画
        isAgentStop = false
        startSizeAnimation(currentVolume)
    }

    fun stopAgentSpeaker() {
        if (sizeAnimator?.isStarted == true) {
            isAgentStop = true
        } else {
            sizeAnimator?.cancel()
        }
    }

    private fun startSizeAnimation(currentVolume:Int) {
        sizeAnimator?.cancel()
        // 根据音量(0-255)计算缩放范围
        val minScale = when {
            currentVolume > 200 -> 0.9f  // 音量很大 (200-255)
            currentVolume > 150 -> 0.94f  // 音量大 (150-200)
            currentVolume > 100 -> 0.94f  // 音量中等 (100-150)
            currentVolume > 50 -> 0.96f   // 音量小 (50-100)
            else -> 0.96f                 // 音量很小 (0-50)
        }

        // 根据音量调整动画速度
        val baseDuration = when {
            currentVolume > 200 -> 250L   // 最快
            currentVolume > 150 -> 300L   // 较快
            currentVolume > 100 -> 350L   // 中速
            currentVolume > 50 -> 400L    // 较慢
            else -> 450L                  // 最慢
        }

        // 创建四段动画
        val anim1 = ValueAnimator.ofFloat(1f, minScale).apply {
            duration = baseDuration
            interpolator = DecelerateInterpolator()
        }

        val anim2 = ValueAnimator.ofFloat(minScale, minScale + 0.03f).apply {
            duration = baseDuration / 3
            interpolator = AccelerateInterpolator()
        }

        val anim3 = ValueAnimator.ofFloat(minScale + 0.03f, minScale).apply {
            duration = baseDuration / 3
            interpolator = DecelerateInterpolator()
        }

        val anim4 = ValueAnimator.ofFloat(minScale, 1f).apply {
            duration = baseDuration
            interpolator = AccelerateInterpolator()
        }

        // 为所有动画添加更新监听
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

        // 创建动画集合
        val animatorSet = AnimatorSet().apply {
            playSequentially(anim1, anim2, anim3, anim4)
            addListener(object : Animator.AnimatorListener {
                override fun onAnimationStart(animation: Animator) {
                    animatorListener?.onAnimationStart(animation)
                }

                override fun onAnimationEnd(animation: Animator) {
                    if (!isAgentStop) {
                        start()
                    } else {
                        view.apply {
                            scaleX = 1f
                            scaleY = 1f
                        }
                        isAgentStop = false
                        animatorListener?.onAnimationEnd(animation)
                    }
                }

                override fun onAnimationCancel(animation: Animator) {
                    view.apply {
                        scaleX = 1f
                        scaleY = 1f
                    }
                    isAgentStop = false
                }

                override fun onAnimationRepeat(animation: Animator) {}
            })
        }

        // 根据音量调整视频播放速度
//        val playbackSpeed = when {
//            currentVolume > 200 -> 3.0f    // 音量很大
//            currentVolume > 120 -> 2.0f   // 音量大
////            currentVolume > 80 -> 160    // 音量中等
////            currentVolume > 50 -> 10     // 音量小
//            else -> 1.0f                  // 音量很小
//        }

        sizeAnimator = animatorSet
        animatorSet.start()
    }
}