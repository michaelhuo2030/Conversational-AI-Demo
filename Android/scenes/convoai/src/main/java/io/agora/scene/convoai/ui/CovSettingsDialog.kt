package io.agora.scene.convoai.ui

import android.graphics.PorterDuff
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.util.dp
import io.agora.scene.convoai.databinding.CovSettingDialogBinding
import io.agora.scene.convoai.databinding.CovSettingOptionItemBinding
import io.agora.scene.convoai.manager.AgentConnectionState
import io.agora.scene.convoai.manager.CovAgentManager

class CovSettingsDialog : BaseSheetDialog<CovSettingDialogBinding>() {

    companion object {
        private const val TAG = "AgentSettingsSheetDialog"
    }

    private val optionsAdapter = OptionsAdapter()

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovSettingDialogBinding {
        return CovSettingDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding?.apply {
            setOnApplyWindowInsets(root)
            rcOptions.adapter = optionsAdapter
            rcOptions.layoutManager = LinearLayoutManager(context)
            clPreset.setOnClickListener {
                onClickPreset()
            }
            clLanguage.setOnClickListener {
                onClickLanguage()
            }
            vOptionsMask.setOnClickListener {
                onClickMaskView()
            }
            cbBhvs.isChecked = CovAgentManager.enableBHVS
            cbBhvs.setOnCheckedChangeListener { _: CompoundButton?, isChecked: Boolean ->
                CovAgentManager.enableBHVS = cbBhvs.isChecked
            }
            cbAiVad.isChecked = CovAgentManager.enableAiVad
            cbAiVad.setOnClickListener {
                CovAgentManager.enableAiVad = cbAiVad.isChecked
            }
            btnClose.setOnClickListener {
                dismiss()
            }
        }
        updateBaseSettings()
        updatePageEnable()
    }

    private fun updateBaseSettings() {
        binding?.apply {
            tvPresetDetail.text = CovAgentManager.getPreset()?.name
            tvLanguageDetail.text = CovAgentManager.language?.language_name
        }
    }

    private fun updatePageEnable() {
        val context = context ?: return
        if (CovAgentManager.connectionState == AgentConnectionState.CONNECTED) {
            binding?.apply {
                tvPresetDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                tvLanguageDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                ivPresetArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext4), PorterDuff.Mode.SRC_IN)
                ivLanguageArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext4), PorterDuff.Mode.SRC_IN)
                clPreset.isEnabled = false
                clLanguage.isEnabled = false
                cbBhvs.isEnabled = false
                cbAiVad.isEnabled = false
            }
        } else {
            binding?.apply {
                tvPresetDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                tvLanguageDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                ivPresetArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                ivLanguageArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext1), PorterDuff.Mode.SRC_IN)
                clPreset.isEnabled = true
                clLanguage.isEnabled = true
                cbBhvs.isEnabled = true
                cbAiVad.isEnabled = true
            }
        }
    }

    private fun onClickPreset() {
        val presets = CovAgentManager.getPresetList() ?: return
        binding?.apply {
            vOptionsMask.visibility = View.VISIBLE
            val itemLocation = IntArray(2)
            clPreset.getLocationOnScreen(itemLocation)
            val maskLocation = IntArray(2)
            vOptionsMask.getLocationOnScreen(maskLocation)
            val targetY = (itemLocation[1] - maskLocation[1]) + 30.dp
            cvOptions.x = vOptionsMask.width - 250.dp
            cvOptions.y = targetY
            val params = cvOptions.layoutParams
            params.height = (48.dp * presets.size).toInt()
            cvOptions.layoutParams = params
            // update options and select action
            optionsAdapter.updateOptions(
                presets.map { it.name }.toTypedArray(),
                presets.indexOf(CovAgentManager.getPreset())
            ) { index ->
                CovAgentManager.setPreset(presets[index])
                updateBaseSettings()
                binding?.apply {
                    vOptionsMask.visibility = View.INVISIBLE
                }
            }
        }
    }

    private fun onClickLanguage() {
        val languages = CovAgentManager.getLanguages() ?: return
        binding?.apply {
            vOptionsMask.visibility = View.VISIBLE
            val itemLocation = IntArray(2)
            clLanguage.getLocationOnScreen(itemLocation)
            val maskLocation = IntArray(2)
            vOptionsMask.getLocationOnScreen(maskLocation)
            val targetY = (itemLocation[1] - maskLocation[1]) + 30.dp
            cvOptions.x = vOptionsMask.width - 250.dp
            cvOptions.y = targetY
            val params = cvOptions.layoutParams
            params.height = (48.dp * languages.size).toInt()
            cvOptions.layoutParams = params
            // update options and select action
            optionsAdapter.updateOptions(
                languages.map { it.language_name }.toTypedArray(),
                languages.indexOf(CovAgentManager.language)
            ) { index ->
                CovAgentManager.language = languages[index]
                updateBaseSettings()
                binding?.apply {
                    vOptionsMask.visibility = View.INVISIBLE
                }
            }
        }
    }

    private fun onClickMaskView() {
        binding?.apply {
            vOptionsMask.visibility = View.INVISIBLE
        }
    }

    inner class OptionsAdapter : RecyclerView.Adapter<OptionsAdapter.ViewHolder>() {

        private var options: Array<String> = emptyArray()
        private var listener: ((Int) -> Unit)? = null
        private var selectedIndex: Int? = null

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            return ViewHolder(CovSettingOptionItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            holder.bind(options[position], (position == selectedIndex))
            holder.itemView.setOnClickListener {
                listener?.invoke(position)
            }
        }

        override fun getItemCount(): Int {
            return options.size
        }

        fun updateOptions(newOptions: Array<String>, selected: Int, newListener: (Int) -> Unit) {
            options = newOptions
            listener = newListener
            selectedIndex = selected
            notifyDataSetChanged()
        }

        inner class ViewHolder(private val binding: CovSettingOptionItemBinding) : RecyclerView.ViewHolder(binding.root) {
            fun bind(option: String, selected: Boolean) {
                binding.tvText.text = option
                binding.ivIcon.visibility = if (selected) View.VISIBLE else View.INVISIBLE
            }
        }
    }
}