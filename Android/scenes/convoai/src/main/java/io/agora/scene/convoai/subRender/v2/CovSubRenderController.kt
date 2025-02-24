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
    val startMs: Long,
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
        const val TAG = "CovSubRenderController"
        const val TAG_UI = "CovSubRenderController-UI"
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
                            CovLogger.d(TAG_UI, "pts：$mPresentationMs, $subtitleMessage")
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
                            val startMs = (msg["start_ms"] as? Number)?.toLong() ?: 0L
                            // Parse words array
                            val wordsArray = msg["words"] as? List<Map<String, Any>>
                            val words = parseWords(wordsArray)
                            onAgentMessageReceived(turnId, startMs, text, words, status == TurnStatus.END)
                        }
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Process stream message error: ${e.message}")
            }
        }
    }

    private fun parseWords(wordsArray: List<Map<String, Any>>?): List<TurnWordInfo>? {
        if (wordsArray.isNullOrEmpty()) return null

        // Convert words array to WordInfo list and sort by startMs in ascending order
        val wordsList = wordsArray.map { wordMap ->
            TurnWordInfo(
                word = wordMap["word"] as? String ?: "",
                startMs = (wordMap["start_ms"] as? Number)?.toLong() ?: 0L,
            )
        }.toMutableList()

        // Return an immutable list to ensure thread safety
        return wordsList.toList()
    }

    @Volatile
    private var mRenderMode: SubRenderMode = SubRenderMode.Idle
        set(value) {
            field = value
            if (mRenderMode == SubRenderMode.Word) {
                mLastDequeuedTurn = null
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
        startMs: Long,
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
            CovLogger.d(TAG_UI, "pts：$mPresentationMs, $subtitleMessage")
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

            // The last turn to be dequeued
            mLastDequeuedTurn?.let { lastEnd ->
                if (turnId <= lastEnd.turnId) {
                    CovLogger.w(TAG, "Discarding the turn has already been processed: received=$turnId, latest=${lastEnd.turnId}")
                    return
                }
            }

            // Remove and get existing info in one operation
            val existingInfo = agentTurnQueue.find { it.turnId == turnId }?.also {
                agentTurnQueue.remove(it)
            }

            // Check if there is an existing message that needs to be merged
            if (existingInfo != null) {
                // Reset end flag of existing words if needed
                existingInfo.words.lastOrNull()?.let { lastWord ->
                    if (lastWord.isEnd) lastWord.isEnd = false
                }

                // Use new data if the new message has a later timestamp
                val useNewData = startMs >= existingInfo.startMs

                // Merge words and sort by timestamp
                val mergedWords = (existingInfo.words + newWords)
                    .sortedBy { it.startMs }    // Ensure sorted by timestamp
                    .toList()

                val newInfo = TurnMessageInfo(
                    turnId = turnId,
                    startMs = if (useNewData) startMs else existingInfo.startMs,
                    text = if (useNewData) text else existingInfo.text,
                    isFinal = if (useNewData) isFinal else existingInfo.isFinal,
                    words = mergedWords
                )

                // Mark the last word as end if this is the final message
                if (newInfo.isFinal && mergedWords.isNotEmpty()) {
                    mergedWords.last().isEnd = true
                }

                agentTurnQueue.offer(newInfo)
                CovLogger.d(TAG, "queue offer merged: $newInfo")
            } else {
                // No existing message, use new message directly
                val newInfo = TurnMessageInfo(
                    turnId = turnId,
                    startMs = startMs,
                    text = text,
                    isFinal = isFinal,
                    words = newWords
                )

                if (isFinal && newWords.isNotEmpty()) {
                    newWords.last().isEnd = true
                }

                agentTurnQueue.offer(newInfo)
                CovLogger.d(TAG, "queue offer new: $newInfo")
            }

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

    // The last turn to be dequeued
    @Volatile
    private var mLastDequeuedTurn: TurnMessageInfo? = null

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
                            CovLogger.d(TAG_UI, "pts：$mPresentationMs, $interruptedMessage")
                            onUpdateStreamContent?.invoke(interruptedMessage)
                        }
                    }
                    mLastDequeuedTurn = turn
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
            CovLogger.d(TAG_UI, "pts：$mPresentationMs, $newSubtitleMessage")
            onUpdateStreamContent?.invoke(newSubtitleMessage)

            if (targetIsEnd) {
                mLastDequeuedTurn = targetTurn
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