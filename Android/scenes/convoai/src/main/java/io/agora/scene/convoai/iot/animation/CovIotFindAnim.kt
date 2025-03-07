package io.agora.scene.convoai.iot.animation

import android.animation.AnimatorSet
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.util.Log
import android.view.View
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import java.util.ArrayList
import kotlin.math.pow

class RippleAnimationView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val TAG = "RippleAnimationView"
    
    // 涟漪数量
    private val rippleCount = 3
    
    // 涟漪间隔时间
    private val rippleDuration = 500L // 0.5秒
    
    // 单次动画持续时间
    private val animationDuration = 2500L // 2.5秒
    
    // 动画暂停时间
    private val pauseDuration = 4000L // 4秒
    
    // 渐入渐出时间比例
    private val fadeRatio = 0.2f
    
    // 缩放因子
    var scaleFactor = 1.4f
    
    // 基础颜色 #446CFF
    private val baseColor = Color.rgb(68, 108, 255)
    
    // 存储所有涟漪圆的列表
    private val rippleCircles = ArrayList<RippleCircle>()
    
    // 画笔
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    
    // 动画集合
    private var animatorSet: AnimatorSet? = null
    
    init {
        // 初始化
        paint.style = Paint.Style.FILL
        Log.d(TAG, "初始化视图")
        
        // 不要在init中启动动画，等待视图尺寸确定后再启动
        // startRippleAnimation()
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        Log.d(TAG, "onDraw: width=$width, height=$height, 圆数量=${rippleCircles.size}")
        
        // 绘制所有涟漪圆 - 圆心位于底部中心
        for (circle in rippleCircles) {
            paint.color = circle.color
            // 将圆心位置改为底部中心
            canvas.drawCircle(width / 2f, height.toFloat(), circle.radius, paint)
            Log.d(TAG, "绘制圆: radius=${circle.radius}, alpha=${Color.alpha(circle.color)}")
        }
    }
    
    private fun startRippleAnimation() {
        // 清除现有动画
        animatorSet?.cancel()
        rippleCircles.clear()
        
        Log.d(TAG, "开始动画: width=$width, height=$height")
        
        // 为每个涟漪创建一个圆对象
        for (i in 0 until rippleCount) {
            rippleCircles.add(RippleCircle())
        }
        
        // 创建动画集合
        val animators = ArrayList<ValueAnimator>()
        
        // 为每个涟漪创建动画
        for (i in 0 until rippleCount) {
            val animator = createRippleAnimator(i)
            animators.add(animator)
        }
        
        // 创建并启动动画集合
        animatorSet = AnimatorSet()
        // 使用 play() 和 with() 方法替代 playTogether()
        if (animators.isNotEmpty()) {
            val builder = animatorSet?.play(animators[0])
            for (i in 1 until animators.size) {
                builder?.with(animators[i])
            }
        }
        animatorSet?.start()
        Log.d(TAG, "动画已启动")
    }
    
    private fun createRippleAnimator(index: Int): ValueAnimator {
        val animator = ValueAnimator.ofFloat(0f, 1f)
        // 移除暂停时间，使用单纯的动画时间
        animator.duration = animationDuration
        animator.repeatCount = ValueAnimator.INFINITE
        // 使用RESTART模式而不是REVERSE
        animator.repeatMode = ValueAnimator.RESTART
        animator.startDelay = index * rippleDuration
        animator.interpolator = LinearInterpolator()
        
        // 记录上一个周期的最后状态，用于平滑过渡
        var lastRadius = 0f
        var lastAlpha = 0
        
        animator.addUpdateListener { animation ->
            val fraction = animation.animatedValue as Float
            
            val circle = rippleCircles[index]
            
            // 防止width或height为0的情况
            if (width > 0 && height > 0) {
                // 更新半径（缩放动画）
                val minRadius = Math.min(width, height) * 0.1f
                val maxRadius = Math.max(width, height) * scaleFactor
                
                // 计算当前半径
                val targetRadius = minRadius + (maxRadius - minRadius) * fraction
                
                // 处理循环开始时的半径平滑过渡
                if (fraction < 0.05f && lastRadius > targetRadius) {
                    // 在新周期开始时，保持上一个周期的透明度为0
                    circle.radius = targetRadius
                    circle.color = Color.argb(
                        0,
                        Color.red(baseColor),
                        Color.green(baseColor),
                        Color.blue(baseColor)
                    )
                } else {
                    // 正常更新半径
                    circle.radius = targetRadius
                    
                    // 修改透明度计算逻辑
                    var alpha = 0f
                    if (fraction < fadeRatio) {
                        // 渐入阶段
                        alpha = (fraction / fadeRatio).pow(2)
                    } else if (fraction < (1 - fadeRatio)) {
                        // 中间阶段 - 随着圆变大而更快地降低透明度
                        val progress = (fraction - fadeRatio) / (1 - 2 * fadeRatio)
                        // 使用更陡峭的曲线，确保在接近结束前透明度已接近0
                        alpha = (1.0f - progress.pow(2f)) * (1.0f - progress)
                    } else {
                        // 渐出阶段 - 确保在结束时完全透明
                        alpha = 0f
                    }
                    
                    // 确保alpha值在有效范围内
                    val alphaInt = (alpha * 255 * 0.8f).toInt().coerceIn(0, 255)
                    
                    circle.color = Color.argb(
                        alphaInt,
                        Color.red(baseColor),
                        Color.green(baseColor),
                        Color.blue(baseColor)
                    )
                    
                    // 保存当前状态用于下一周期
                    lastRadius = circle.radius
                    lastAlpha = alphaInt
                }
                
                // 重绘视图
                invalidate()
            }
        }
        
        return animator
    }
    
    // 添加波纹效果（可选）
    fun addWaveEffect() {
        val waveAnimator = ValueAnimator.ofFloat(0.9f, 1.1f)
        waveAnimator.duration = 2000
        waveAnimator.repeatCount = ValueAnimator.INFINITE
        waveAnimator.repeatMode = ValueAnimator.REVERSE
        waveAnimator.interpolator = DecelerateInterpolator()
        
        waveAnimator.addUpdateListener { animation ->
            // 实现波纹效果的逻辑
            invalidate()
        }
        
        waveAnimator.start()
    }
    
    // 涟漪圆类
    private inner class RippleCircle {
        var radius = 0f
        var color = Color.TRANSPARENT
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        // 清理资源
        animatorSet?.cancel()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        Log.d(TAG, "尺寸变化: w=$w, h=$h, oldw=$oldw, oldh=$oldh")
        // 当视图大小改变时重启动画
        if (w > 0 && h > 0) {
            startRippleAnimation()
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        Log.d(TAG, "视图已附加到窗口")
    }

    // 添加测量方法，确保视图有尺寸
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        
        val widthMode = MeasureSpec.getMode(widthMeasureSpec)
        val widthSize = MeasureSpec.getSize(widthMeasureSpec)
        val heightMode = MeasureSpec.getMode(heightMeasureSpec)
        val heightSize = MeasureSpec.getSize(heightMeasureSpec)
        
        var width = widthSize
        var height = heightSize
        
        // 如果宽度是wrap_content，设置默认宽度
        if (widthMode == MeasureSpec.AT_MOST || widthMode == MeasureSpec.UNSPECIFIED) {
            width = 200
        }
        
        // 如果高度是wrap_content，设置默认高度
        if (heightMode == MeasureSpec.AT_MOST || heightMode == MeasureSpec.UNSPECIFIED) {
            height = 200
        }
        
        // 确保宽高相等（可选，如果你希望视图是正方形）
        val size = Math.min(width, height)
        setMeasuredDimension(size, size)
        
        Log.d(TAG, "onMeasure: width=$width, height=$height, 最终尺寸=$size")
    }
}