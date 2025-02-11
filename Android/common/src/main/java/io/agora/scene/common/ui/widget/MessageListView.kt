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
import io.agora.scene.common.BuildConfig
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

    private val binding: MessageListViewBinding =
        MessageListViewBinding.inflate(LayoutInflater.from(context), this, true)
    private val messageAdapter: MessageAdapter = MessageAdapter()
    private var currentAgentMessage: Message? = null
    private var userDragged = false

    init {
        binding.rvMessages.layoutManager = LinearLayoutManager(context)
        binding.rvMessages.adapter = messageAdapter
        binding.rvMessages.itemAnimator = null
        binding.rvMessages.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrollStateChanged(recyclerView: RecyclerView, newState: Int) {
                super.onScrollStateChanged(recyclerView, newState)
                Log.d(TAG, "onScrollStateChanged: $newState")
                when (newState) {
                    RecyclerView.SCROLL_STATE_DRAGGING -> {
                        setUserDragged(true)
                    }
                }
            }

            override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
                Log.d(TAG, "onScrolled: $dy")
                if (userDragged && isScrolledToBottom()) {
                    setUserDragged(false)
                }
            }
        })
        binding.btnToBottom.setOnClickListener {
            setUserDragged(false)
            scrollToBottom()
        }
    }

    fun clearMessages() {
        currentAgentMessage = null
        messageAdapter.clearMessages()
    }

    fun getAllMessages(): List<Message> {
        return messageAdapter.getAllMessage()
    }

    fun updateAgentName(str: String) {
        messageAdapter.updateFromTitle(str)
    }

    fun updateStreamContent(isMe: Boolean, turnId: Double, text: String, isFinal: Boolean = false) {
        if (isMe) {
            handleUserMessage(turnId, text, isFinal)
        } else {
            handleAgentMessage(turnId, text, isFinal)
        }
    }

    private fun handleUserMessage(turnId: Double, text: String, isFinal: Boolean) {
        if (isFinal) {
            addMineMessage(turnId, text)
            scrollIfNeeded()
        }else{

        }
    }

    private fun handleAgentMessage(turnId: Double, text: String, isFinal: Boolean) {
        val isNewMessage = currentAgentMessage?.turnId != turnId
        
        if (isNewMessage) {
            startNewAgentMessage(turnId, text)
        } else {
            updateCurrentMessage(text)
        }
        
        if (isFinal) {
            completeCurrentMessage()
        } else {
            scrollIfNeeded()
        }
    }

    private fun scrollIfNeeded() {
        if (!userDragged) {
            checkAndScrollToBottom()
        }
    }

    private fun startNewAgentMessage(turnId: Double, content: String) {
        currentAgentMessage?.let {
            // 如果存在未完成的消息，先完成它
            completeCurrentMessage()
        }
        
        val message = Message(false, turnId, content, false)
        messageAdapter.addMessage(message)
        currentAgentMessage = message
    }

    private fun completeCurrentMessage() {
        currentAgentMessage?.let {
            if (!messageAdapter.containsMessage(it)) {
                messageAdapter.addMessage(it)
            }
            currentAgentMessage = null
        }
        scrollIfNeeded()
    }

    private fun addMineMessage(turnId: Double, text: String) {
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "addUserMessage: $text")
        }
        messageAdapter.addMessage(Message(true, turnId, text, true))
        if (!userDragged) {
            checkAndScrollToBottom()
        }
    }

    private fun updateCurrentMessage(content: String) {
        currentAgentMessage?.let {
            it.content = content
            messageAdapter.updateMessage(it)
        }
    }

    private fun setUserDragged(b: Boolean) {
        userDragged = b
        binding.cvToBottom.visibility = if (b) View.VISIBLE else View.INVISIBLE
    }

    private var scrollRunnable: Runnable? = null
    private val scrollDelay = 500L
    private var isScrollScheduled = false
    private fun checkAndScrollToBottom() {
        if (isScrollScheduled) return
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
            (binding.rvMessages.layoutManager as LinearLayoutManager).scrollToPositionWithOffset(
                lastPosition,
                -9999.dp.toInt()
            )
        }
    }

    private fun isScrolledToBottom(): Boolean {
        val scrollY = binding.rvMessages.scrollY
        val contentHeight = binding.rvMessages.getChildAt(0).height
        val scrollViewHeight = binding.rvMessages.height
        return scrollY >= (contentHeight - scrollViewHeight)
    }

    data class Message(
        val isMe: Boolean,
        val turnId: Double,
        var content: String,
        var isFinal: Boolean = false
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
                binding.tvMessageContent.text = message.content
                binding.tvMessageTitle.text = fromTitle
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

        fun clearMessages() {
            val size = messages.size
            messages.clear()
            notifyItemRangeRemoved(0, size)
        }

        fun getLastMessage(): Message? {
            return messages.lastOrNull()
        }

        fun getAllMessage(): List<Message> {
            return messages
        }

        fun containsMessage(message: Message): Boolean {
            return messages.contains(message)
        }

        fun notifyLastItemChanged() {
            notifyItemChanged(messages.size - 1)
        }

        fun updateMessage(message: Message) {
            val index = messages.indexOfLast { it.turnId == message.turnId }
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
}
