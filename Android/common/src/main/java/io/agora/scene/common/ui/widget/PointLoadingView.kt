package io.agora.scene.common.ui.widget

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.drawable.GradientDrawable
import android.util.AttributeSet
import android.view.View
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout

class PointLoadingView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val points = mutableListOf<View>()
    private var animator: ValueAnimator? = null

    var pointColor: Int = 0xFFFFFFFF.toInt()
        set(value) {
            field = value
            points.forEach { point ->
                (point.background as? GradientDrawable)?.setColor(value)
            }
        }

    var pointSize: Int = 9.dp
    var pointSpace: Int = 7.dp
    private val animDuration = 800L

    init {
        initPoints()
    }

    private fun initPoints() {
        repeat(3) {
            val point = View(context).apply {
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(pointColor)
                }
            }
            points.add(point)
            addView(point)
        }
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)

        val totalWidth = pointSize * 3 + pointSpace * 2

        var startX = (width - totalWidth) / 2

        points.forEach { point ->
            val t = (height - pointSize) / 2
            point.layout(startX, t, startX + pointSize, t + pointSize)
            startX += (pointSize + pointSpace)
        }
    }

    fun startAnimation() {
        stopAnimation()

        animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = animDuration
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()

            addUpdateListener { animation ->
                val progress = animation.animatedValue as Float
                points.forEachIndexed { index, point ->
                    var pointProgress = progress - index * 0.3f
                    if (pointProgress < 0) pointProgress += 1

                    point.alpha = 0.3f + 0.7f * when {
                        pointProgress < 0.5f -> pointProgress * 2
                        else -> (1f - pointProgress) * 2
                    }
                }
            }

            start()
        }
    }

    fun stopAnimation() {
        animator?.cancel()
        animator = null
        points.forEach { it.alpha = 0.3f }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopAnimation()
    }

    private val Int.dp: Int
        get() = (this * context.resources.displayMetrics.density + 0.5f).toInt()
} 