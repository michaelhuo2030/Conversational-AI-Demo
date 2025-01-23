import Foundation
import AgoraRtcKit
import Common

class DHSceneManager {
    
    static let shared = DHSceneManager()
    
    private var presetType: AgentPresetType
    private var voiceType: AgentVoiceType
    private var modelType: AgentModelType
    private var languageType: AgentLanguageType
    
    private(set) var roomStatus: ConnectionStatus = .unload
    private(set) var networkStatus: NetworkStatus = .unknown
    
    private var isDenoise = false
    
    var uid: UInt = 0
    var channelName: String = ""
    var agentStarted: Bool = false
    var rtcEngine: AgoraRtcEngineKit?
    
    private init() {
        if AppContext.shared.appArea == .mainland {
            presetType = .xiaoi
            voiceType = .femaleShaonv
            modelType = .minimax
            languageType = .chinese
        } else {
            presetType = .defaultPreset
            voiceType = .emma
            modelType = .openAI
            languageType = .english
        }
    }
    
    func getDenoise() -> Bool {
        return isDenoise
    }
    
    func updateDenoise(isOn: Bool) {
        isDenoise = isOn
        if isDenoise {
            rtcEngine?.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
            rtcEngine?.setParameters("{\"che.audio.sf.enabled\":true}")
            rtcEngine?.setParameters("{\"che.audio.sf.ainlpToLoadFlag\":1}")
            rtcEngine?.setParameters("{\"che.audio.sf.nlpAlgRoute\":1}")
            rtcEngine?.setParameters("{\"che.audio.sf.ainlpModelPref\":11}")
            rtcEngine?.setParameters("{\"che.audio.sf.ainsToLoadFlag\":1}")
            rtcEngine?.setParameters("{\"che.audio.sf.nsngAlgRoute\":12}")
            rtcEngine?.setParameters("{\"che.audio.sf.ainsModelPref\":11}")
            rtcEngine?.setParameters("{\"che.audio.sf.nsngPredefAgg\":11}")
            rtcEngine?.setParameters("{\"che.audio.agc.enable\":false}")
        } else {
            rtcEngine?.setParameters("{\"che.audio.sf.enabled\":false}")
        }
    }
    
    func resetData() {
        rtcEngine = nil
//        updatePreset(isMainlandVersion ? .xiaoAI : .default)
        isDenoise = false
        roomStatus = .unload
        channelName = ""
        uid = 0
        
        if AppContext.shared.appArea == .mainland {
            presetType = .xiaoi
            voiceType = .femaleShaonv
            modelType = .minimax
            languageType = .chinese
        } else {
            presetType = .defaultPreset
            voiceType = .andrew
            modelType = .openAI
            languageType = .english
        }
    }
    
    // MARK: - Preset Type
    var currentPresetType: AgentPresetType {
        get { presetType }
        set {
            presetType = newValue
            updateSettingsForCurrentPreset()
        }
    }
    
    // MARK: - Voice Type
    var currentVoiceType: AgentVoiceType {
        get { voiceType }
        set { voiceType = newValue }
    }
    
    // MARK: - Model Type
    var currentModelType: AgentModelType {
        get { modelType }
        set { modelType = newValue }
    }
    
    // MARK: - Language Type
    var currentLanguageType: AgentLanguageType {
        get { languageType }
        set { languageType = newValue }
    }
    
    // MARK: - Helper Methods
    private func updateSettingsForCurrentPreset() {
        let availableVoices = AgentVoiceType.availableVoices(for: presetType)
        voiceType = availableVoices.first ?? voiceType
        
        let availableModels = AgentModelType.availableModels(for: presetType)
        modelType = availableModels.first ?? modelType
        
        let availableLanguages = AgentLanguageType.availableLanguages(for: presetType)
        languageType = availableLanguages.first ?? languageType
    }
    
    // MARK: - Status Update Methods
    func updateAgentNetwork(_ status: NetworkStatus) {
        networkStatus = status
    }
    
    func updateRoomStatus(_ status: ConnectionStatus) {
        roomStatus = status
    }
}
