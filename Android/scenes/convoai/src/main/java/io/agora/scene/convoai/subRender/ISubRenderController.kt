package io.agora.scene.convoai.subRender

interface ISubRenderController {

    fun onStreamMessage(uid: Int, streamId: Int, data: ByteArray?)
}