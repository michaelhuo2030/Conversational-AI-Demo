package io.agora.scene.convoai.ui

import android.app.Dialog
import android.content.DialogInterface
import android.graphics.Color
import android.os.Bundle
import androidx.fragment.app.DialogFragment
import android.view.Gravity
import android.view.LayoutInflater
import android.view.Window
import android.view.WindowManager
import io.agora.rtc2.Constants
import io.agora.scene.convoai.databinding.CovNetworkDialogBinding
import io.agora.scene.convoai.rtc.CovAgoraManager

class CovNetworkDialog : DialogFragment() {

    private var binding: CovNetworkDialogBinding? = null
    private var onDismissListener: (() -> Unit)? = null

    private var value: Int = 0

    fun setOnDismissListener(listener: () -> Unit) {
        this.onDismissListener = listener
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        binding = CovNetworkDialogBinding.inflate(LayoutInflater.from(context))
        val dialog = Dialog(requireContext(), theme)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        dialog.setCancelable(true)

        binding?.let { binding ->
            dialog.setContentView(binding.root)
            binding.root.setOnClickListener {
                dialog.dismiss()
            }
            if (!CovAgoraManager.agentStarted) {
                binding.mtvNetworkStatus.text = getString(io.agora.scene.common.R.string
                    .cov_info_your_network_disconnected)
                binding.mtvNetworkStatus.setTextColor(Color.parseColor("#FF414D"))
            } else {
                updateNetworkStatus(value)
            }
        }
        val window = dialog.window
        window?.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.WRAP_CONTENT)
        window?.setGravity(Gravity.TOP)
        window?.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window?.setBackgroundDrawableResource(android.R.color.transparent)
        return dialog
    }

    override fun onDismiss(dialog: DialogInterface) {
        super.onDismiss(dialog)
        onDismissListener?.invoke()
    }

    fun updateNetworkStatus(value: Int) {
        this.value = value
        binding?.apply {
            when (value) {
                Constants.QUALITY_EXCELLENT, Constants.QUALITY_GOOD -> {
                    mtvNetworkStatus.text = getString(io.agora.scene.common.R.string.cov_info_your_network_good)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#36B37E"))
                }
                Constants.QUALITY_POOR, Constants.QUALITY_BAD -> {
                    mtvNetworkStatus.text = getString(io.agora.scene.common.R.string.cov_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FFAB00"))
                }
                else -> {
                    mtvNetworkStatus.text = getString(io.agora.scene.common.R.string.cov_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FF414D"))
                }
            }
        }
    }
}