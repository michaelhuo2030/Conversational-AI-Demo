package io.agora.scene.convoai.ui

import android.graphics.Color
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

    var isConnected = false

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
                mtvNetworkStatus.setTextColor(Color.parseColor("#FF414D"))
            } else {
                updateNetworkStatus(value)
            }

            if (CovAgoraManager.agentStarted) {
                mtvRoomStatus.visibility = View.VISIBLE
                mtvAgentStatus.visibility = View.VISIBLE
                if (isConnected) {
                    mtvRoomStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvRoomStatus.setTextColor(Color.parseColor("#36B37E"))

                    mtvAgentStatus.text = getString(R.string.cov_info_agent_connected)
                    mtvAgentStatus.setTextColor(Color.parseColor("#36B37E"))
                } else {
                    mtvRoomStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvRoomStatus.setTextColor(Color.parseColor("#FF414D"))

                    mtvAgentStatus.text = getString(R.string.cov_info_your_network_disconnected)
                    mtvAgentStatus.setTextColor(Color.parseColor("#FF414D"))
                }
                mtvRoomId.text = CovAgoraManager.channelName
                mtvUidValue.text = CovAgoraManager.uid.toString()
            } else {
                mtvRoomId.visibility = View.INVISIBLE
                mtvUidValue.visibility = View.INVISIBLE
                mtvRoomStatus.visibility = View.INVISIBLE
                mtvAgentStatus.visibility = View.INVISIBLE
            }
        }
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
        binding?.apply {
            when (value) {
                Constants.QUALITY_EXCELLENT, Constants.QUALITY_GOOD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_good)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#36B37E"))
                }
                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FFAB00"))
                }
                else -> {
                    mtvNetworkStatus.text = getString(R.string.cov_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FF414D"))
                }
            }
        }
    }
}