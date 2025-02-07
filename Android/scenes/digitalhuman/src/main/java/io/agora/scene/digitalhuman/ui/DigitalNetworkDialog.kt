package io.agora.scene.digitalhuman.ui

import android.app.Dialog
import android.content.DialogInterface
import android.graphics.Color
import android.os.Bundle
import androidx.fragment.app.DialogFragment
import android.view.Gravity
import android.view.LayoutInflater
import android.view.Window
import android.view.WindowManager
import io.agora.scene.digitalhuman.R
import io.agora.scene.digitalhuman.databinding.DigitalNetworkDialogBinding
import io.agora.scene.digitalhuman.rtc.DigitalAgoraManager

class DigitalNetworkDialog : DialogFragment() {

    private var binding: DigitalNetworkDialogBinding? = null
    private var onDismissListener: (() -> Unit)? = null

    private var value: Int = 0

    fun setOnDismissListener(listener: () -> Unit) {
        this.onDismissListener = listener
    }

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        binding = DigitalNetworkDialogBinding.inflate(LayoutInflater.from(context))
        val dialog = Dialog(requireContext(), theme)
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
        dialog.setCancelable(true)

        binding?.let { binding ->
            dialog.setContentView(binding.root)
            binding.root.setOnClickListener {
                dialog.dismiss()
            }
            if (!DigitalAgoraManager.agentStarted) {
                binding.mtvNetworkStatus.text = getString(R.string
                    .digital_info_your_network_disconnected)
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
                1, 2 -> {
                    mtvNetworkStatus.text = getString(R.string.digital_info_your_network_good)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#36B37E"))
                }
                3, 4 -> {
                    mtvNetworkStatus.text = getString(R.string.digital_info_your_network_medium)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FFAB00"))
                }
                else -> {
                    mtvNetworkStatus.text = getString(R.string.digital_info_your_network_poor)
                    mtvNetworkStatus.setTextColor(Color.parseColor("#FF414D"))
                }
            }
        }
    }
}