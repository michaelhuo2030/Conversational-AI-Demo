package io.agora.scene.convoai.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CompoundButton
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovSettingDialogBinding
import io.agora.scene.convoai.databinding.CovSettingOptionItemBinding
import io.agora.scene.convoai.http.ConvAIManager
import io.agora.scene.convoai.rtc.AgentConnectionState
import io.agora.scene.convoai.rtc.AgentLLMType
import io.agora.scene.convoai.rtc.AgentLanguageType
import io.agora.scene.convoai.rtc.AgentPresetType
import io.agora.scene.convoai.rtc.AgentVoiceType
import io.agora.scene.convoai.rtc.CovAgoraManager

class CovSettingsDialog : BaseSheetDialog<CovSettingDialogBinding>() {

    companion object {
        private const val TAG = "AgentSettingsSheetDialog"
    }

    private val presets = AgentPresetType.options
    private var voices = AgentVoiceType.options
    private var LLMs = AgentLLMType.values()
    private var languages = AgentLanguageType.values()

    private val optionsAdapter = OptionsAdapter()

    override fun getViewBinding(
        inflater: LayoutInflater,
        container: ViewGroup?
    ): CovSettingDialogBinding {
        return CovSettingDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        updateOptionsByPresets()
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
            cbNoiseCancellation.isChecked = CovAgoraManager.getDenoiseStatus()
            cbNoiseCancellation.setOnCheckedChangeListener { _: CompoundButton?, isChecked: Boolean ->
                CovAgoraManager.updateDenoise(isChecked)
            }
            cbAiVad.isChecked = CovAgoraManager.isAiVad
            cbAiVad.setOnClickListener {
                CovAgoraManager.isAiVad = cbAiVad.isChecked
                CovAgoraManager.isForceThreshold = cbAiVad.isChecked
                updateAiVadSettings()
            }
            cbForceResponse.isChecked = CovAgoraManager.isForceThreshold
            cbForceResponse.setOnClickListener {
                CovAgoraManager.isForceThreshold = cbForceResponse.isChecked
                updateAiVadSettings()
            }
            btnClose.setOnClickListener {
                dismiss()
            }
        }
        updateBaseSettings()
        updateAiVadSettings()
        updatePageEnable()
    }

    private fun uploadNewSetting(voice: AgentVoiceType? = null, llm: AgentLLMType? = null, language: AgentLanguageType? = null) {
        val context = context?:return
        if (CovAgoraManager.connectionState == AgentConnectionState.CONNECTED) {
            val loadingDialog = LoadingDialog(context).apply {
                show()
            }
            ConvAIManager.updateAgent(voice?.value) { success ->
                loadingDialog.dismiss()
                if (success) {
                    voice?.let {CovAgoraManager.voiceType = it}
                    llm?.let { CovAgoraManager.llmType = llm }
                    language?.let { CovAgoraManager.languageType = language }
                    updateAiVadSettings()
                } else {
                    updateAiVadSettings()
                    ToastUtil.show(R.string.cov_setting_network_error)
                }
            }
        } else {
            voice?.let {CovAgoraManager.voiceType = it}
            llm?.let { CovAgoraManager.llmType = llm }
            language?.let { CovAgoraManager.languageType = language }
            updateAiVadSettings()
        }
    }

    private fun updateAiVadSettings() {
        binding?.apply {
            // ai vad
            if (CovAgoraManager.connectionState == AgentConnectionState.CONNECTED) {
                clAiVad.visibility = View.GONE
                clForceResponse.visibility = View.GONE
            } else {
                clAiVad.visibility = View.VISIBLE
                cbAiVad.isChecked = CovAgoraManager.isAiVad
                cbForceResponse.isChecked = CovAgoraManager.isForceThreshold
                if (CovAgoraManager.isAiVad) {
                    clForceResponse.visibility = View.VISIBLE
                } else {
                    clForceResponse.visibility = View.GONE
                }
            }
        }
    }

    private fun updateBaseSettings() {
        binding?.apply {
            tvPresetDetail.text = CovAgoraManager.currentPresetType().value
            tvLanguageDetail.text = CovAgoraManager.languageType.value
        }
    }

    private fun updateOptionsByPresets() {
        when (CovAgoraManager.currentPresetType()) {
            AgentPresetType.VERSION1 -> {
                voices = arrayOf(AgentVoiceType.AVA_MULTILINGUAL)
                LLMs = arrayOf(AgentLLMType.OPEN_AI)
                languages = arrayOf(AgentLanguageType.EN)
            }
            AgentPresetType.XIAO_AI -> {
                voices = arrayOf(AgentVoiceType.FEMALE_SHAONV)
                LLMs = arrayOf(AgentLLMType.MINIMAX)
                languages = arrayOf(AgentLanguageType.CN)
            }
            AgentPresetType.TBD -> {
                voices = arrayOf(AgentVoiceType.TBD)
                LLMs = arrayOf(AgentLLMType.MINIMAX, AgentLLMType.TONG_YI)
                languages = arrayOf(AgentLanguageType.CN, AgentLanguageType.EN)
            }
            AgentPresetType.DEFAULT -> {
                voices = arrayOf(AgentVoiceType.ANDREW, AgentVoiceType.EMMA, AgentVoiceType.DUSTIN, AgentVoiceType.SERENA)
                LLMs = arrayOf(AgentLLMType.OPEN_AI)
                languages = arrayOf(AgentLanguageType.EN)
            }
            AgentPresetType.AMY -> {
                voices = arrayOf(AgentVoiceType.EMMA)
                LLMs = arrayOf(AgentLLMType.OPEN_AI)
                languages = arrayOf(AgentLanguageType.EN)
            }
        }
    }

    private fun updatePageEnable() {
        val context = context ?: return
        if (CovAgoraManager.connectionState == AgentConnectionState.CONNECTED) {
            binding?.apply {
                tvPresetDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                tvLanguageDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                ivPresetArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                ivLanguageArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext4))
                clPreset.isEnabled = false
                clLanguage.isEnabled = false
                cbNoiseCancellation.isEnabled = false
                cbAiVad.isEnabled = false
                cbForceResponse.isEnabled = false
            }
        } else {
            binding?.apply {
                tvPresetDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                tvLanguageDetail.setTextColor(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                ivPresetArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                ivLanguageArrow.setColorFilter(context.getColor(io.agora.scene.common.R.color.ai_icontext1))
                clPreset.isEnabled = true
                clLanguage.isEnabled = true
                cbNoiseCancellation.isEnabled = true
                cbAiVad.isEnabled = true
                cbForceResponse.isEnabled = true
            }
        }
    }

    private fun onClickPreset() {
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
            optionsAdapter.updateOptions(presets.map { it.value }.toTypedArray()) { index ->
                CovAgoraManager.updatePreset(presets[index])
            }
        }
    }

    private fun onClickLanguage() {
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
            optionsAdapter.updateOptions(languages.map { it.value }.toTypedArray()) { index ->

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

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            return ViewHolder(CovSettingOptionItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            holder.bind(options[position])
            holder.itemView.setOnClickListener {
                listener?.invoke(position)
            }
        }

        override fun getItemCount(): Int {
            return options.size
        }

        fun updateOptions(newOptions: Array<String>, newListener: (Int) -> Unit) {
            options = newOptions
            listener = newListener
            notifyDataSetChanged()
        }

        inner class ViewHolder(private val binding: CovSettingOptionItemBinding) : RecyclerView.ViewHolder(binding.root) {
            fun bind(option: String) {
                binding.tvText.text = option
            }
        }
    }
}