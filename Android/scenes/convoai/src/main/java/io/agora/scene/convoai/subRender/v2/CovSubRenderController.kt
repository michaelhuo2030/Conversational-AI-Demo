package io.agora.scene.convoai.subRender.v2

import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.subRender.ISubRenderController
import io.agora.scene.convoai.subRender.MessageParser
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.ticker
import java.util.concurrent.atomic.AtomicReference

data class WordInfo(
    val word: String,
    val startMs: Long,
    val durationMs: Long,
    val stable: Boolean
)

// 定义字幕更新的数据类
data class SubtitleInfo(
    val turnId: Int,
    val text: String,
    val isFinal: Boolean,
    val words: List<WordInfo>
)

enum class SubRenderMode {
    Idle,
    Text,
    Word
}

/**
 * Subtitle Rendering Controller
 *
 * @constructor Create empty Cov sub render controller
 */
class CovSubRenderController : ISubRenderController {

    companion object {
        private const val TAG = "CovSubRenderController"
    }

    private var mMessageParser = MessageParser()

    var onUpdateStreamContent: ((isMe: Boolean, turnId: Int, text: String, isFinal: Boolean) -> Unit)? = null

    override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
        data?.let { bytes ->
            try {
                val rawString = String(bytes, Charsets.UTF_8)
                val message = mMessageParser.parseStreamMessage(rawString)
                message?.let { msg ->

                    CovLogger.d(TAG, "onStreamMessage parser：$msg")
                    val isFinal = msg["final"] as? Boolean ?: false
                    val streamId = msg["stream_id"] as? Int ?: 0
                    val turnId = msg["turn_id"] as? Int ?: 0
                    val text = msg["text"] as? String ?: ""
                    val turnStatus = msg["turn_status"] as? Int ?: 0
                    val startMs = msg["start_ms"] as? Long ?: ""

                    if (text.isNotEmpty()) {
                        if (streamId == 0) { // agent
                            // Parse words array
                            val wordsArray = msg["words"] as? List<Map<String, Any>>
                            val words = parseWords(wordsArray)
                            onStreamMessageReceived(turnId, text, turnStatus!=0, words)
                        } else {
                            onUpdateStreamContent?.invoke(true, turnId, text, isFinal)
                        }
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Process stream message error: ${e.message}")
            }
        }
    }

    private fun parseWords(wordsArray: List<Map<String, Any>>?): List<WordInfo>? {
        if (wordsArray.isNullOrEmpty()) return null
        return wordsArray.map { wordMap ->
            WordInfo(
                word = wordMap["word"] as? String ?: "",
                startMs = (wordMap["start_ms"] as? Double)?.toLong() ?: 0L,
                durationMs = (wordMap["duration_ms"] as? Double)?.toLong() ?: 0L,
                stable = wordMap["stable"] as? Boolean ?: false
            )
        }
    }

    @Volatile
    private var mRenderMode: SubRenderMode = SubRenderMode.Text

    @Volatile
    private var mRenderTimeMs: Long = 0

    // 使用 ConcurrentHashMap 替代 synchronized map
    private val turnsWordsMap = ConcurrentHashMap<Int, MutableList<WordInfo>>()
    private val currentTurnId = AtomicReference(0)
    private val currentText = AtomicReference("")
    private val isFinal = AtomicReference(false)

    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var tickerJob: Job? = null

    // 修改回调接口返回更完整的信息
    var onSubtitleUpdate: ((SubtitleInfo) -> Unit)? = null

    fun setRenderMode(renderMode: SubRenderMode) {
        this.mRenderMode = renderMode
        // 切换模式时清理数据
        turnsWordsMap.clear()
    }

    fun startSubtitleTicker() {
        tickerJob?.cancel()
        tickerJob = coroutineScope.launch {
            val ticker = ticker(delayMillis = 200)
            try {
                for (unit in ticker) {
                    updateSubtitleDisplay()
                }
            } finally {
                ticker.cancel()
            }
        }
    }

    fun onPlaybackAudioFrameBeforeMixing(renderTimeMs: Long) {
        mRenderTimeMs = renderTimeMs
    }

    fun onStreamMessageReceived(
        turnId: Int,
        text: String,
        isFinal: Boolean,
        words: List<WordInfo>?
    ) {
        // 自动检测模式
        if (mRenderMode == SubRenderMode.Idle) {
            mRenderMode = if (words != null) {
                SubRenderMode.Word
            } else {
                SubRenderMode.Text
            }
        }

        currentTurnId.set(turnId)
        currentText.set(text)
        this.isFinal.set(isFinal)

        when (mRenderMode) {
            SubRenderMode.Word -> {
                // Word 模式下，只有在有 words 时才累加
                words?.let { wordsList ->
                    val turnWords = turnsWordsMap.getOrPut(turnId) { mutableListOf() }
                    turnWords.addAll(wordsList)
                    cleanOldTurns()
                }
            }

            SubRenderMode.Text -> {
                // Text 模式下不需要存储 words
                if (isFinal) {
                    turnsWordsMap.clear()
                }
            }

            SubRenderMode.Idle -> {
                // Idle 模式下清空数据
                turnsWordsMap.clear()
            }
        }
    }

    private fun cleanOldTurns() {
        if (turnsWordsMap.size <= 5) return
        val sortedTurns = turnsWordsMap.keys.sortedDescending()
        val turnsToRemove = sortedTurns.drop(5)
        turnsToRemove.forEach { turnId ->
            turnsWordsMap.remove(turnId)
        }
    }

    private fun updateSubtitleDisplay() {
        val currentId = currentTurnId.get()
        val text = currentText.get()
        val isFinal = isFinal.get()

        when (mRenderMode) {
            SubRenderMode.Word -> {
                val currentTurnWords = turnsWordsMap[currentId] ?: return
                // 找出当前时间应该显示的单词
                val wordsToShow = currentTurnWords.filter { word ->
                    mRenderTimeMs >= word.startMs
                }
                if (wordsToShow.isNotEmpty()) {
                    val subtitleText = wordsToShow.joinToString("") { it.word }
                    coroutineScope.launch {
                        onSubtitleUpdate?.invoke(
                            SubtitleInfo(
                                turnId = currentId,
                                text = subtitleText,
                                isFinal = isFinal,
                                words = wordsToShow
                            )
                        )
                    }
                }
            }

            SubRenderMode.Text -> {
                // Text 模式直接返回完整文本
                if (text.isNotEmpty()) {
                    coroutineScope.launch {
                        onSubtitleUpdate?.invoke(
                            SubtitleInfo(
                                turnId = currentId,
                                text = text,
                                isFinal = isFinal,
                                words = emptyList()
                            )
                        )
                    }
                }
            }

            SubRenderMode.Idle -> {
                // Idle 模式不做任何处理
            }
        }
    }

    fun clear() {
        tickerJob?.cancel()
        tickerJob = null
        coroutineScope.cancel()

        turnsWordsMap.clear()
        currentTurnId.set(0)
        currentText.set("")
        isFinal.set(false)
        mRenderTimeMs = 0
        mRenderMode = SubRenderMode.Text
    }
}