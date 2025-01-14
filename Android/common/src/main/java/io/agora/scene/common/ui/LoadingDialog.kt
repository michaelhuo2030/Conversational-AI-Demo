package io.agora.scene.common.ui

import android.app.Dialog
import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import io.agora.scene.common.databinding.LoadingDialogBinding

class LoadingDialog(context: Context) : Dialog(context) {

    private val binding: LoadingDialogBinding by lazy {
        LoadingDialogBinding.inflate(LayoutInflater.from(context))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(binding.root)
        
        window?.setBackgroundDrawableResource(android.R.color.transparent)
        setCancelable(false)
    }

    fun setMessage(message: String) {
        binding.loadingText.text = message
    }
}