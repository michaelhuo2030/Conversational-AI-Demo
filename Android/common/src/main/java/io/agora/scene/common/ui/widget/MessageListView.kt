package io.agora.scene.common.ui.widget

import android.view.ViewGroup
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.util.dp
import io.agora.scene.common.databinding.CovMessageAgentItemBinding
import io.agora.scene.common.databinding.CovMessageMineItemBinding
import io.agora.scene.common.databinding.MessageListViewBinding

class MessageListView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    val TAG = "MessageListView"

    private val binding: MessageListViewBinding = MessageListViewBinding.inflate(LayoutInflater.from(context), this, true)
    private val messageAdapter: MessageAdapter = MessageAdapter()
    private var currentAgentMessage: Message? = null

    init {
        binding.rvMessages.layoutManager = LinearLayoutManager(context)
        binding.rvMessages.adapter = messageAdapter
        binding.rvMessages.itemAnimator = null
    }

    fun clearMessages() {
        currentAgentMessage = null
        messageAdapter.clearMessages()
    }

    fun updateStreamContent(isMe: Boolean, text: String, isFinal: Boolean = false) {
        if (isMe) {
            if (isFinal) {
                addMineMessage(text)
                completeCurrentMessage()
            }
        } else {
            if (isFinal) {
                if (currentAgentMessage == null) {
                    startNewAgentMessage(text)
                } else {
                    updateCurrentMessage(text)
                }
                completeCurrentMessage()
            } else {
                if (currentAgentMessage == null) {
                    startNewAgentMessage(text)
                } else {
                    updateCurrentMessage(text)
                }
            }
        }
    }

    private fun startNewAgentMessage(content: String) {
        val message = Message(false, content, false)
        messageAdapter.addMessage(message)
        currentAgentMessage = message
        checkAndScrollToBottom()
    }

    private fun completeCurrentMessage() {
        currentAgentMessage?.let {
            if (!messageAdapter.containsMessage(it)) {
                messageAdapter.addMessage(it)
            }
            currentAgentMessage = null
        }
        checkAndScrollToBottom()
    }

    private fun addMineMessage(text: String) {
        Log.d(TAG, "addUserMessage: $text")
        messageAdapter.addMessage(Message(true, text, true))
        checkAndScrollToBottom()
    }

    private fun updateCurrentMessage(content: String) {
        currentAgentMessage?.let {
            it.content = content
            messageAdapter.updateMessage(it)
            checkAndScrollToBottom()
        }
    }

    private var scrollRunnable: Runnable? = null
    private val scrollDelay = 500L
    private var isScrollScheduled = false
    private fun checkAndScrollToBottom() {
        if (isScrollScheduled) return
        scrollRunnable = Runnable {
            binding.rvMessages.post {
                val lastPosition = messageAdapter.itemCount - 1
                if (lastPosition >= 0) {
                    (binding.rvMessages.layoutManager as LinearLayoutManager).scrollToPositionWithOffset(lastPosition, -9999.dp.toInt())
                }
            }
            isScrollScheduled = false
        }
        binding.rvMessages.postDelayed(scrollRunnable!!, scrollDelay)
        isScrollScheduled = true
    }

    data class Message(
        val isMe: Boolean,
        var content: String,
        var isFinal: Boolean = false
    )

    class MessageAdapter : RecyclerView.Adapter<MessageAdapter.MessageViewHolder>() {

        private val messages = mutableListOf<Message>()

        abstract class MessageViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            abstract fun bind(message: Message)
        }

        class MineMessageViewHolder(private val binding: CovMessageMineItemBinding) : MessageViewHolder(binding.root) {
            override fun bind(message: Message) {
                binding.tvMessageContent.text = message.content
            }
        }

        class AgentMessageViewHolder(private val binding: CovMessageAgentItemBinding) : MessageViewHolder(binding.root) {
            override fun bind(message: Message) {
                binding.tvMessageContent.text = message.content
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MessageViewHolder {
            return if (viewType == 0) {
                MineMessageViewHolder(CovMessageMineItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
            } else {
                AgentMessageViewHolder(CovMessageAgentItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
            }
        }

        override fun onBindViewHolder(holder: MessageViewHolder, position: Int) {
            holder.bind(messages[position])
        }

        override fun getItemCount(): Int = messages.size

        override fun getItemViewType(position: Int): Int {
            return if (messages[position].isMe) 0 else 1
        }

        fun clearMessages() {
            messages.clear()
            notifyDataSetChanged()
        }

        fun addMessage(message: Message) {
            messages.add(message)
            notifyDataSetChanged()
        }

        fun getLastMessage(): Message? {
            return messages.lastOrNull()
        }

        fun containsMessage(message: Message): Boolean {
            return messages.contains(message)
        }

        fun notifyLastItemChanged() {
            notifyItemChanged(messages.size - 1)
        }

        fun updateMessage(message: Message) {
            val index = messages.indexOf(message)
            if (index != -1) {
                notifyItemChanged(index)
            } else {
                addMessage(message)
            }
        }
    }
}
