package io.agora.agent

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.CompoundButton
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import io.agora.agent.base.BaseSheetDialog
import io.agora.agent.databinding.SettingDialogBinding
import io.agora.agent.http.ConvAIManager
import io.agora.agent.rtc.AgentLanguageType
import io.agora.agent.rtc.AgentMicrophoneType
import io.agora.agent.rtc.AgentLLMType
import io.agora.agent.rtc.AgentPresetType
import io.agora.agent.rtc.AgentSpeakerType
import io.agora.agent.rtc.AgentVoiceType
import io.agora.agent.rtc.AgoraManager

class AgentSettingsSheetDialog : BaseSheetDialog<SettingDialogBinding>() {

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
    ): SettingDialogBinding {
        return SettingDialogBinding.inflate(inflater, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        updateOptionsByPresets()
        binding?.apply {
            setOnApplyWindowInsets(root)
            cbNoiseCancellation.isChecked = AgoraManager.currentDenoiseStatus()
            cbNoiseCancellation.setOnCheckedChangeListener { _: CompoundButton?, isChecked: Boolean ->
                AgoraManager.updateDenoise(isChecked)
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
        val loadingDialog = LoadingDialog(context!!).apply {
            show()
        }
        ConvAIManager.updateAgent(voice.value) { success ->
            loadingDialog.dismiss()
            if (success) {
                AgoraManager.voiceType = voice
                llm?.let { AgoraManager.llmType = llm }
                language?.let { AgoraManager.languageType = language }
                updateSpinners()
            } else {
                updateSpinners()
                Toast.makeText(
                    context,
                    R.string.cov_setting_network_error,
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    private fun updateSpinners() {
        binding?.apply {
            voiceAdapter.updateItems(voices.map { it.display }.toList())
            val defaultVoice = AgoraManager.voiceType
            val voicePosition = voices.indexOf(defaultVoice)
            if (voicePosition != -1) {
                voiceAdapter.updateSelectedPosition(voicePosition)
                spVoice.setSelection(voicePosition)
            }

            modelAdapter.updateItems(LLMs.map { it.display }.toList())
            val defaultModel = AgoraManager.llmType
            val modelPosition = LLMs.indexOf(defaultModel)
            if (modelPosition != -1) {
                modelAdapter.updateSelectedPosition(modelPosition)
                spModel.setSelection(modelPosition)
            }

            speakerAdapter.updateItems(speakers.map { it.value }.toList())
            val defaultSpeaker = AgoraManager.speakerType
            val speakerPosition = speakers.indexOf(defaultSpeaker)
            if (speakerPosition != -1) {
                speakerAdapter.updateSelectedPosition(speakerPosition)
                spSpeaker.setSelection(speakerPosition)
            }

            presetAdapter.updateItems(presets.map { it.value }.toList())
            val defaultPreset = AgoraManager.currentPresetType()
            val presetPosition = presets.indexOf(defaultPreset)
            if (presetPosition != -1) {
                presetAdapter.updateSelectedPosition(presetPosition)
                spPreset.setSelection(presetPosition)
            }

            languageAdapter.updateItems(languages.map { it.value }.toList())
            val defaultLanguage = AgoraManager.languageType
            val languagePosition = languages.indexOf(defaultLanguage)
            if (languagePosition != -1) {
                languageAdapter.updateSelectedPosition(languagePosition)
                spLanguage.setSelection(languagePosition)
            }

            microphoneAdapter.updateItems(microphones.map { it.value }.toList())
            val defaultMicrophone = AgoraManager.microphoneType
            val microphonePosition = microphones.indexOf(defaultMicrophone)
            if (microphonePosition != -1) {
                microphoneAdapter.updateSelectedPosition(microphonePosition)
                spMicrophone.setSelection(microphonePosition)
            }
        }
    }

    private fun setupVoiceSpinner() {
        binding?.apply {
            voiceAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
                    if (AgoraManager.voiceType != selectedVoice) {
                        uploadNewSetting(voice = selectedVoice)
                    }
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun setupModelSpinner() {
        binding?.apply {
            modelAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
        binding?.apply {
            languageAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
        binding?.apply {
            microphoneAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
        binding?.apply {
            speakerAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
        binding?.apply {
            presetAdapter = CustomArrayAdapter(
                this@AgentSettingsSheetDialog.context!!,
                R.layout.agent_setting_spinner_list_item,
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
                    val oldVoiceType = AgoraManager.voiceType
                    val oldLLMType = AgoraManager.llmType
                    val oldLanguageType = AgoraManager.languageType
                    val oldPreset = AgoraManager.currentPresetType()
                    val selectedPreset = presets[position]
                    if (AgoraManager.currentPresetType() != selectedPreset) {
                        val loadingDialog = LoadingDialog(context!!).apply {
                            show()
                        }
                        AgoraManager.updatePreset(presets[position])
                        ConvAIManager.updateAgent(AgoraManager.voiceType.value) { success ->
                            loadingDialog.dismiss()
                            if (success) {
                                updateOptionsByPresets()
                                updateSpinners()
                            } else {
                                AgoraManager.updatePreset(oldPreset)
                                AgoraManager.voiceType = oldVoiceType
                                AgoraManager.llmType = oldLLMType
                                AgoraManager.languageType = oldLanguageType
                                updateSpinners()
                                Toast.makeText(
                                    context,
                                    R.string.cov_setting_network_error,
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        }
                    }
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {}
            }
        }
    }

    private fun updateOptionsByPresets() {
        when (AgoraManager.currentPresetType()) {
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
                R.layout.agent_setting_spinner_list_item, parent, false
            )
            val textView = view.findViewById<TextView>(R.id.tv_text)
            val iconView = view.findViewById<ImageView>(R.id.iv_icon)
            textView.text = items[position]
            iconView.visibility = View.GONE
            return view
        }

        override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
            val view = convertView ?: LayoutInflater.from(context).inflate(
                R.layout.agent_setting_spinner_list_item, parent, false
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