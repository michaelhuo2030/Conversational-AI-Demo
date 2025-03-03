package io.agora.scene.convoai.subRender.v2

import android.view.ViewGroup
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import androidx.core.view.isVisible
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.databinding.CovMessageAgentItemBinding
import io.agora.scene.convoai.databinding.CovMessageListViewBinding
import io.agora.scene.convoai.databinding.CovMessageMineItemBinding

class CovMessageListView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr), IConversationSubtitleCallback {

    val TAG = "CovMessageListView"

    private val binding: CovMessageListViewBinding =
        CovMessageListViewBinding.inflate(LayoutInflater.from(context), this, true)
    private val messageAdapter: MessageAdapter = MessageAdapter()
    private var currentAgentMessage: Message? = null
    private var currentUserMessage: Message? = null
    private var autoScrollToBottom = true

    init {
        binding.rvMessages.layoutManager = LinearLayoutManager(context)
        binding.rvMessages.adapter = messageAdapter
        binding.rvMessages.itemAnimator = null
        binding.rvMessages.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrollStateChanged(recyclerView: RecyclerView, newState: Int) {
                super.onScrollStateChanged(recyclerView, newState)
                Log.d(TAG, "onScrollStateChanged: $newState")
                when (newState) {
                    RecyclerView.SCROLL_STATE_IDLE -> {
                        checkShowToBottomButton()
                    }

                    RecyclerView.SCROLL_STATE_DRAGGING -> {
                        autoScrollToBottom = false
                    }
                }
            }

            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
            }
        })
        binding.btnToBottom.setOnClickListener {
            autoScrollToBottom = true
            binding.cvToBottom.visibility = View.INVISIBLE
            scrollToBottom()
        }
    }

    fun clearMessages() {
        autoScrollToBottom = true
        binding.cvToBottom.visibility = View.INVISIBLE
        currentAgentMessage = null
        currentUserMessage = null
        messageAdapter.clearMessages()
    }

    fun getAllMessages(): List<Message> {
        return messageAdapter.getAllMessage()
    }

    fun updateAgentName(str: String) {
        messageAdapter.updateFromTitle(str)
    }

    private fun handleMessage(subtitleMessage: SubtitleMessage) {
        // Try to find existing message with same turnId
        messageAdapter.getMessageByTurnId(subtitleMessage.turnId, subtitleMessage.userId == 0)?.let { existingMessage ->
            // Update existing message
            existingMessage.apply {
                content = subtitleMessage.text
                status = subtitleMessage.status
            }
            messageAdapter.updateMessage(existingMessage)
        } ?: run {
            // Create new message
            val newMessage = Message(
                isMe = subtitleMessage.userId == 0,
                turnId = subtitleMessage.turnId,
                content = subtitleMessage.text,
                status = subtitleMessage.status
            )

            // Determine message insertion position
            when {
                // User message: try to insert before corresponding agent message
                subtitleMessage.userId == 0 -> {
                    messageAdapter.getMessageByTurnId(subtitleMessage.turnId, false)?.let { agentMessage ->
                        val agentIndex = messageAdapter.getMessageIndex(agentMessage)
                        if (agentIndex != -1) {
                            messageAdapter.insertMessage(agentIndex, newMessage)
                            return
                        }
                    }
                    messageAdapter.addMessage(newMessage)
                }
                // Agent greeting message (turnId = 0): insert at the beginning
                subtitleMessage.turnId == 0L -> {
                    messageAdapter.insertMessage(0, newMessage)
                }
                // Normal agent message: append to the end
                else -> {
                    messageAdapter.addMessage(newMessage)
                }
            }
        }
        if (autoScrollToBottom) {
            binding.rvMessages.post {
                scrollToBottom()
            }
        } else {
            checkShowToBottomButton()
        }
    }

    private var scrollRunnable: Runnable? = null
    private val scrollDelay = 200L
    private var isScrollScheduled = false
    private fun checkAndScrollToBottom() {
        if (isScrollScheduled) {
            scrollRunnable?.let { binding.rvMessages.removeCallbacks(it) }
        }
        
        scrollRunnable = Runnable {
            binding.rvMessages.post {
                scrollToBottom()
            }
            isScrollScheduled = false
        }
        binding.rvMessages.postDelayed(scrollRunnable!!, scrollDelay)
        isScrollScheduled = true
    }

    private fun scrollToBottom() {
        val lastPosition = messageAdapter.itemCount - 1
        if (lastPosition >= 0) {
            binding.rvMessages.smoothScrollToPosition(lastPosition)
        }
    }

    private fun checkShowToBottomButton() {
        val layoutManager = binding.rvMessages.layoutManager as LinearLayoutManager
        val lastItemPosition = layoutManager.findLastVisibleItemPosition()
        val lastIndex = messageAdapter.itemCount - 1
        val lastVisible = (lastIndex == lastItemPosition)
        Log.d(TAG, "lastItemPosition: $lastItemPosition, lastIndex: $lastIndex, lastVisible: $lastVisible")
        if (lastVisible) {
            binding.cvToBottom.visibility = View.INVISIBLE
            autoScrollToBottom = true
        } else {
            binding.cvToBottom.visibility = View.VISIBLE
            autoScrollToBottom = false
        }
    }

    data class Message constructor(
        val isMe: Boolean,
        val turnId: Long,
        var content: String,
        var status: SubtitleStatus,
    )

    class MessageAdapter : RecyclerView.Adapter<MessageAdapter.MessageViewHolder>() {

        private var fromTitle: String = ""
        private val messages = mutableListOf<Message>()

        abstract class MessageViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            abstract fun bind(message: Message)
        }

        class MineMessageViewHolder(private val binding: CovMessageMineItemBinding) : MessageViewHolder(binding.root) {
            override fun bind(message: Message) {
                binding.tvMessageContent.text = message.content
            }
        }

        inner class AgentMessageViewHolder(private val binding: CovMessageAgentItemBinding) :
            MessageViewHolder(binding.root) {
            override fun bind(message: Message) {
                binding.tvMessageTitle.text = fromTitle

                when (message.status) {
                    SubtitleStatus.End -> {
                        binding.tvMessageContent.text = message.content
                        binding.layoutMessageInterrupt.isVisible = false
                    }

                    SubtitleStatus.Interrupted -> {
                        binding.tvMessageContent.text = message.content
                        binding.layoutMessageInterrupt.isVisible = true
//                        val htmlText =
//                            "${message.content} <img src=\"${io.agora.scene.common.R.drawable.ai_interrupt}\"/>"
//                        binding.tvMessageContent.text = HtmlCompat.fromHtml(
//                            htmlText,
//                            HtmlCompat.FROM_HTML_MODE_COMPACT,
//                            object : Html.ImageGetter {
//                                override fun getDrawable(source: String?): Drawable {
//                                    val drawable = ContextCompat.getDrawable(
//                                        binding.root.context,
//                                        io.agora.scene.common.R.drawable.ai_interrupt
//                                    ) ?: return ColorDrawable(Color.TRANSPARENT)
//
//                                    val size = binding.tvMessageContent.textSize.toInt()
//                                    drawable.setBounds(0, 0, size, size)
//                                    return drawable
//                                }
//                            },
//                            null
//                        )
                    }

                    else -> {
                        binding.tvMessageContent.text = message.content
                        binding.layoutMessageInterrupt.isVisible = false
                    }
                }
            }
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MessageViewHolder {
            return if (viewType == 0) {
                MineMessageViewHolder(
                    CovMessageMineItemBinding.inflate(
                        LayoutInflater.from(parent.context),
                        parent,
                        false
                    )
                )
            } else {
                AgentMessageViewHolder(
                    CovMessageAgentItemBinding.inflate(
                        LayoutInflater.from(parent.context),
                        parent,
                        false
                    )
                )
            }
        }

        override fun onBindViewHolder(holder: MessageViewHolder, position: Int) {
            holder.bind(messages[position])
        }

        override fun getItemCount(): Int = messages.size

        override fun getItemViewType(position: Int): Int {
            return if (messages[position].isMe) 0 else 1
        }

        fun addMessage(message: Message) {
            messages.add(message)
            notifyItemInserted(messages.size - 1)
        }

        fun insertMessage(index: Int, message: Message) {
            messages.add(index, message)
            notifyItemInserted(index)
        }

        fun clearMessages() {
            val size = messages.size
            messages.clear()
            notifyItemRangeRemoved(0, size)
        }

        fun getAllMessage(): List<Message> {
            return messages
        }

        fun getMessageByTurnId(turnId: Long, isMe: Boolean): Message? {
            return messages.lastOrNull { it.turnId == turnId && it.isMe == isMe }
        }

        fun getMessageIndex(message: Message): Int {
            return messages.indexOfFirst {
                it.turnId == message.turnId && it.isMe == message.isMe
            }
        }

        fun updateMessage(message: Message) {
            val index = getMessageIndex(message)
            if (index != -1) {
                messages[index] = message
                notifyItemChanged(index)
            } else {
                addMessage(message)
            }
        }

        fun updateFromTitle(title: String) {
            fromTitle = title
            notifyDataSetChanged()
        }
    }

    override fun onSubtitleUpdated(subtitle: SubtitleMessage) {
        handleMessage(subtitle)
    }

    override fun onDebugLog(tag: String, msg: String) {
        CovLogger.d(tag, msg)
    }
}
