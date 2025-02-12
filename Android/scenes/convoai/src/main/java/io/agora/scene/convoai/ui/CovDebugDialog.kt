package io.agora.scene.convoai.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.rtc2.RtcEngine
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovDebugDialogBinding
import io.agora.scene.convoai.manager.CovServerManager

class CovDebugDialog constructor(private val settingBean: DebugSettingBean) :
    BaseSheetDialog<CovDebugDialogBinding>() {

    class DebugSettingBean(callback: Callback) {
        private val mCallback: Callback = callback


        /**
         * Is audio dump enabled boolean.
         *
         * @return the boolean
         */
        var isAudioDumpEnabled: Boolean = false
            private set(value) {
                if (field != value) {
                    field = value
                    mCallback.onAudioDumpEnable(value)
                }
            }


        /**
         * Enable audio dump.
         *
         * @param enable the enable
         */
        fun enableAudioDump(enable: Boolean) {
            this.isAudioDumpEnabled = enable
        }

        fun enableDebug(enable: Boolean) {
            ServerConfig.isDebug = enable
            mCallback.onDebugEnable(enable)
        }

        fun onClickCopy() {
            mCallback.onClickCopy()
        }
    }

    interface Callback {
        /**
         * On audio dump enable.
         *
         * @param enable the enable
         */
        fun onAudioDumpEnable(enable: Boolean)

        fun onDebugEnable(enable: Boolean)

        fun onClickCopy()
    }

    private var value: Int = 0

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovDebugDialogBinding {
        return CovDebugDialogBinding.inflate(inflater, container, false)
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            mtvRtcVersion.text = RtcEngine.getSdkVersion()
            mtvServerHost.text = CovServerManager.currentHost ?: ""
            cbAudioDump.setChecked(settingBean.isAudioDumpEnabled)
            cbAudioDump.setOnCheckedChangeListener { buttonView, isChecked ->
                if (buttonView.isPressed) {
                    settingBean.enableAudioDump(isChecked)
                }
            }
            btnClose.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    dismiss()
                }
            })
            layoutCloseDebug.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    settingBean.enableDebug(false)
                    dismiss()
                }
            })
            btnCopy.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    settingBean.onClickCopy()
                }
            })
        }
    }
}