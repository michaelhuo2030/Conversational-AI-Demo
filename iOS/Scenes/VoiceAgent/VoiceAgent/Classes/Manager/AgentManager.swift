import Foundation
import AgoraRtcKit
import Common

protocol AgentProtocol {
    func getRtcEntine() -> AgoraRtcEngineKit
    func startAgent(uid: Int, agentUid: Int, completion: @escaping (AgentError?, String?) -> Void)
    func stopAgent(agentUid: String, completion: @escaping (AgentError?, [String: Any]?) -> Void)
    func updateAgent(agentUid: String, appId: String, voiceId: String, completion: @escaping((AgentError?) -> Void))
    func joinChannel() -> Int32
    func openDenoise()
    func closeDenoise()
    func muteVoice(state: Bool)
    func destroy()
}

enum RtcEnum {
    private static let uidKey = "uidKey"
    private static let channelKey = "channelKey"
    private static var channelId: String?
    private static var uid: Int?
    
    static func getUid() -> Int {
        if let uid = uid {
            return uid
        } else {
            let randomUid = Int.random(in: 1000...9999999)
            uid = randomUid
            return randomUid
        }
    }
    
    static func getChannel() -> String {
        if let channel = channelId {
            return channel
        } else {
            let characters = Array("0123456789abcdefghijklmnopqrstuvwxyz")
            let randomString = String((0..<4).compactMap { _ in characters.randomElement() })
            channelId = randomString
            return randomString
        }
    }
}

class AgentManager: NSObject {
    private var rtcEngine: AgoraRtcEngineKit!
    private(set) var appId: String = ""
    private(set) var channelName: String = ""
    private(set) var token: String = ""
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
        
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .liveBroadcasting
        config.audioScenario = .chorus
        rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self.delegate)
        rtcEngine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}");
        rtcEngine.setParameters("{\"che.audio.sf.enabled\":true}");
        rtcEngine.setParameters("{\"che.audio.sf.ainlpToLoadFlag\":1}");
        rtcEngine.setParameters("{\"che.audio.sf.nlpAlgRoute\":1}");
        rtcEngine.setParameters("{\"che.audio.sf.ainlpModelPref\":11}");
        rtcEngine.setParameters("{\"che.audio.sf.ainsToLoadFlag\":1}");
        rtcEngine.setParameters("{\"che.audio.sf.nsngAlgRoute\":12}");
        rtcEngine.setParameters("{\"che.audio.sf.ainsModelPref\":11}");
        rtcEngine.setParameters("{\"che.audio.sf.nsngPredefAgg\":11}");
        rtcEngine.setParameters("{\"che.audio.agc.enable\":false}");
        rtcEngine.enableAudioVolumeIndication(100, smooth: 3, reportVad: false)
    }
}
    
extension AgentManager: AgentProtocol {
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


