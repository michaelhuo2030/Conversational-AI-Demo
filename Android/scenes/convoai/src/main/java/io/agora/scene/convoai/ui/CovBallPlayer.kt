package io.agora.scene.convoai.ui

import android.content.Context
import android.graphics.SurfaceTexture
import android.media.MediaPlayer
import android.view.Surface
import android.view.TextureView
import android.widget.FrameLayout

class CovBallPlayer(private val context: Context) {
    private var mediaPlayer: MediaPlayer? = null
    
    interface SpeedCallback {
        fun onSpeedChanged(speed: Float)
    }
    
    var speedCallback: SpeedCallback? = null

    fun create(surfaceView: TextureView) {
        mediaPlayer = MediaPlayer()

        surfaceView.surfaceTextureListener = object : TextureView.SurfaceTextureListener {
            override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
                mediaPlayer?.setSurface(Surface(surface))
                playVideo()
            }

            override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {}

            override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
                return true
            }

            override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}
        }
    }

    private fun playVideo() {
        try {
            mediaPlayer?.apply {
                reset()
                setDataSource(context.filesDir.absolutePath + "/ball_small_video.mov")
                setOnPreparedListener { mp ->
                    mp.isLooping = true
                    mp.start()
                    setSpeed(0.7f)
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun setSpeed(speed: Float) {
        try {
            val params = mediaPlayer?.playbackParams ?: return
            params.setSpeed(speed)
            mediaPlayer?.playbackParams = params
            speedCallback?.onSpeedChanged(speed)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun release() {
        mediaPlayer?.apply {
            stop()
            release()
        }
        mediaPlayer = null
        speedCallback = null
    }
} 