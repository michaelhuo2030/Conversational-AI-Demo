package io.agora.scene.digitalhuman.ui

import android.app.Dialog
import android.graphics.Color
import android.os.Bundle
import androidx.fragment.app.DialogFragment
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.Window
import android.view.WindowManager
import io.agora.scene.digitalhuman.R
import io.agora.scene.digitalhuman.databinding.DigitalAgentInfoDialogBinding
import io.agora.scene.digitalhuman.rtc.DigitalAgoraManager

class DigitalAgentInfoDialog : DialogFragment() {

    var isConnected = false

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        val binding = DigitalAgentInfoDialogBinding.inflate(LayoutInflater.from(context))

        val dialog = Dialog(requireContext(), theme)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        dialog.setCancelable(true)
        dialog.setContentView(binding.root)

        val window = dialog.window
        window?.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT)
        window?.setGravity(Gravity.TOP)
        window?.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window?.setBackgroundDrawableResource(android.R.color.transparent)

        if (DigitalAgoraManager.agentStarted) {
            binding.mtvRoomStatus.visibility = View.VISIBLE
            binding.mtvAgentStatus.visibility = View.VISIBLE
            if (isConnected) {
                binding.mtvRoomStatus.text = getString(R.string.digital_info_agent_connected)
                binding.mtvRoomStatus.setTextColor(Color.parseColor("#36B37E"))

                binding.mtvAgentStatus.text = getString(R.string.digital_info_agent_connected)
                binding.mtvAgentStatus.setTextColor(Color.parseColor("#36B37E"))
            } else {
                binding.mtvRoomStatus.text = getString(R.string.digital_info_your_network_disconnected)
                binding.mtvRoomStatus.setTextColor(Color.parseColor("#FF414D"))

                binding.mtvAgentStatus.text = getString(R.string.digital_info_your_network_disconnected)
                binding.mtvAgentStatus.setTextColor(Color.parseColor("#FF414D"))
            }
            binding.mtvRoomId.text = DigitalAgoraManager.channelName
            binding.mtvUidValue.text = DigitalAgoraManager.uid.toString()
        } else {
            binding.mtvRoomId.visibility = View.INVISIBLE
            binding.mtvUidValue.visibility = View.INVISIBLE
            binding.mtvRoomStatus.visibility = View.INVISIBLE
            binding.mtvAgentStatus.visibility = View.INVISIBLE
        }

        binding.root.setOnClickListener {
            dialog.dismiss()
        }
        return dialog
    }
}