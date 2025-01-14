package io.agora.scene.common.ui

import android.os.Bundle
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
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

    open fun onHandleOnBackPressed(){
        finish()
    }

    abstract fun getViewBinding(): VB

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        _binding = getViewBinding()
        if (_binding?.root == null){
            finish()
            return
        }
        setContentView(_binding!!.root)
        onBackPressedDispatcher.addCallback(this, onBackPressedCallback)
        initView()
    }

    override fun finish() {
        onBackPressedCallback.remove()
        super.finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        _binding = null
    }

    /**
     * 初始化视图
     */
    protected abstract fun initView()

    fun setOnApplyWindowInsetsListener(view: View) {
        ViewCompat.setOnApplyWindowInsetsListener(view) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }
    }
} 