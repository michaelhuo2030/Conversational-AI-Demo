package io.agora.scene.common.ui

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.activity.OnBackPressedCallback
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.viewbinding.ViewBinding

abstract class BaseActivity<VB : ViewBinding> : AppCompatActivity() {

    private var _binding: VB? = null
    protected val mBinding: VB? get() = _binding

    private val onBackPressedCallback = object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
            onHandleOnBackPressed()
        }
    }

    open fun onHandleOnBackPressed() {
        finish()
    }

    abstract fun getViewBinding(): VB

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = isLightStatusBars()
        }
        _binding = getViewBinding()
        if (_binding?.root == null) {
            finish()
            return
        }
        setContentView(_binding!!.root)
        onBackPressedDispatcher.addCallback(this, onBackPressedCallback)
        if (isFullScreen()) {
            setupFullScreen()
        }
        initView()
    }

    open fun isLightStatusBars(): Boolean = false

    open fun isFullScreen(): Boolean = true

    override fun finish() {
        onBackPressedCallback.remove()
        super.finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        _binding = null
    }

    /**
     * Initialize the view.
     */
    protected abstract fun initView()

    fun setOnApplyWindowInsetsListener(view: View) {
        ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPaddingRelative(
                systemBars.left + v.paddingLeft,
                systemBars.top,
                systemBars.right + v.paddingRight,
                systemBars.bottom
            )
            insets
        }
    }

    private fun setupFullScreen() {
        window.apply {
            statusBarColor = Color.TRANSPARENT
            navigationBarColor = Color.TRANSPARENT

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // For Android 11+ use WindowInsetsController
                decorView.windowInsetsController?.apply {
                    hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                    systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                // For Android 10 and below, use the deprecated systemUiVisibility
                @Suppress("DEPRECATION")
                decorView.systemUiVisibility =
                    (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
            }
        }
    }
}