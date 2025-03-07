package io.agora.scene.convoai.iot.manager

import io.agora.scene.convoai.iot.api.CovIotPreset
import io.agora.scene.convoai.iot.api.CovIotLanguage

object CovIotPresetManager {

    private const val TAG = "CovIotPresetManager"

    private var presetList: List<CovIotPreset>? = null

    fun getPreset(presetName: String): CovIotPreset? {
        return presetList?.find { it.display_name == presetName }
    }

    fun setPresetList(l: List<CovIotPreset>) {
        presetList = l
    }

    fun getPresetList(): List<CovIotPreset>? {
        return presetList
    }

    fun getLanguageList(): List<CovIotLanguage>? {
        return presetList?.firstOrNull()?.support_languages
    }

    fun getPresetLanguages(presetName: String): List<CovIotLanguage>? {
        return presetList?.find { it.preset_name == presetName }?.support_languages
    }
}
