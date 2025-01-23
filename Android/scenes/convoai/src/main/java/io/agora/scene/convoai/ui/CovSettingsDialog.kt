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

    private lateinit var voiceAdapter: CustomArrayAdapter
    private lateinit var modelAdapter: CustomArrayAdapter
    private lateinit var languageAdapter: CustomArrayAdapter
    private lateinit var microphoneAdapter: CustomArrayAdapter
    private lateinit var speakerAdapter: CustomArrayAdapter
    private lateinit var presetAdapter: CustomArrayAdapter

    private val presets = AgentPresetType.options
    private var voices = AgentVoiceType.options
    private var LLMs = AgentLLMType.values()
    private var languages = AgentLanguageType.values()
    private val microphones = AgentMicrophoneType.values()
    private val speakers = AgentSpeakerType.values()

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
            cbNoiseCancellation.isChecked = CovAgoraManager.currentDenoiseStatus()
            cbNoiseCancellation.setOnCheckedChangeListener { _: CompoundButton?, isChecked: Boolean ->
                CovAgoraManager.updateDenoise(isChecked)
            }
            btnClose.setOnClickListener {
                dismiss()
            }
        }
        setupVoiceSpinner()
        setupModelSpinner()
        setupLanguageSpinner()
        setupMicrophoneSpinner()
        setupSpeakerSpinner()
        setupPresetSpinner()
        updateSpinners()
    }

    private fun uploadNewSetting(voice: AgentVoiceType, llm: AgentLLMType? = null, language: AgentLanguageType? = null) {
        val context = context?:return
        if (CovAgoraManager.agentStarted) {
            val loadingDialog = LoadingDialog(context).apply {
                show()
            }
            ConvAIManager.updateAgent(voice.value) { success ->
                loadingDialog.dismiss()
                if (success) {
                    CovAgoraManager.voiceType = voice
                    llm?.let { CovAgoraManager.llmType = llm }
                    language?.let { CovAgoraManager.languageType = language }
                    updateSpinners()
                } else {
                    updateSpinners()
                    ToastUtil.show(io.agora.scene.common.R.string.cov_setting_network_error)
                }
            }
        } else {
            CovAgoraManager.voiceType = voice
            llm?.let { CovAgoraManager.llmType = llm }
            language?.let { CovAgoraManager.languageType = language }
            updateSpinners()
        }
    }

    private fun updateSpinners() {
        binding?.apply {
            voiceAdapter.updateItems(voices.map { it.display }.toList())
            val defaultVoice = CovAgoraManager.voiceType
            val voicePosition = voices.indexOf(defaultVoice)
            if (voicePosition != -1) {
                voiceAdapter.updateSelectedPosition(voicePosition)
                spVoice.setSelection(voicePosition)
            }

            modelAdapter.updateItems(LLMs.map { it.display }.toList())
            val defaultModel = CovAgoraManager.llmType
            val modelPosition = LLMs.indexOf(defaultModel)
            if (modelPosition != -1) {
                modelAdapter.updateSelectedPosition(modelPosition)
                spModel.setSelection(modelPosition)
            }

            speakerAdapter.updateItems(speakers.map { it.value }.toList())
            val defaultSpeaker = CovAgoraManager.speakerType
            val speakerPosition = speakers.indexOf(defaultSpeaker)
            if (speakerPosition != -1) {
                speakerAdapter.updateSelectedPosition(speakerPosition)
                spSpeaker.setSelection(speakerPosition)
            }

            presetAdapter.updateItems(presets.map { it.value }.toList())
            val defaultPreset = CovAgoraManager.currentPresetType()
            val presetPosition = presets.indexOf(defaultPreset)
            if (presetPosition != -1) {
                presetAdapter.updateSelectedPosition(presetPosition)
                spPreset.setSelection(presetPosition)
            }

            languageAdapter.updateItems(languages.map { it.value }.toList())
            val defaultLanguage = CovAgoraManager.languageType
            val languagePosition = languages.indexOf(defaultLanguage)
            if (languagePosition != -1) {
                languageAdapter.updateSelectedPosition(languagePosition)
                spLanguage.setSelection(languagePosition)
            }

            microphoneAdapter.updateItems(microphones.map { it.value }.toList())
            val defaultMicrophone = CovAgoraManager.microphoneType
            val microphonePosition = microphones.indexOf(defaultMicrophone)
            if (microphonePosition != -1) {
                microphoneAdapter.updateSelectedPosition(microphonePosition)
                spMicrophone.setSelection(microphonePosition)
            }
        }
    }

    private fun setupVoiceSpinner() {
        val context = context?:return
        binding?.apply {
            voiceAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spVoice.adapter = voiceAdapter
            spVoice.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {
                    val selectedVoice = voices[position]
                    if (CovAgoraManager.voiceType != selectedVoice) {
                        uploadNewSetting(voice = selectedVoice)
                    }
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupModelSpinner() {
        val context = context?:return
        binding?.apply {
            modelAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spModel.adapter = modelAdapter
            spModel.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {

                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupLanguageSpinner() {
        val context = context?:return
        binding?.apply {
            languageAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spLanguage.adapter = languageAdapter
            spLanguage.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupMicrophoneSpinner() {
        val context = context?:return
        binding?.apply {
            microphoneAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spMicrophone.adapter = microphoneAdapter
            spMicrophone.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {

                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupSpeakerSpinner() {
        val context = context?:return
        binding?.apply {
            speakerAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spSpeaker.adapter = speakerAdapter
            spSpeaker.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupPresetSpinner() {
        val context = context?:return
        binding?.apply {
            presetAdapter = CustomArrayAdapter(
                context,
                R.layout.cov_setting_spinner_item,
                mutableListOf()
            )
            spPreset.adapter = presetAdapter
            spPreset.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {
                    val oldVoiceType = CovAgoraManager.voiceType
                    val oldLLMType = CovAgoraManager.llmType
                    val oldLanguageType = CovAgoraManager.languageType
                    val oldPreset = CovAgoraManager.currentPresetType()
                    val selectedPreset = presets[position]
                    if (CovAgoraManager.currentPresetType() != selectedPreset) {
                        if (CovAgoraManager.agentStarted) {
                            val loadingDialog = LoadingDialog(context!!).apply {
                                show()
                            }
                            CovAgoraManager.updatePreset(presets[position])
                            ConvAIManager.updateAgent(CovAgoraManager.voiceType.value) { success ->
                                loadingDialog.dismiss()
                                if (success) {
                                    updateOptionsByPresets()
                                    updateSpinners()
                                } else {
                                    CovAgoraManager.updatePreset(oldPreset)
                                    CovAgoraManager.voiceType = oldVoiceType
                                    CovAgoraManager.llmType = oldLLMType
                                    CovAgoraManager.languageType = oldLanguageType
                                    updateSpinners()
                                    ToastUtil.show(io.agora.scene.common.R.string.cov_setting_network_error)
                                }
                            }
                        } else {
                            CovAgoraManager.updatePreset(presets[position])
                            updateOptionsByPresets()
                            updateSpinners()
                        }
                    }
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
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

    private inner class CustomArrayAdapter(
        context: Context,
        resource: Int,
        private var items: MutableList<String>
    ) : ArrayAdapter<String>(context, resource, items) {

        var selectedPosition: Int = -1

        fun updateItems(newItems: List<String>) {
            clear()
            addAll(emptyList())
            items.clear()
            items.addAll(newItems)
            notifyDataSetChanged()
        }

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: LayoutInflater.from(context).inflate(
                R.layout.cov_setting_spinner_item, parent, false
            )
            val textView = view.findViewById<TextView>(R.id.tv_text)
            val iconView = view.findViewById<ImageView>(R.id.iv_icon)
            textView.text = items[position]
            iconView.visibility = View.GONE
            return view
        }

        override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: LayoutInflater.from(context).inflate(
                R.layout.cov_setting_spinner_item, parent, false
            )
            val textView = view.findViewById<TextView>(R.id.tv_text)
            val iconView = view.findViewById<ImageView>(R.id.iv_icon)
            textView.text = items[position]
            if (position == selectedPosition) {
                textView.setTextColor(Color.parseColor("#00C2FF"))
                iconView.visibility = View.VISIBLE
            } else {
                textView.setTextColor(Color.parseColor("#FFFFFF"))
                iconView.visibility = View.GONE
            }
            return view
        }

        fun updateSelectedPosition(position: Int) {
            selectedPosition = position
            notifyDataSetChanged()
        }
    }
}