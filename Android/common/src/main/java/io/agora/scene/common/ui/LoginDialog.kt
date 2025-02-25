package io.agora.scene.common.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.TranslateAnimation
import android.widget.CompoundButton
import io.agora.scene.common.databinding.CommonLoginDialogBinding

interface LoginDialogCallback {
    fun onDialogDismiss() = Unit
    fun onClickStartSSO() = Unit
    fun onTermsOfServices() = Unit
    fun onPrivacyPolicy() = Unit
}

class LoginDialog constructor() : BaseSheetDialog<CommonLoginDialogBinding>() {

    var onLoginDialogCallback: LoginDialogCallback? = null

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CommonLoginDialogBinding {
        return CommonLoginDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            btnClose.setOnClickListener {
                dismiss()
            }
            btnLoginSSO.setOnClickListener { v: View? ->
                if (cbTerms.isChecked) {
                    onLoginDialogCallback?.onClickStartSSO()
                    dismiss()
                } else {
                    animCheckTip()
                }
            }
            cbTerms.setOnCheckedChangeListener { buttonView: CompoundButton?, isChecked: Boolean ->
                if (tvCheckTips.visibility == View.VISIBLE) {
                    tvCheckTips.visibility = View.INVISIBLE
                }
            }
            tvAccept.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    cbTerms.isChecked = !cbTerms.isChecked
                }
            })
            tvTermsOfServices.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onLoginDialogCallback?.onTermsOfServices()
                }
            })
            tvPrivacyPolicy.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    onLoginDialogCallback?.onPrivacyPolicy()
                }
            })
        }
    }

    override fun disableDragging(): Boolean {
        return true
    }

    override fun dismiss() {
        super.dismiss()
        onLoginDialogCallback?.onDialogDismiss()
    }

    private fun animCheckTip() {
        binding?.apply {
            tvCheckTips.visibility = View.VISIBLE
            val animation = TranslateAnimation(
                -10f, 10f, 0f, 0f
            )
            animation.duration = 60
            animation.repeatCount = 4
            animation.repeatMode = Animation.REVERSE
            tvCheckTips.clearAnimation()
            tvCheckTips.startAnimation(animation)
        }
    }
}