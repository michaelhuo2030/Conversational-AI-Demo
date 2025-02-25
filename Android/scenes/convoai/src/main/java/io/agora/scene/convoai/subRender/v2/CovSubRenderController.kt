package io.agora.scene.convoai.subRender.v2

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.agora.rtc2.IRtcEngineEventHandler
import io.agora.rtc2.RtcEngine
import io.agora.scene.common.BuildConfig
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.rtc.CovAudioFrameObserver
import io.agora.scene.convoai.subRender.MessageParser
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.ticker
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentLinkedQueue

data class SubRenderConfig (
    val rtcEngine: RtcEngine,
    val renderMode: SubRenderMode?,
    val view: ICovMessageListView?
)

// Producer: Single word information
data class TurnWordInfo constructor(
    val word: String,
    val startMs: Long,
    var status: SubtitleStatus = SubtitleStatus.Progress
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
    val status: TurnStatus,
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
class CovSubRenderController(
    private val config: SubRenderConfig
): IRtcEngineEventHandler() {

    companion object {
        const val TAG = "CovSubRenderController"
        const val TAG_UI = "CovSubRenderController-UI"
    }

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private var mMessageParser = MessageParser()

    init {
        config.rtcEngine.addHandler(this)
        config.rtcEngine.registerAudioFrameObserver(object : CovAudioFrameObserver() {
            override fun onPlaybackAudioFrameBeforeMixing(
                channelId: String?,
                uid: Int,
                type: Int,
                samplesPerChannel: Int,
                bytesPerSample: Int,
                channels: Int,
                samplesPerSec: Int,
                buffer: ByteBuffer?,
                renderTimeMs: Long,
                avsync_type: Int,
                rtpTimestamp: Int,
                presentationMs: Long
            ): Boolean {
                // Pass render time to subtitle controller
                if (BuildConfig.DEBUG) {
                    Log.d(TAG, "onPlaybackAudioFrameBeforeMixing $presentationMs")
                }
                mPresentationMs = presentationMs
                return false
            }
        })
        config.rtcEngine.setPlaybackAudioFrameBeforeMixingParameters(44100, 1)
    }

    override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
        if (!enable) return
        data?.let { bytes ->
            try {
                val rawString = String(bytes, Charsets.UTF_8)
                val message = mMessageParser.parseStreamMessage(rawString)
                message?.let { msg ->
                    CovLogger.d(TAG, "onStreamMessage parser：$msg")
                    val transcription = msg["object"] as? String ?: return
                    var isInterrupt = false
                    val isUserMsg: Boolean
                    when (transcription) {
                        // agent message
                        "assistant.transcription" -> { isUserMsg = false }
                        // user message
                        "user.transcription" -> { isUserMsg = true }
                        "message.interrupt" -> {
                            isUserMsg = false
                            isInterrupt = true
                        }
                        else -> return
                    }
                    //CovLogger.d(TAG, "onStreamMessage parser：$msg")
                    val turnId = (msg["turn_id"] as? Number)?.toLong() ?: 0L
                    val text = msg["text"] as? String ?: ""

                    // deal with interrupt message
                    if (isInterrupt) {
                        val startMs = (msg["start_ms"] as? Number)?.toLong() ?: 0L
                        onAgentMessageReceived(turnId, startMs, text, null, TurnStatus.INTERRUPTED)
                        return
                    }

                    if (text.isNotEmpty()) {
                        if (isUserMsg) {
                            val isFinal = msg["final"] as? Boolean ?: false
                            val subtitleMessage = SubtitleMessage(
                                turnId = turnId,
                                isMe = true,
                                text = text,
                                status = if (isFinal) SubtitleStatus.End else SubtitleStatus.Progress
                            )
                            // Local user messages are directly callbacked out
                            CovLogger.d(TAG_UI, "pts：$mPresentationMs, $subtitleMessage")
                            runOnMainThread {
                                config.view?.onUpdateStreamContent(subtitleMessage)
                            }
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
                            onAgentMessageReceived(turnId, startMs, text, words, status)
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
                mCurSubtitleMessage = null
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
    private var enable = false

    fun enable(enable: Boolean) {
        this.enable = enable
    }

    fun setRenderMode(renderMode: SubRenderMode) {
        this.mRenderMode = renderMode
    }

    fun release() {
        this.mRenderMode = SubRenderMode.Idle
        stopSubtitleTicker()
        coroutineScope.cancel()
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
        mLastDequeuedTurn = null
        agentTurnQueue.clear()
        tickerJob?.cancel()
        tickerJob = null
        mPresentationMs = 0
    }

    private fun onAgentMessageReceived(
        turnId: Long,
        startMs: Long,
        text: String,
        words: List<TurnWordInfo>?,
        status: TurnStatus
    ) {
        // Auto detect mode
        if (mRenderMode == SubRenderMode.Idle) {
            // TODO turn 0 interrupt ??
            if (status == TurnStatus.INTERRUPTED) return
            mRenderMode = if (words != null) {
                SubRenderMode.Word
            } else {
                SubRenderMode.Text
            }
            CovLogger.d(TAG, "Mode auto detected: $mRenderMode")
        }

        if (mRenderMode == SubRenderMode.Text && status != TurnStatus.INTERRUPTED) {
            val subtitleMessage = SubtitleMessage(
                turnId = turnId,
                isMe = false,
                text = text,
                status = if (status == TurnStatus.END) SubtitleStatus.End else SubtitleStatus.Progress
            )
            // Agent text mode messages are directly callback out
            CovLogger.d(TAG_UI, "[Text Mode]pts：$mPresentationMs, $subtitleMessage")
            runOnMainThread {
                config.view?.onUpdateStreamContent(subtitleMessage)
            }
            return
        }

        // Word mode processing
        val newWords = words?.toList() ?: emptyList()

        synchronized(agentTurnQueue) {
            // TODO ? if turn2 agent message is before turn1 interrupt
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
                if (status == TurnStatus.INTERRUPTED && it.status == TurnStatus.INTERRUPTED) return
                agentTurnQueue.remove(it)
            }

            // Check if there is an existing message that needs to be merged
            if (existingInfo != null) {
                if (status == TurnStatus.INTERRUPTED) {
                    // Interrupt all words from the last one before startMs to the end of the word list
                    var lastBeforeStartMs: TurnWordInfo? = null
                    val mergedWords = existingInfo.words.toMutableList()
                    mergedWords.forEach { word ->
                        if (word.startMs <= startMs) {
                            lastBeforeStartMs = word
                        }
                        if (word.startMs >= startMs) {
                            word.status = SubtitleStatus.Interrupted
                        }
                    }
                    lastBeforeStartMs?.status = SubtitleStatus.Interrupted

                    val newInfo = TurnMessageInfo(
                        turnId = turnId,
                        startMs = existingInfo.startMs,
                        text = existingInfo.text,
                        status = status,
                        words = mergedWords
                    )
                    agentTurnQueue.offer(newInfo)
                } else {
                    // Reset end flag of existing words if needed
                    existingInfo.words.lastOrNull()?.let { lastWord ->
                        if (lastWord.status == SubtitleStatus.End) lastWord.status = SubtitleStatus.Progress
                    }

                    // Use new data if the new message has a later timestamp
                    val useNewData = startMs >= existingInfo.startMs

                    // Merge words and sort by timestamp
                    val mergedWords = existingInfo.words.toMutableList()

                    newWords.forEach { newWord ->
                        // Check if a word with the same startMs already exists
                        if (existingInfo.words.none { it.startMs == newWord.startMs }) {
                            mergedWords.add(newWord)
                        }
                    }

                    val sortedMergedWords = mergedWords.sortedBy { it.startMs }.toList()

                    // Traverse sortedMergedWords, set the status of the word after the first Interrupted word to Interrupted
                    var foundInterrupted = false
                    sortedMergedWords.forEach { word ->
                        if (foundInterrupted || word.status == SubtitleStatus.Interrupted) {
                            word.status = SubtitleStatus.Interrupted
                            foundInterrupted = true
                        }
                    }

                    // TODO interrupt / end
                    val newInfo = TurnMessageInfo(
                        turnId = turnId,
                        startMs = if (useNewData) startMs else existingInfo.startMs,
                        text = if (useNewData) text else existingInfo.text,
                        status = if (useNewData) status else existingInfo.status,
                        words = sortedMergedWords
                    )

                    // Mark the last word as end if this is the final message
                    if (newInfo.status == TurnStatus.END && sortedMergedWords.isNotEmpty()) {
                        sortedMergedWords.last().status = SubtitleStatus.End
                    }
                    agentTurnQueue.offer(newInfo)
                }
            } else {
                // No existing message, use new message directly
                val newInfo = TurnMessageInfo(
                    turnId = turnId,
                    startMs = startMs,
                    text = text,
                    status = status,
                    words = newWords
                )

                if (status == TurnStatus.END && newWords.isNotEmpty()) {
                    newWords.last().status = SubtitleStatus.End
                }

                agentTurnQueue.offer(newInfo)
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
                .mapNotNull { turn ->
                    // Check for interrupt condition
                    val interruptWord = turn.words.find { it.status == SubtitleStatus.Interrupted && it.startMs <= mPresentationMs }
                    if (interruptWord != null) {
                        val words = turn.words.filter { it.startMs <= interruptWord.startMs }
                        val interruptedText = words.joinToString("") { it.word }
                        // create interrupted message
                        val interruptedMessage = SubtitleMessage(
                            turnId = turn.turnId,
                            isMe = false,
                            text = interruptedText,
                            status = SubtitleStatus.Interrupted
                        )
                        CovLogger.d(TAG_UI, "[interrupt1]pts：$mPresentationMs, $interruptedMessage")
                        runOnMainThread {
                            config.view?.onUpdateStreamContent(interruptedMessage)
                        }
                    
                        // remove the turn if interrupt condition is met
                        mLastDequeuedTurn = turn
                        agentTurnQueue.remove(turn)
                        mCurSubtitleMessage = null
                        CovLogger.d(TAG, "Removed interrupted turn: ${turn.turnId}")
                        null
                    } else {
                        val words = turn.words.filter { it.startMs <= mPresentationMs }
                        if (words.isNotEmpty()) turn to words else null
                    }
                }
                .toList()
        
            if (availableTurns.isEmpty()) return
        
            // Find the latest turn to display
            val latestValidTurn = availableTurns.last()
            val (targetTurn, targetWords) = latestValidTurn
            val targetIsEnd = targetWords.last().status == SubtitleStatus.End
        
            // Interrupt all previous turns
            if (availableTurns.size > 1) {
                // Iterate through all turns except the last one
                for (i in 0 until availableTurns.size - 1) {
                    val (turn, _) = availableTurns[i]
                    mCurSubtitleMessage?.let { current ->
                        if (current.turnId == turn.turnId) {
                            val interruptedMessage = current.copy(status = SubtitleStatus.Interrupted)
                            CovLogger.d(TAG_UI, "[interrupt2]pts：$mPresentationMs, $interruptedMessage")
                            runOnMainThread {
                                config.view?.onUpdateStreamContent(interruptedMessage)
                            }
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
            if (targetIsEnd) {
                CovLogger.d(TAG_UI, "[end]pts：$mPresentationMs, $newSubtitleMessage")
            } else {
                CovLogger.d(TAG_UI, "[progress]pts：$mPresentationMs, $newSubtitleMessage")
            }
            runOnMainThread {
                config.view?.onUpdateStreamContent(newSubtitleMessage)
            }
        
            if (targetIsEnd) {
                mLastDequeuedTurn = targetTurn
                agentTurnQueue.remove(targetTurn)
                mCurSubtitleMessage = null
            } else {
                mCurSubtitleMessage = newSubtitleMessage
            }
        }
    }

    private fun runOnMainThread(r: java.lang.Runnable) {
        if (Thread.currentThread() == mainHandler.looper.thread) {
            r.run()
        } else {
            mainHandler.post(r)
        }
    }
}