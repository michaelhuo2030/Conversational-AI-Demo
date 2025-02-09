//
//  AgentPreferenceManager.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/8.
//

import Foundation
import AgoraRtcKit

protocol AgentPreferenceManagerDelegate: AnyObject {
    func preferenceManager(_ manager: AgentPreferenceManager, presetDidUpdated preset: AgentPreset)
    func preferenceManager(_ manager: AgentPreferenceManager, languageDidUpdated language: SupportLanguage)
    func preferenceManager(_ manager: AgentPreferenceManager, aiVadStateDidUpdated state: Bool)
    func preferenceManager(_ manager: AgentPreferenceManager, forceThresholdStateDidUpdated state: Bool)
    
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus)
    func preferenceManager(_ manager: AgentPreferenceManager, agentStateDidUpdated agentState: ConnectionStatus)
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus)
    func preferenceManager(_ manager: AgentPreferenceManager, roomIdDidUpdated roomId: String)
    func preferenceManager(_ manager: AgentPreferenceManager, userIdDidUpdated userId: String)
}

protocol AgentPreferenceManagerProtocol {
    // Delegate Management
    func addDelegate(_ delegate: AgentPreferenceManagerDelegate)
    func removeDelegate(_ delegate: AgentPreferenceManagerDelegate)
    
    
    // Preference Updates
    func updatePreset(_ preset: AgentPreset)
    func updateLanguage(_ language: SupportLanguage)

//    func updatePreset(_ preset: String)
//    func updateLanguage(_ language: String)
    func updateAiVadState(_ state: Bool)
    func updateForceThresholdState(_ state: Bool)
    
    // Information Updates
    func updateNetworkState(_ state: NetworkStatus)
    func updateAgentState(_ state: ConnectionStatus)
    func updateRoomState(_ state: ConnectionStatus)
    func updateRoomId(_ roomId: String)
    func updateUserId(_ userId: String)
    
    func allPresets() -> [AgentPreset]?
    func setPresets(presets: [AgentPreset])
}

class AgentPreferenceManager: AgentPreferenceManagerProtocol {
    static let shared = AgentPreferenceManager()
    let preference = AgentPreference()
    let information = AgentInfomation()
    private var presets: [AgentPreset]?
    
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    // MARK: - Delegate Management
    func addDelegate(_ delegate: AgentPreferenceManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: AgentPreferenceManagerDelegate) {
        delegates.remove(delegate)
    }
    
    // MARK: - Preference Updates
    func updatePreset(_ preset: AgentPreset) {
        preference.preset = preset
        notifyDelegates { $0.preferenceManager(self, presetDidUpdated: preset) }
    }
    
    func updateLanguage(_ language: SupportLanguage) {
        preference.language = language
        notifyDelegates { $0.preferenceManager(self, languageDidUpdated: language) }
    }
    
    func updateAiVadState(_ state: Bool) {
        preference.aiVad = state
        notifyDelegates { $0.preferenceManager(self, aiVadStateDidUpdated: state) }
    }
    
    func updateForceThresholdState(_ state: Bool) {
        preference.forceThreshold = state
        notifyDelegates { $0.preferenceManager(self, forceThresholdStateDidUpdated: state) }
    }
    
    // MARK: - Information Updates
    func updateNetworkState(_ state: NetworkStatus) {
        information.networkState = state
        notifyDelegates { $0.preferenceManager(self, networkDidUpdated: state) }
    }
    
    func updateAgentState(_ state: ConnectionStatus) {
        information.agentState = state
        notifyDelegates { $0.preferenceManager(self, agentStateDidUpdated: state) }
    }
    
    func updateRoomState(_ state: ConnectionStatus) {
        information.rtcRoomState = state
        notifyDelegates { $0.preferenceManager(self, roomStateDidUpdated: state) }
    }
    
    func updateRoomId(_ roomId: String) {
        information.roomId = roomId
        notifyDelegates { $0.preferenceManager(self, roomIdDidUpdated: roomId) }
    }
    
    func updateUserId(_ userId: String) {
        information.userId = userId
        notifyDelegates { $0.preferenceManager(self, userIdDidUpdated: userId) }
    }
    
    func allPresets() -> [AgentPreset]? {
        return presets
    }
    
    func setPresets(presets: [AgentPreset]) {
        self.presets = presets
        if presets.isEmpty { return }
        
        guard let preset = presets.first else {
            return
        }
        
        self.updatePreset(preset)
        
        if preset.supportLanguages.isEmpty { return }
        
        guard let language = preset.supportLanguages.first else {
            return
        }
        
        self.updateLanguage(language)
    }
    
    // MARK: - Private Methods
    private func notifyDelegates(_ notification: (AgentPreferenceManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? AgentPreferenceManagerDelegate {
                notification(delegate)
            }
        }
    }
}

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

enum NetworkStatus: String {
    case good = "Good"
    case poor = "Okay"
    case veryBad = "Poor"
    case unknown = ""
    
    init(agoraQuality: AgoraNetworkQuality) {
        switch agoraQuality {
        case .excellent, .good:
            self = .good
        case .poor:
            self = .poor
        case .bad, .vBad, .down:
            self = .veryBad
        default:
            self = .unknown
        }
    }
    
    var color: UIColor {
        switch self {
        case .good:
            return UIColor(hex: 0x36B37E)
        case .poor:
            return UIColor(hex: 0xFFAB00)
        case .veryBad, .unknown:
            return UIColor(hex: 0xFF414D)
        }
    }
}

class AgentPreference {
    var preset: AgentPreset?
    var language: SupportLanguage?
    var aiVad = true
    var forceThreshold = true
}

class AgentInfomation {
    var networkState: NetworkStatus = .unknown
    var agentState: ConnectionStatus = .unload
    var rtcRoomState: ConnectionStatus = .unload
    var roomId: String = ""
    var userId: String = ""
}

extension AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, presetDidUpdated preset: AgentPreset) {}
    func preferenceManager(_ manager: AgentPreferenceManager, languageDidUpdated language: SupportLanguage) {}
    func preferenceManager(_ manager: AgentPreferenceManager, aiVadStateDidUpdated state: Bool) {}
    func preferenceManager(_ manager: AgentPreferenceManager, forceThresholdStateDidUpdated state: Bool) {}
    
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {}
    func preferenceManager(_ manager: AgentPreferenceManager, agentStateDidUpdated agentState: ConnectionStatus) {}
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus) {}
    func preferenceManager(_ manager: AgentPreferenceManager, roomIdDidUpdated roomId: String) {}
    func preferenceManager(_ manager: AgentPreferenceManager, userIdDidUpdated userId: String) {}
}
