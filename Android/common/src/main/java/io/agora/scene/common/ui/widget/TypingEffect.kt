package io.agora.scene.common.ui.widget

import android.os.Handler
import android.widget.TextView

class TypingEffect(
    private val textView: TextView, // 用来显示文本的 TextView
    private val text1: String, // 第一次显示的文本
    private val text2: String, // 第二次显示的文本
    private val cursor: String = "●", // 光标符号
    private val speed: Int = 10, // 打字速度（每秒字符数）
    private val pauseTime1: Int = 300, // 减少停留时间
    private val pauseTime2: Int = 1000, // 减少停留时间
    private val blinkSpeed: Double = 2.0 // 增加闪烁速度
) {
    private var handler: Handler? = Handler()
    private var time: Int = 0 // 当前时间（毫秒）
    private var isRunning = false

    // 计算每个阶段的时间（单位：毫秒）
    private val typeTime1 = (text1.length / speed.toDouble() * 1000).toInt() // 第一次打字时间（毫秒）
    private val typeTime2 = (text2.length / speed.toDouble() * 1000).toInt() // 第二次打字时间（毫秒）
    private val deleteTime1 = (text1.length / speed.toDouble() * 1000).toInt() // 第一次删除时间（毫秒）
    private val deleteTime2 = (text2.length / speed.toDouble() * 1000).toInt() // 第二次删除时间（毫秒）
    private val totalTime = typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 // 总循环时间（毫秒）

    fun startTypingAnimation() {
        if (isRunning) return
        isRunning = true
        animateNextFrame()
    }

    private fun animateNextFrame() {
        if (!isRunning) return

        val cycleTime = (time % totalTime)
        var visibleText = ""

        // 计算当前显示的文本
        when {
            cycleTime < typeTime1 -> {
                // 第一次打字
                val charCount = (cycleTime * speed / 1000)
                visibleText = text1.substring(0, charCount)
            }
            cycleTime < typeTime1 + pauseTime2 -> {
                // 第一次打字后的停顿
                visibleText = text1
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 -> {
                // 第一次删除
                val charCount = text1.length - ((cycleTime - typeTime1 - pauseTime2) * speed / 1000)
                visibleText = text1.substring(0, charCount)
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 -> {
                // 第一次删除后的停顿
                visibleText = ""
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 -> {
                // 第二次打字
                val charCount = ((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1) * speed / 1000)
                visibleText = text2.substring(0, charCount)
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 -> {
                // 第二次打字后的停顿
                visibleText = text2
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 -> {
                // 第二次删除
                val charCount = text2.length - ((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1 - typeTime2 - pauseTime2) * speed / 1000)
                visibleText = text2.substring(0, charCount)
            }
            cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 + pauseTime1 -> {
                // 第二次删除后的停顿
                visibleText = ""
            }
        }

        // 修改光标闪烁逻辑
        if (cycleTime < typeTime1 ||
            cycleTime in (typeTime1 until (typeTime1 + pauseTime2)) ||
            cycleTime in (typeTime1 + pauseTime2 until (typeTime1 + pauseTime2 + deleteTime1)) ||
            cycleTime in (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 until (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2)) ||
            cycleTime in (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 until (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2)) ||
            cycleTime in (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 until (typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2))
        ) {
            // 修改光标闪烁计算方式
            val isVisible = (time / 500) % 2 == 0 // 每500ms闪烁一次
            if (isVisible) {
                visibleText += cursor
            }
        }

        // 换行并居中
        val lines = visibleText.split("\n")
        var maxLength = 0
        for (line in lines) {
            val lineLength = line.replace(Regex("\u0000.."), "").length // 忽略光标字符的长度
            maxLength = maxOf(maxLength, lineLength)
        }

        // 居中对齐
        var centeredText = ""
        for (line in lines) {
            val lineLength = line.replace(Regex("\u0000.."), "").length
            val padding = ((maxLength - lineLength) / 2).toInt()
            centeredText += " ".repeat(padding) + line + "\n"
        }

        // 更新 TextView
        textView.text = centeredText.trim()

        // 更新计时器
        time += 50 // 减少更新间隔，使动画更流畅
        handler?.postDelayed({ animateNextFrame() }, 50)
    }

    fun stop() {
        isRunning = false
        handler?.removeCallbacksAndMessages(null)
        handler = null
    }
}