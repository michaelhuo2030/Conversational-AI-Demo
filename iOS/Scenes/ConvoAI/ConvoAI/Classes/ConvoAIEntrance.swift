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
public class ConvoAIEntrance: NSObject {
    public static let kSceneName = "ConvoAI"
    
//    public static func voiceAgentScene(viewController: UIViewController) {
//        let vc = ChatViewController()
//        viewController.navigationController?.pushViewController(vc, animated: true)
//    }
}

extension AppContext {
    static private var _preferenceManager: AgentPreferenceManager?
    static private var _loginManager: LoginManager?
    static private var _iotDeviceManager: IOTDeviceManager?
    static private var _iotPresetsManager: IOTPresetsManager?
    
    static func preferenceManager() -> AgentPreferenceManager? {
        if let manager = _preferenceManager {
            return manager
        }
        
        _preferenceManager = AgentPreferenceManager()
        
        return _preferenceManager
    }

    static func iotDeviceManager() -> IOTDeviceManager? {
        if let manager = _iotDeviceManager {
            return manager
        }
        
        _iotDeviceManager = IOTDeviceManager()
        
        return _iotDeviceManager
    }   
        
    static func iotPresetsManager() -> IOTPresetsManager? {
        if let manager = _iotPresetsManager {
            return manager
        }
        
        _iotPresetsManager = IOTPresetsManager()
        return _iotPresetsManager
    }
    
    static func loginManager() -> LoginManager? {
        if let manager = _loginManager {
            return manager
        }
        
        _loginManager = LoginManager()
        
        return _loginManager
    }
    
    static func destory() {
        _preferenceManager = nil
        _loginManager = nil
    }
    
    static var agentUid: Int {
        return 999
    }
    
    static var uid: Int {
        return Int(arc4random_uniform(90000000))
    }
}
