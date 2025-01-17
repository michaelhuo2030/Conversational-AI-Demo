import Foundation
import AgoraRtcKit
import Common

class AgoraManager {
    
    static let shared = AgoraManager()
    
    private var isDenoise = false
    
    // Status
    var uid: Int = 0
    var channelName: String = ""
    var agentStarted: Bool = false
    var rtcEngine: AgoraRtcEngineKit?
    
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
    
    func resetData() {
        rtcEngine = nil
//        updatePreset(isMainlandVersion ? .xiaoAI : .default)
        isDenoise = false
    }
}
