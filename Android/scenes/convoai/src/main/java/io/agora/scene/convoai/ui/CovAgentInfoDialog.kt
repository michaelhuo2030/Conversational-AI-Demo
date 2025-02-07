package io.agora.scene.convoai.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import io.agora.rtc2.Constants
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovInfoDialogBinding
import io.agora.scene.convoai.rtc.CovAgoraManager

class CovAgentInfoDialog : BaseSheetDialog<CovInfoDialogBinding>() {

    private var value: Int = 0

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovInfoDialogBinding {
        return CovInfoDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            if (!CovAgoraManager.agentStarted) {
                mtvNetworkStatus.text = getString(R.string.cov_info_your_network_disconnected)
                context?.let {
                    mtvNetworkStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))
                }
            } else {
                updateNetworkStatus(value)
            }
            if (CovAgoraManager.agentStarted) {
                mtvRoomId.visibility = View.VISIBLE
                mtvUidValue.visibility = View.VISIBLE
                context?.let {
                    mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_green6))

                    mtvAgentStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_green6))
                }
                mtvRoomId.text = CovAgoraManager.channelName
                mtvUidValue.text = CovAgoraManager.uid.toString()
            } else {
                context?.let {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(it.getColor(io.agora.scene.common.R.color.ai_red6))
                }
                mtvRoomId.visibility = View.INVISIBLE
                mtvUidValue.visibility = View.INVISIBLE
            }
        }
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
        val context = context ?: return
        binding?.apply {
            when (value) {
                Constants.QUALITY_EXCELLENT, Constants.QUALITY_GOOD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_good)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_green6))
                }
                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_yellow6))
                }
                else -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_red6))
                }
            }
        }
    }
}