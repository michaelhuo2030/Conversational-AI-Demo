package io.agora.scene.convoai.subRender.v1

interface ISelfMessageListView {
    fun onUpdateStreamContent(isMe: Boolean, turnId: Long, text: String, isFinal: Boolean = false)
}