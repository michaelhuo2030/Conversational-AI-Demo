package io.agora.scene.convoai.rtc

import io.agora.rtc2.RtcEngineEx
import io.agora.scene.common.constant.ServerConfig

enum class AgentVoiceType(val value: String, val display: String) {
    FEMALE_SHAONV("female-shaonv", "少女"),

    TBD("TBD", "TBD"),

    EMMA("en-US-EmmaMultilingualNeural", "Emma"),
    ANDREW("en-US-AndrewMultilingualNeural", "Andrew"),
    SERENA("en-US-SerenaMultilingualNeural", "Serena"),
    DUSTIN("en-US-DustinMultilingualNeural", "Dustin"),

    // Overseas multilingual voices
    AVA_MULTILINGUAL("en-US-AvaMultilingualNeural", "Ava (Multilingual)"),
    ANDREW_MULTILINGUAL("en-US-AndrewMultilingualNeural", "Andrew (Multilingual)"),
    EMMA_MULTILINGUAL("en-US-EmmaMultilingualNeural", "Emma (Multilingual)"),
    BRIAN_MULTILINGUAL("en-US-BrianMultilingualNeural", "Brian (Multilingual)"),
    JENNY_MULTILINGUAL("en-US-JennyMultilingualNeural4", "Jenny (Multilingual)"),

    // Overseas standard voices
    AVA("en-US-AvaNeural", "Ava"),

    BRIAN("en-US-BrianNeural", "Brian"),
    JENNY("en-US-JennyNeural", "Jenny"),
    GUY("en-US-GuyNeural", "Guy"),
    ARIA("en-US-AriaNeural", "Aria"),
    DAVIS("en-US-DavisNeural", "Davis"),
    JANE("en-US-JaneNeural", "Jane"),
    JASON("en-US-JasonNeural", "Jason"),
    SARA("en-US-SaraNeural", "Sara"),
    TONY("en-US-TonyNeural", "Tony"),
    NANCY("en-US-NancyNeural", "Nancy"),
    AMBER("en-US-AmberNeural", "Amber"),
    ANA("en-US-AnaNeural", "Ana"),
    ASHLEY("en-US-AshleyNeural", "Ashley"),
    BRANDON("en-US-BrandonNeural", "Brandon"),
    CHRISTOPHER("en-US-ChristopherNeural", "Christopher"),
    CORA("en-US-CoraNeural", "Cora"),
    ELIZABETH("en-US-ElizabethNeural", "Elizabeth"),
    ERIC("en-US-EricNeural", "Eric"),
    JACOB("en-US-JacobNeural", "Jacob"),
    MICHELLE("en-US-MichelleNeural", "Michelle"),
    MONICA("en-US-MonicaNeural", "Monica"),
    ROGER("en-US-RogerNeural", "Roger"),

    // Mainland standard voices
    MALE_QINGSE("male-qn-qingse", "青涩青年音色"),
    MALE_JINGYING("male-qn-jingying", "精英青年音色"),
    MALE_BADAO("male-qn-badao", "霸道青年音色"),
    MALE_DAXUESHENG("male-qn-daxuesheng", "青年大学生音色"),
    FEMALE_YUJIE("female-yujie", "御姐音色"),
    FEMALE_CHENGSHU("female-chengshu", "成熟女性音色"),
    FEMALE_TIANMEI("female-tianmei", "甜美女性音色"),

    // Mainland presenters
    PRESENTER_MALE("presenter_male", "男性主持人"),
    PRESENTER_FEMALE("presenter_female", "女性主持人"),

    // Mainland audiobook voices
    AUDIOBOOK_MALE_1("audiobook_male_1", "男性有声书1"),
    AUDIOBOOK_MALE_2("audiobook_male_2", "男性有声书2"),
    AUDIOBOOK_FEMALE_1("audiobook_female_1", "女性有声书1"),
    AUDIOBOOK_FEMALE_2("audiobook_female_2", "女性有声书2"),

    // Mainland beta voices
    MALE_QINGSE_BETA("male-qn-qingse-jingpin", "青涩青年音色-beta"),
    MALE_JINGYING_BETA("male-qn-jingying-jingpin", "精英青年音色-beta"),
    MALE_BADAO_BETA("male-qn-badao-jingpin", "霸道青年音色-beta"),
    MALE_DAXUESHENG_BETA("male-qn-daxuesheng-jingpin", "青年大学生音色-beta"),
    FEMALE_SHAONV_BETA("female-shaonv-jingpin", "少女音色-beta"),
    FEMALE_YUJIE_BETA("female-yujie-jingpin", "御姐音色-beta"),
    FEMALE_CHENGSHU_BETA("female-chengshu-jingpin", "成熟女性音色-beta"),
    FEMALE_TIANMEI_BETA("female-tianmei-jingpin", "甜美女性音色-beta"),

    // Mainland character voices
    CLEVER_BOY("clever_boy", "聪明男童"),
    CUTE_BOY("cute_boy", "可爱男童"),
    LOVELY_GIRL("lovely_girl", "萌萌女童"),
    CARTOON_PIG("cartoon_pig", "卡通猪小琪"),
    JUNLANG_NANYOU("junlang_nanyou", "俊朗男友"),
    TIANXIN_XIAOLING("tianxin_xiaoling", "甜心小玲"),
    QIAOPI_MENGMEI("qiaopi_mengmei", "俏皮萌妹"),
    WUMEI_YUJIE("wumei_yujie", "妩媚御姐"),
    DIADIA_XUEMEI("diadia_xuemei", "嗲嗲学妹"),
    DANYA_XUEJIE("danya_xuejie", "淡雅学姐"),
    BADAO_SHAOYE("badao_shaoye", "霸道少爷"),
    LENGDAN_XIONGZHANG("lengdan_xiongzhang", "冷淡学长"),
    CHUNZHEN_XUEDI("chunzhen_xuedi", "纯真学弟");

    companion object {

        val options: Array<AgentVoiceType>
            get() = arrayOf(EMMA)
    }
}

enum class AgentLLMType(val value: String, val display: String) {
    OPEN_AI("GPT-4o-mini", "OpenAI"),
    MINIMAX("minimax-abab6.5s-chat", "MiniMax"),
    TONG_YI("通义千问", "通义千问"),
}

enum class AgentLanguageType(val value: String) {
    EN("English"),
    CN("中文");
}

enum class AgentPresetType(val value: String) {
    VERSION1("v1.0"),
    XIAO_AI("小艾"),
    TBD("TBD"),
    DEFAULT("Default"),
    AMY("Amy");

    companion object {
        val options: Array<AgentPresetType>
            get() = if (ServerConfig.isMainlandVersion) {
                arrayOf(XIAO_AI, TBD)
            } else {
                arrayOf(DEFAULT, AMY)
            }
    }
}

enum class AgentMicrophoneType(val value: String) {
    MICROPHONE1("Default Microphone")
}

enum class AgentSpeakerType(val value: String) {
    SPEAKER1("BoseFlex")
}

object CovAgoraManager {

    private val isMainlandVersion: Boolean get() = ServerConfig.isMainlandVersion

    // Settings
    var speakerType = AgentSpeakerType.SPEAKER1
    var microphoneType = AgentMicrophoneType.MICROPHONE1
    private var presetType = AgentPresetType.VERSION1
    var voiceType = if (isMainlandVersion)
        AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
    var llmType = AgentLLMType.OPEN_AI
    var languageType = AgentLanguageType.EN
    private var isDenoise = false

    // Status
    var uid = 0
    var channelName = ""
    var agentStarted = false
    var rtcEngine: RtcEngineEx? = null

    fun updatePreset(type: AgentPresetType) {
        presetType = type
        when (type) {
            AgentPresetType.VERSION1 -> {
                voiceType = if (isMainlandVersion)
                    AgentVoiceType.MALE_QINGSE else AgentVoiceType.AVA_MULTILINGUAL
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
            AgentPresetType.XIAO_AI -> {
                voiceType = AgentVoiceType.FEMALE_SHAONV
                llmType = AgentLLMType.MINIMAX
                languageType = AgentLanguageType.CN
            }
            AgentPresetType.TBD -> {
                voiceType = AgentVoiceType.TBD
                llmType = AgentLLMType.MINIMAX
                languageType = AgentLanguageType.CN
            }
            AgentPresetType.DEFAULT -> {
                voiceType = AgentVoiceType.ANDREW
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
            AgentPresetType.AMY -> {
                voiceType = AgentVoiceType.EMMA
                llmType = AgentLLMType.OPEN_AI
                languageType = AgentLanguageType.EN
            }
        }
    }

    fun currentDenoiseStatus(): Boolean {
        return isDenoise
    }

    fun updateDenoise(isOn: Boolean) {
        isDenoise = isOn
        if (isDenoise) {
            rtcEngine?.apply {
                setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
                setParameters("{\"che.audio.sf.enabled\":true}")
                setParameters("{\"che.audio.sf.ainlpToLoadFlag\":1}")
                setParameters("{\"che.audio.sf.nlpAlgRoute\":1}")
                setParameters("{\"che.audio.sf.ainlpModelPref\":11}")
                setParameters("{\"che.audio.sf.ainsToLoadFlag\":1}")
                setParameters("{\"che.audio.sf.nsngAlgRoute\":12}")
                setParameters("{\"che.audio.sf.ainsModelPref\":11}")
                setParameters("{\"che.audio.sf.nsngPredefAgg\":11}")
                setParameters("{\"che.audio.agc.enable\":false}")
            }
        } else {
            rtcEngine?.apply {
                setParameters("{\"che.audio.sf.enabled\":false}")
            }
        }
    }

    fun currentPresetType(): AgentPresetType {
        return presetType
    }

    fun resetData() {
        rtcEngine = null
        updatePreset(if (isMainlandVersion) AgentPresetType.XIAO_AI else AgentPresetType.DEFAULT)
        isDenoise = false
    }
}