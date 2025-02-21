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
    case emma2 = "en-US-Emma2:DragonHDLatestNeural"
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
        case .emma, .emma2: return "Emma"
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
            return [.emma2]
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
