//
//  VoiceAgentContext.swift
//  VoiceAgent-VoiceAgent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit
import Common
import SVProgressHUD

@objcMembers
public class VoiceAgentEntrance: NSObject {
    public static let kSceneName = "VoiceAgent"
    
    public static func voiceAgentScene(viewController: UIViewController) {
        let vc = ChatViewController()
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}

extension AppContext {
    static private var _preferenceManager: AgentPreferenceManager?
    
    static func preferenceManager() -> AgentPreferenceManager? {
        if let manager = _preferenceManager {
            return manager
        }
        
        _preferenceManager = AgentPreferenceManager()
        
        return _preferenceManager
    }
    
    static func destory() {
        _preferenceManager = nil
    }
    
    static var agentUid: Int {
        return 999
    }
    
    static var uid: Int {
        return Int(arc4random_uniform(90000000))
    }
}
