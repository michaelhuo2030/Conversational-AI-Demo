package io.agora.scene.convoai.subRender.v2

import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.subRender.ISubRenderController
import io.agora.scene.convoai.subRender.MessageParser
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.ticker
import java.util.concurrent.ConcurrentLinkedQueue

// Producer: Single word information
data class TurnWordInfo constructor(
    val word: String,
    val startMs: Long,
    var isEnd: Boolean = false
)

enum class TurnStatus {
    IN_PROGRESS,
    END,
    INTERRUPTED,
    UNKNOWN,
}

// Producer: Single sentence information
data class TurnMessageInfo(
    val turnId: Long,
    val text: String,
    val isFinal: Boolean,
    val words: List<TurnWordInfo>
)

enum class SubtitleStatus {
    Progress,
    End,
    Interrupted
}

// Consumer: Single sentence information for rendering
data class SubtitleMessage(
    val turnId: Long,
    val isMe: Boolean,
    val text: String,
    var status: SubtitleStatus
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

    var onUpdateStreamContent: ((subtitle: SubtitleMessage) -> Unit)? = null

    override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
        data?.let { bytes ->
            try {
                val rawString = String(bytes, Charsets.UTF_8)
                val message = mMessageParser.parseStreamMessage(rawString)
                message?.let { msg ->
                    val transcription = msg["object"] as? String ?: return
                    val isMe = when (transcription) {
                        // agent message
                        "assistant.transcription" -> false
                        // user message
                        "user.transcription" -> true
                        else -> return
                    }
                    CovLogger.d(TAG, "onStreamMessage parser：$msg")
                    val turnId = (msg["turn_id"] as? Number)?.toLong() ?: 0L
                    val text = msg["text"] as? String ?: ""

                    if (text.isNotEmpty()) {
                        if (isMe) {
                            val isFinal = msg["final"] as? Boolean ?: false
                            val subtitleMessage = SubtitleMessage(
                                turnId = turnId,
                                isMe = true,
                                text = text,
                                status = if (isFinal) SubtitleStatus.End else SubtitleStatus.Progress
                            )
                            // Local user messages are directly callbacked out
                            onUpdateStreamContent?.invoke(subtitleMessage)
                        } else {

                            // 0: in-progress, 1: end gracefully, 2: interrupted, otherwise undefined
                            val turnStatusInt = (msg["turn_status"] as? Number)?.toLong() ?: 0L
                            val status: TurnStatus = when ((msg["turn_status"] as? Number)?.toLong() ?: 0L) {
                                0L -> TurnStatus.IN_PROGRESS
                                1L -> TurnStatus.END
                                2L -> TurnStatus.END
                                else -> TurnStatus.UNKNOWN
                            }
                            // Discarding and not processing the message with Unknown status.
                            if (status == TurnStatus.UNKNOWN) {
                                CovLogger.e(TAG, "unknown turn_status:$turnStatusInt")
                                return
                            }
                            // Parse words array
                            val wordsArray = msg["words"] as? List<Map<String, Any>>
                            val words = parseWords(status, wordsArray)
                            onAgentMessageReceived(turnId, text, words, status == TurnStatus.END)
                        }
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Process stream message error: ${e.message}")
            }
        }
    }

    private fun parseWords(turnStatus: TurnStatus, wordsArray: List<Map<String, Any>>?): List<TurnWordInfo>? {
        if (wordsArray.isNullOrEmpty()) return null

        // Convert words array to WordInfo list and sort by startMs in ascending order
        val wordsList = wordsArray.map { wordMap ->
            TurnWordInfo(
                word = wordMap["word"] as? String ?: "",
                startMs = (wordMap["start_ms"] as? Number)?.toLong() ?: 0L,
            )
        }.sortedBy { it.startMs }.toMutableList()

        // If turnStatus is not progress and list is not empty, set the last word's isEnd to true
        if (turnStatus != TurnStatus.IN_PROGRESS && wordsList.isNotEmpty()) {
            wordsList.last().isEnd = true
        }

        // Return an immutable list to ensure thread safety
        return wordsList.toList()
    }

    @Volatile
    private var mRenderMode: SubRenderMode = SubRenderMode.Idle
        set(value) {
            field = value
            if (mRenderMode == SubRenderMode.Word) {
                startSubtitleTicker()
            } else {
                stopSubtitleTicker()
            }
        }

    @Volatile
    private var mPresentationMs: Long = 0

    private val agentTurnQueue = ConcurrentLinkedQueue<TurnMessageInfo>()

    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var tickerJob: Job? = null

    fun setRenderMode(renderMode: SubRenderMode) {
        this.mRenderMode = renderMode
    }

    private fun startSubtitleTicker() {
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

    private fun stopSubtitleTicker() {
        mCurSubtitleMessage = null
        agentTurnQueue.clear()
        tickerJob?.cancel()
        tickerJob = null
        mPresentationMs = 0
    }

    fun onPlaybackAudioFrameBeforeMixing(presentationMs: Long) {
        mPresentationMs = presentationMs
    }

    private fun onAgentMessageReceived(
        turnId: Long,
        text: String,
        words: List<TurnWordInfo>?,
        isFinal: Boolean,
    ) {
        // Auto detect mode
        if (mRenderMode == SubRenderMode.Idle) {
            mRenderMode = if (words != null) {
                SubRenderMode.Word
            } else {
                SubRenderMode.Text
            }
            CovLogger.d(TAG, "Mode auto detected: $mRenderMode")
        }

        if (mRenderMode == SubRenderMode.Text) {
            val subtitleMessage = SubtitleMessage(
                turnId = turnId,
                isMe = false,
                text = text,
                status = if (isFinal) SubtitleStatus.End else SubtitleStatus.Progress
            )
            // Agent text mode messages are directly callbacked out
            onUpdateStreamContent?.invoke(subtitleMessage)
            return
        }

        // Word mode processing
        val newWords = words?.toList() ?: emptyList()

        synchronized(agentTurnQueue) {
            // Check if this turn is older than the latest turn in queue
            val lastTurn = agentTurnQueue.lastOrNull()
            if (lastTurn != null && turnId < lastTurn.turnId) {
                CovLogger.w(TAG, "Discarding old turn: received=$turnId, latest=${lastTurn.turnId}")
                return
            }

            // Remove and get existing info in one operation
            val existingInfo = agentTurnQueue.find { it.turnId == turnId }?.also {
                agentTurnQueue.remove(it)
            }

            // Merge words while preserving order
            val mergedWords = if (existingInfo != null && existingInfo.words.isNotEmpty()) {
                existingInfo.words + newWords
            } else {
                newWords
            }

            val newInfo = TurnMessageInfo(
                turnId = turnId,
                text = text,
                isFinal = isFinal,
                words = mergedWords
            )

            agentTurnQueue.offer(newInfo)

            // Cleanup old turns
            while (agentTurnQueue.size > 5) {
                agentTurnQueue.poll()?.let { removed ->
                    CovLogger.d(TAG, "Removed old turn: ${removed.turnId}")
                }
            }
        }
    }

    // Current subtitle rendering data, only kept if not in End or Interrupted status
    @Volatile
    private var mCurSubtitleMessage: SubtitleMessage? = null

    private fun updateSubtitleDisplay() {
        // Audio callback PTS is not assigned.
        if (mPresentationMs <= 0) return
        if (mRenderMode != SubRenderMode.Word) return

        synchronized(agentTurnQueue) {
            // Get all turns that meet display conditions
            val availableTurns = agentTurnQueue.asSequence()
                .map { turn ->
                    val words = turn.words.filter { it.startMs <= mPresentationMs }
                    turn to words
                }
                .filter { (_, words) -> words.isNotEmpty() }
                .toList()

            if (availableTurns.isEmpty()) return

            // Find the latest turn to display
            val latestValidTurn = availableTurns.last()
            val (targetTurn, targetWords) = latestValidTurn
            val targetIsEnd = targetWords.last().isEnd

            // Interrupt all previous turns
            if (availableTurns.size > 1) {
                // Iterate through all turns except the last one
                for (i in 0 until availableTurns.size - 1) {
                    val (turn, _) = availableTurns[i]
                    mCurSubtitleMessage?.let { current ->
                        if (current.turnId == turn.turnId) {
                            val interruptedMessage = current.copy(status = SubtitleStatus.Interrupted)
                            onUpdateStreamContent?.invoke(interruptedMessage)
                        }
                    }
                    // Remove the interrupted turn from queue
                    agentTurnQueue.remove(turn)
                }
                mCurSubtitleMessage = null
            }

            // Display the latest turn
            val newSubtitleMessage = SubtitleMessage(
                turnId = targetTurn.turnId,
                isMe = false,
                text = if (targetIsEnd) targetTurn.text
                else targetWords.joinToString("") { it.word },
                status = if (targetIsEnd) SubtitleStatus.End else SubtitleStatus.Progress
            )
            onUpdateStreamContent?.invoke(newSubtitleMessage)

            if (targetIsEnd) {
                agentTurnQueue.remove(targetTurn)
                mCurSubtitleMessage = null
            } else {
                mCurSubtitleMessage = newSubtitleMessage
            }
        }
    }

    fun resetClear() {
        stopSubtitleTicker()
        coroutineScope.cancel()
    }
}