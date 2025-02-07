package io.agora.scene.convoai.ui

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.CompoundButton
import android.widget.ImageView
import android.widget.TextView
import io.agora.scene.common.ui.BaseSheetDialog
import io.agora.scene.common.ui.LoadingDialog
import io.agora.scene.common.util.dp
import io.agora.scene.common.util.toast.ToastUtil
import io.agora.scene.convoai.R
import io.agora.scene.convoai.databinding.CovSettingDialogBinding
import io.agora.scene.convoai.http.ConvAIManager
import io.agora.scene.convoai.rtc.AgentLLMType
import io.agora.scene.convoai.rtc.AgentLanguageType
import io.agora.scene.convoai.rtc.AgentMicrophoneType
import io.agora.scene.convoai.rtc.AgentPresetType
import io.agora.scene.convoai.rtc.AgentSpeakerType
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
    }

    private fun uploadNewSetting(voice: AgentVoiceType? = null, llm: AgentLLMType? = null, language: AgentLanguageType? = null) {
        val context = context?:return
        if (CovAgoraManager.agentStarted) {
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
                    ToastUtil.show(io.agora.scene.common.R.string.cov_setting_network_error)
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
            if (CovAgoraManager.agentStarted) {
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
            tvPreset.text = CovAgoraManager.currentPresetType().value
            tvLanguage.text = CovAgoraManager.languageType.value
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
        }
    }

    private fun onClickMaskView() {
        binding?.apply {
            vOptionsMask.visibility = View.GONE
        }
    }
}