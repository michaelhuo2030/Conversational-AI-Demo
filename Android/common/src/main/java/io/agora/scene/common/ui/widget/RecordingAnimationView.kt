package io.agora.scene.common.ui.widget

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import android.animation.ValueAnimator
import android.graphics.Color
import io.agora.scene.common.R
import kotlin.random.Random

class RecordingAnimationView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val paint = Paint().apply {
        color = Color.WHITE
        style = Paint.Style.FILL
        strokeCap = Paint.Cap.ROUND
    }

    private val volumeArr = FloatArray(4) { 0f }
    private val barHeightsFragStart = FloatArray(4)
    private val animators = mutableListOf<ValueAnimator>()

    var horizontalSpacing = 10
    var barWidth = 50

    init {
        context.theme.obtainStyledAttributes(
            attrs,
            R.styleable.RecordingAnimationView,
            0, 0
        ).apply {
            try {
                horizontalSpacing = getDimensionPixelSize(R.styleable.RecordingAnimationView_horizontalSpacing, 10)
                barWidth = getDimensionPixelSize(R.styleable.RecordingAnimationView_barWidth, 50)
            } finally {
                recycle()
            }
        }
    }

    var barColor: Int = Color.WHITE
        set(value) {
            field = value
            paint.color = value
            invalidate()
        }

    var animationDuration: Long = 130
        set(value) {
            field = value
            animators.forEach { it.duration = value }
        }
    var frag = 0.1f
    private var minBarHeight = 0

    fun startVolumeAnimation(volume: Int) {
        val v = volume / 255f
        volumeArr[0] = mapValueToRange1(v, 0.4f, 1f)
        volumeArr[1] = mapValueToRange2(v, 0.4f, 1f)
        volumeArr[2] = mapValueToRange3(v, 0.4f, 1f)
        volumeArr[3] = mapValueToRange4(v, 0.4f, 1f)
        innerStartAnimation(volumeArr)
    }

    private fun innerStartAnimation(barHeightsEnd: FloatArray) {
        stopAnimation()
        animators.clear()
        for (i in barHeightsFragStart.indices) {
            val animator = ValueAnimator.ofFloat(barHeightsFragStart[i], barHeightsEnd[i]).apply {
                duration = animationDuration
                addUpdateListener {
                    barHeightsFragStart[i] = (it.animatedValue as Float)
                    invalidate()
                }
            }
            animators.add(animator)
        }
        animators.forEach { it.start() }
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        barWidth = (w / 5.5).toInt()
        val diff = height - barWidth
        minBarHeight = barWidth
        if (diff > 0) {
            minBarHeight = (diff * frag + barWidth).toInt()
            barHeightsFragStart.forEachIndexed { index, fl ->
                barHeightsFragStart[index] = minBarHeight.toFloat() / height
            }
        }
    }

    fun stopAnimation() {
        animators.forEach { it.cancel() }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val centerY = height / 2
        val totalWidth =
            barHeightsFragStart.size * barWidth + (barHeightsFragStart.size - 1) * horizontalSpacing
        val startX = (width - totalWidth) / 2

        for (i in barHeightsFragStart.indices) {
            val left = startX + i * (barWidth + horizontalSpacing)
            val right = left + barWidth
            val top = centerY - (height / 2 * barHeightsFragStart[i])
            val bottom = centerY + (height / 2 * barHeightsFragStart[i])
            if (bottom - top > minBarHeight) {
                canvas.drawRoundRect(
                    left.toFloat(),
                    top,
                    right.toFloat(),
                    bottom,
                    barWidth / 2f,
                    barWidth / 2f,
                    paint
                )
            } else {
                if (minBarHeight > barWidth) {
                    canvas.drawRoundRect(
                        left.toFloat(),
                        (centerY - minBarHeight / 2).toFloat(),
                        right.toFloat(),
                        (centerY + minBarHeight / 2).toFloat(),
                        barWidth / 2f,
                        barWidth / 2f,
                        paint
                    )
                } else {
                    val radius = barWidth / 2f
                    val cx = left + radius
                    val cy = centerY.toFloat()
                    canvas.drawCircle(cx, cy, radius, paint)
                }

            }
        }
    }

    fun randomMultiplier(): Float {
        return Random.nextFloat() * (1.5f - 0.5f) + 0.5f // Generate a random number between 0.5 and 1.5
    }

    fun mapValueToRange1(value1: Float, x: Float, y: Float): Float {
        if (value1 == 0f) {
            return x // Return x instead of 0
        }
        val scaledValue1 = value1.coerceIn(0.0f, 1.0f)
        val mappedValue = x + (scaledValue1 * (y - x) * 0.5f) // Scale down the range
        return (mappedValue * randomMultiplier()).coerceIn(x, y) // Ensure the returned value is within [x, y]
    }

    fun mapValueToRange2(value1: Float, x: Float, y: Float): Float {
        if (value1 == 0f) {
            return x // Return x instead of 0
        }
        val scaledValue1 = value1.coerceIn(0.0f, 1.0f)
        val mappedValue = x + (scaledValue1 * (y - x) * 0.75f) // Scale down the range differently
        return (mappedValue * randomMultiplier()).coerceIn(x, y) // Ensure the returned value is within [x, y]
    }

    fun mapValueToRange3(value1: Float, x: Float, y: Float): Float {
        if (value1 == 0f) {
            return x // Return x instead of 0
        }
        val scaledValue1 = value1.coerceIn(0.0f, 1.0f)
        val mappedValue = x + (scaledValue1 * (y - x) * 0.5f) // Same scaling as mapValueToRange1
        return (mappedValue * randomMultiplier()).coerceIn(x, y) // Ensure the returned value is within [x, y]
    }

    fun mapValueToRange4(value1: Float, x: Float, y: Float): Float {
        if (value1 == 0f) {
            return x // Return x instead of 0
        }
        val scaledValue1 = value1.coerceIn(0.0f, 1.0f)
        val mappedValue = x + (scaledValue1 * (y - x) * 0.75f) // Same scaling as mapValueToRange2
        return (mappedValue * randomMultiplier()).coerceIn(x, y) // Ensure the returned value is within [x, y]
    }
}