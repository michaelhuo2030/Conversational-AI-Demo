package io.agora.scene.common.ui.widget

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.util.AttributeSet
import android.view.ViewGroup
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import io.agora.scene.common.R
import io.agora.scene.common.util.dp
import kotlin.math.PI

class GradientBorderView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val rect = RectF()
    private var rotationAngle = 0f
    private var animator: ValueAnimator? = null
    
    // Configuration parameters
    var borderWidth = 2.dp  // Border width
    var cornerRadius = 99.dp // Corner radius
    var colors = intArrayOf(
        0xFF00C2FF.toInt(),
        0x19ffffff.toInt(),
    )
    
    init {
        context.theme.obtainStyledAttributes(
            attrs,
            R.styleable.GradientBorderView,
            0, 0
        ).apply {
            try {
                borderWidth = getDimension(R.styleable.GradientBorderView_borderWidth, 2.dp)
                cornerRadius = getDimension(R.styleable.GradientBorderView_cornerRadius, 99.dp)
                
                // Get colors array from attributes
                val colorsArrayId = getResourceId(
                    R.styleable.GradientBorderView_gradientColors,
                    R.array.gradient_border_default_colors
                )
                val typedArray = context.resources.obtainTypedArray(colorsArrayId)
                colors = IntArray(typedArray.length()) { index ->
                    typedArray.getColor(index, 0)
                }
                typedArray.recycle()
            } finally {
                recycle()
            }
        }
        setWillNotDraw(false) // Enable custom view drawing
        setupAnimator()
    }

    private fun setupAnimator() {
        animator = ValueAnimator.ofFloat(0f, 2f * PI.toFloat()).apply {
            duration = 1000
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            addUpdateListener { animation ->
                rotationAngle = animation.animatedValue as Float
                invalidate()
            }
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        animator?.start()
    }

    override fun onDetachedFromWindow() {
        animator?.cancel()
        super.onDetachedFromWindow()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        rect.set(
            borderWidth / 2,
            borderWidth / 2,
            width.toFloat() - borderWidth / 2,
            height.toFloat() - borderWidth / 2
        )
    }

    override fun onDraw(canvas: Canvas) {
        // Create gradient
        val gradient = LinearGradient(
            0f, 0f,
            width.toFloat(), 0f,
            colors,
            null,
            Shader.TileMode.CLAMP
        )

        // Create rotation matrix
        val matrix = Matrix()
        matrix.setRotate(
            Math.toDegrees(rotationAngle.toDouble()).toFloat(),
            width / 2f,
            height / 2f
        )
        gradient.setLocalMatrix(matrix)

        // Setup paint
        paint.apply {
            style = Paint.Style.STROKE
            strokeWidth = borderWidth
            shader = gradient
        }

        // Draw rounded rectangle
        canvas.drawRoundRect(rect, cornerRadius, cornerRadius, paint)

        super.onDraw(canvas)
    }

    fun startAnimation() {
        animator?.start()
    }

    fun stopAnimation() {
        animator?.cancel()
    }

    companion object {
        fun create(
            context: Context,
            width: Int,
            height: Int,
            borderWidth: Float = 2.dp,
            cornerRadius: Float = 99.dp,
            colors: IntArray? = null
        ): GradientBorderView {
            return GradientBorderView(context).apply {
                layoutParams = ViewGroup.LayoutParams(width, height)
                this.borderWidth = borderWidth
                this.cornerRadius = cornerRadius
                colors?.let { this.colors = it }
            }
        }
    }
} 