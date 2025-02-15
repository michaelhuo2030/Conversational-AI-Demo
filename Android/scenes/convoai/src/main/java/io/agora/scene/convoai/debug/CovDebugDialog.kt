package io.agora.scene.convoai.debug

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.rtc2.RtcEngine
import io.agora.scene.common.constant.ServerConfig
import io.agora.scene.common.constant.ServerEnv
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovDebugDialogBinding
import io.agora.scene.convoai.api.CovAgentApiManager

object DebugSettings {
    val debugConfig = DebugSettingConfig()
}

data class DebugSettingConfig constructor(
    var isAudioDumpEnabled: Boolean = false
)

class CovDebugDialog constructor(val mCallback: Callback) :
    BaseSheetDialog<CovDebugDialogBinding>() {

    interface Callback {
        /**
         * On audio dump enable.
         *
         * @param enable the enable
         */
        fun onAudioDumpEnable(enable: Boolean) {}

        fun onDebugEnable(enable: Boolean) {}

        fun onSwitchEnv(env: Int) {}

        fun onClickCopy() {}
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

    private var tempEnv = ServerConfig.toolboxEnv

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            mtvRtcVersion.text = RtcEngine.getSdkVersion()
            mtvServerHost.text = CovAgentApiManager.currentHost ?: ""
            cbAudioDump.setChecked(DebugSettings.debugConfig.isAudioDumpEnabled)
            cbAudioDump.setOnCheckedChangeListener { buttonView, isChecked ->
                if (buttonView.isPressed) {
                    DebugSettings.debugConfig.isAudioDumpEnabled = isChecked
                    mCallback.onAudioDumpEnable(isChecked)
                }
            }
            btnClose.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    dismiss()
                }
            })
            layoutCloseDebug.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    ServerConfig.isDebug = false
                    mCallback.onDebugEnable(false)
                    dismiss()
                }
            })
            btnCopy.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    mCallback.onClickCopy()
                }
            })

            when (ServerConfig.toolboxEnv) {
                ServerEnv.STAGING -> {
                    rgSwitchEnv.check(R.id.rbEnvStaging)
                }
                ServerEnv.DEV -> {
                    rgSwitchEnv.check(R.id.rbEnvDev)
                }
                else -> {
                    rgSwitchEnv.check(R.id.rbEnvStaging)
                }
            }
            rgSwitchEnv.setOnCheckedChangeListener { group, checkedId ->
                when (checkedId) {
                    R.id.rbEnvStaging -> {
                        tempEnv = ServerEnv.STAGING
                    }

                    R.id.rbEnvDev -> {
                        tempEnv = ServerEnv.DEV
                    }

                    else -> {
                        tempEnv = ServerEnv.STAGING
                    }
                }
            }
            tvSwitch.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    if (ServerConfig.toolboxEnv == tempEnv) {
                        return
                    }
                    ServerConfig.toolboxEnv = tempEnv
                    mCallback.onSwitchEnv(tempEnv)
                    dismiss()
                    ToastUtil.show(
                        getString(
                            io.agora.scene.common.R.string.common_debug_current_server,
                            ServerConfig.toolBoxUrl
                        )
                    )
                }
            })
        }
    }
}