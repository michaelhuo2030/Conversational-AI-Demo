import Foundation
import AgoraRtcKit
import Common

class AgentManager: NSObject {
    var token: String = ""
    private var rtcEngine: AgoraRtcEngineKit!
    private(set) var appId: String = ""
    private(set) var channelName: String = ""
    private(set) var uid: String = ""
    private(set) var host: String = ""
    private weak var delegate: AgoraRtcEngineDelegate?
    private var agentApiService: AgentAPIService!
        
    init(appId: String, channelName: String, token: String, host: String, delegate: AgoraRtcEngineDelegate?) {
        self.appId = appId
        self.channelName = channelName
        self.token = token
        self.host = host
        self.delegate = delegate

        super.init()
        initService()
    }
    
    private func addLog(_ txt: String) {
        print(txt)
    }
    
    private func initService() {
        agentApiService = AgentAPIService(host: host)
        
        
    }
}

class AgoraManager {
    
    static let shared = AgoraManager()
    
    // MARK: - Properties
    
    private var isMainlandVersion: Bool { ServerConfig.isMainlandVersion }
    
    // Settings
    var speakerType: AgentSpeakerType = .speaker1
    var microphoneType: AgentMicrophoneType = .microphone1
    private var presetType: AgentPresetType = .version1
    var voiceType: AgentVoiceType {
        isMainlandVersion ? .maleQingse : .avaMultilingual
    }
    var llmType: AgentLLMType = .openAI
    var languageType: AgentLanguageType = .en
    private var isDenoise = false
    
    // Status
    var uid: Int = 0
    var channelName: String = ""
    var agentStarted: Bool = false
    var rtcEngine: RtcEngineEx?
    
    // MARK: - Methods
    
    func updatePreset(type: AgentPresetType) {
        presetType = type
        switch type {
        case .version1:
            voiceType = isMainlandVersion ? .maleQingse : .avaMultilingual
            llmType = .openAI
            languageType = .en
        case .xiaoAI:
            voiceType = .femaleShaonv
            llmType = .minimax
            languageType = .cn
        case .tbd:
            voiceType = .tbd
            llmType = .minimax
            languageType = .cn
        case .default:
            voiceType = .andrew
            llmType = .openAI
            languageType = .en
        case .amy:
            voiceType = .emma
            llmType = .openAI
            languageType = .en
        }
    }
    
    func currentDenoiseStatus() -> Bool {
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
    
    func currentPresetType() -> AgentPresetType {
        return presetType
    }
    
    func resetData() {
        rtcEngine = nil
        updatePreset(isMainlandVersion ? .xiaoAI : .default)
        isDenoise = false
    }
}
    
extension AgentManager {
    func getRtcEntine() -> AgoraRtcEngineKit {
        return rtcEngine
    }
    
    func startAgent(uid: Int, agentUid: Int, completion: @escaping (AgentError?, String?) -> Void) {
        agentApiService.startAgent(uid: uid, agentUid: agentUid, channelName: channelName, completion: completion)
    }
    
    func updateAgent(agentUid: String, appId: String, voiceId: String, completion: @escaping((AgentError?) -> Void)) {
        agentApiService.updateAgent(agentUid: agentUid, appId: appId, voiceId: voiceId, completion: completion)
    }
    
    func joinChannel() -> Int32 {
        let uid = UInt(RtcEnum.getUid())
        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false
        return rtcEngine.joinChannel(byToken: token, channelId: channelName, uid: uid, mediaOptions: options)
    }
    
    func stopAgent(agentUid: String, completion: @escaping (AgentError?, [String: Any]?) -> Void) {
        agentApiService.stopAgent(agentUid: agentUid, channelName: channelName, completion: completion)
    }
    
    func openDenoise() {
        AgentSettingManager.shared.isNoiseCancellationEnabled = true
        let params = [
            "{\"che.audio.sf.enabled\":true}",
            "{\"che.audio.sf.ainlpToLoadFlag\":1}",
            "{\"che.audio.sf.nlpAlgRoute\":1}",
            "{\"che.audio.sf.ainsToLoadFlag\":1}",
            "{\"che.audio.sf.nsngAlgRoute\":12}",
            "{\"che.audio.sf.ainsModelPref\":11}",
            "{\"che.audio.sf.ainlpModelPref\":11}"
        ]
        params.forEach { rtcEngine.setParameters($0) }
    }
    
    func closeDenoise() {
        rtcEngine.setParameters("{\"che.audio.sf.enabled\":false}")
        AgentSettingManager.shared.isNoiseCancellationEnabled = false
    }
    
    func muteVoice(state: Bool) {
        rtcEngine.adjustRecordingSignalVolume(state ? 0 : 100)
    }
    
    func destroy() {
        rtcEngine.leaveChannel()
        AgoraRtcEngineKit.destroy()
    }
}


