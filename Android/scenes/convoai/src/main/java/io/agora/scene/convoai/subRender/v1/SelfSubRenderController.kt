package io.agora.scene.convoai.subRender.v1

import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.subRender.ISubRenderController
import io.agora.scene.convoai.subRender.MessageParser

class SelfSubRenderController : ISubRenderController {

    companion object {
        private const val TAG = "SelfSubRenderController"
    }

    private var mMessageParser = MessageParser()

    var onUpdateStreamContent: ((isMe: Boolean, turnId: Int, text: String, isFinal: Boolean) -> Unit)? = null

    override fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?) {
        data?.let { bytes ->
            try {
                val rawString = String(bytes, Charsets.UTF_8)
                val message = mMessageParser.parseStreamMessage(rawString)
                message?.let { msg ->
                    CovLogger.d(TAG, "onStreamMessage: $msg")
                    val isFinal = msg["is_final"] as? Boolean ?: msg["final"] as? Boolean ?: false
                    val streamId = msg["stream_id"] as? Int ?: 0
                    val turnId = msg["turn_id"] as? Int ?: 0
                    val text = msg["text"] as? String ?: ""
                    if (text.isNotEmpty()) {
                        onUpdateStreamContent?.invoke((streamId != 0), turnId, text, isFinal)
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Process stream message error: ${e.message}")
            }
        }
    }
}