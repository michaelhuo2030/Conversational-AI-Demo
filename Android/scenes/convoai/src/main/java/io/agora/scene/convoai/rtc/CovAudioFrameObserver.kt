package io.agora.scene.convoai.rtc

import io.agora.rtc2.Constants
import io.agora.rtc2.IAudioFrameObserver
import io.agora.rtc2.audio.AudioParams
import java.nio.ByteBuffer

open class CovAudioFrameObserver : IAudioFrameObserver {

    private val TAG = "CovAudioFrameObserver"
    override fun onRecordAudioFrame(
        channel: String, audioFrameType: Int,
        samples: Int, bytesPerSample: Int,
        channels: Int, samplesPerSec: Int,
        byteBuffer: ByteBuffer, renderTimeMs: Long, bufferLength: Int
    ): Boolean {
        return false
    }


    override fun onPlaybackAudioFrame(
        channel: String, audioFrameType: Int,
        samples: Int, bytesPerSample: Int,
        channels: Int, samplesPerSec: Int,
        byteBuffer: ByteBuffer, renderTimeMs: Long,
        bufferLength: Int
    ): Boolean {
        return false
    }

    override fun onMixedAudioFrame(
        channel: String, audioFrameType: Int,
        samples: Int, bytesPerSample: Int, channels: Int,
        samplesPerSec: Int, byteBuffer: ByteBuffer,
        renderTimeMs: Long, bufferLength: Int
    ): Boolean {
        return false
    }

    override fun onEarMonitoringAudioFrame(
        type: Int, samplesPerChannel: Int, bytesPerSample: Int,
        channels: Int, samplesPerSec: Int,
        buffer: ByteBuffer, renderTimeMs: Long, avsyncType: Int
    ): Boolean {
        return false
    }

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
        return false
    }

    override fun getObservedAudioFramePosition(): Int {
        return Constants.POSITION_BEFORE_MIXING
    }

    override fun getRecordAudioParams(): AudioParams? {
        return null
    }

    override fun getPlaybackAudioParams(): AudioParams? {
        return null
    }

    override fun getMixedAudioParams(): AudioParams? {
        return null
    }

    override fun getEarMonitoringAudioParams(): AudioParams? {
        return null
    }
}