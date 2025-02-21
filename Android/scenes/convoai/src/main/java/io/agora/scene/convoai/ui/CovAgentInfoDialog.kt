package io.agora.scene.convoai.ui

import android.content.DialogInterface
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.rtc2.Constants
import io.agora.scene.common.debugMode.DebugConfigSettings
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.OnFastClickListener
import io.agora.scene.common.util.LogUploader
import io.agora.scene.common.util.copyToClipboard
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovInfoDialogBinding
import io.agora.scene.convoai.constant.CovAgentManager
import io.agora.scene.convoai.api.CovAgentApiManager
import io.agora.scene.convoai.constant.AgentConnectionState
import io.agora.scene.convoai.rtc.CovRtcManager

class CovAgentInfoDialog : BaseSheetDialog<CovInfoDialogBinding>() {
    private var onDismissCallback: (() -> Unit)? = null

    companion object {
        fun newInstance(onDismissCallback: () -> Unit): CovAgentInfoDialog {
            return CovAgentInfoDialog().apply {
                this.onDismissCallback = onDismissCallback
            }
        }
    }

    private var value: Int = -1
    private var connectionState: AgentConnectionState = AgentConnectionState.IDLE

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovInfoDialogBinding {
        return CovInfoDialogBinding.inflate(inflater, container, false)
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissCallback?.invoke()
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            mtvAgentId.setOnLongClickListener {
                copyToClipboard(mtvAgentId.text.toString())
                return@setOnLongClickListener true
            }
            mtvRoomId.setOnLongClickListener {
                copyToClipboard(mtvRoomId.text.toString())
                return@setOnLongClickListener true
            }
            mtvUidValue.setOnLongClickListener {
                copyToClipboard(mtvUidValue.text.toString())
                return@setOnLongClickListener true
            }
            btnClose.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    dismiss()
                }
            })
            tvUploader.setOnClickListener(object : OnFastClickListener() {
                override fun onClickJacking(view: View) {
                    CovRtcManager.generatePredumpFile()
                    tvUploader.postDelayed({
                        // 处理 agentId，如果包含冒号则只取冒号前的内容
                        val processedAgentId = CovAgentApiManager.agentId?.split(":")?.first()?:""
                        val zipFileName = "${processedAgentId}_${CovAgentManager.channelName}"
                        LogUploader.uploadLog(zipFileName,)
                    }, 2000L)

                }
            })
            updateView()
        }
    }

    fun updateConnectStatus(connectionState: AgentConnectionState) {
        this.connectionState = connectionState
        updateView()
    }

    private fun updateView() {
        val context = context ?: return
        binding?.apply {
            when (connectionState) {
                AgentConnectionState.IDLE, AgentConnectionState.ERROR -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = getString(R.string.cov_info_empty)
                    mtvRoomId.text = getString(R.string.cov_info_empty)
                    mtvUidValue.text = getString(R.string.cov_info_empty)
                }

                AgentConnectionState.CONNECTING -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }

                AgentConnectionState.CONNECTED -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))

                    mtvAgentStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))

                    mtvAgentId.text = CovAgentApiManager.agentId ?: getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }

                AgentConnectionState.CONNECTED_INTERRUPT -> {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentId.text = CovAgentApiManager.agentId ?: getString(R.string.cov_info_empty)
                    mtvRoomId.text = CovAgentManager.channelName
                    mtvUidValue.text = CovAgentManager.uid.toString()
                }
            }
            updateNetworkStatus(value)
        }
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
        val context = context ?: return
        binding?.apply {
            when (value) {
                -1 -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
                }

                Constants.QUALITY_VBAD, Constants.QUALITY_DOWN -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
                }

                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_yellow6))
                }

                else -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_good)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))
                }
            }
        }
    }

    private fun copyToClipboard(text: String) {
        context?.apply {
            copyToClipboard(text)
            ToastUtil.show(getString(R.string.cov_copy_succeed))
        }
    }

}