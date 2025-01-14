import Foundation
import Common

// MARK: - Setting Types
enum AgentPresetType: String, CaseIterable {
    case xiaoi = "小艾"
    case defaultPreset = "Default"
    case amy = "Amy"
    
    static var availablePresets: [AgentPresetType] {
        if AppContext.shared.appArea == .mainland {
            return [.xiaoi]
        } else {
            return [.defaultPreset, .amy]
        }
    }
}

enum AgentVoiceType: String {
    // Mainland voices
    case femaleShaonv = "female-shaonv"
    
    // Overseas voices
    case emma = "en-US-EmmaMultilingualNeural"
    case andrew = "en-US-AndrewMultilingualNeural"
    case serena = "en-US-SerenaMultilingualNeural"
    case dustin = "en-US-DustinMultilingualNeural"
    
    static var isMainlandVersion: Bool = AppContext.shared.appArea == .mainland
    
    var voiceId: String {
        return self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .femaleShaonv: return "少女"
        case .emma: return "Emma"
        case .andrew: return "Andrew"
        case .serena: return "Serena"
        case .dustin: return "Dustin"
        }
    }
    
    static func availableVoices(for preset: AgentPresetType) -> [AgentVoiceType] {
        switch preset {
        case .xiaoi:
            return [.femaleShaonv]
        case .defaultPreset:
            return [.andrew, .emma, .dustin, .serena]
        case .amy:
            return [.emma]
        }
    }
}

enum AgentModelType: String, CaseIterable {
    case openAI = "OpenAI"
    case minimax = "MiniMax"
    
    static var isMainlandVersion: Bool = AppContext.shared.appArea == .mainland
    
    static var availableModels: [AgentModelType] {
        if isMainlandVersion {
            return [.minimax]
        } else {
            return [.openAI]
        }
    }
    
    static func availableModels(for preset: AgentPresetType) -> [AgentModelType] {
        switch preset {
        case .xiaoi:
            return [.minimax]
        case .defaultPreset, .amy:
            return [.openAI]
        }
    }
}

enum AgentLanguageType: String {
    case english = "English"
    case chinese = "中文"
    
    static func availableLanguages(for preset: AgentPresetType) -> [AgentLanguageType] {
        switch preset {
        case .xiaoi:
            return [.chinese]
        case .defaultPreset, .amy:
            return [.english]
        }
    }
}

// MARK: - Connection Status
enum ConnectionStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case unload = "Unload"
    
    var color: UIColor {
        switch self {
        case .connected:
            return UIColor(hex: 0x36B37E) // Green
        case .disconnected:
            return UIColor(hex: 0xFF5630) // Red
        case .unload:
            return UIColor(hex: 0x8F92A1) // Gray
        }
    }
}

// MARK: - Setting Manager
class AgentSettingManager {
    static let shared = AgentSettingManager()
    
    // MARK: - Properties
    private var presetType: AgentPresetType
    private var voiceType: AgentVoiceType
    private var modelType: AgentModelType
    private var languageType: AgentLanguageType
    private var noiseCancellation: Bool = false
    
    private(set) var agentStatus: ConnectionStatus = .unload
    private(set) var roomStatus: ConnectionStatus = .unload
    private(set) var roomId: String = ""
    private(set) var yourId: String = ""
    
    private init() {
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
    
    // MARK: - Noise Cancellation
    var isNoiseCancellationEnabled: Bool {
        get { noiseCancellation }
        set { noiseCancellation = newValue }
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
    func updateAgentStatus(_ status: ConnectionStatus) {
        agentStatus = status
    }
    
    func updateRoomStatus(_ status: ConnectionStatus) {
        roomStatus = status
    }
    
    func updateRoomId(_ id: String) {
        roomId = id
    }
    
    func updateYourId(_ id: String) {
        yourId = id
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
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
        noiseCancellation = false
        
        // 重置状态
        agentStatus = .unload
        roomStatus = .unload
        roomId = ""
        yourId = ""
    }
} 
