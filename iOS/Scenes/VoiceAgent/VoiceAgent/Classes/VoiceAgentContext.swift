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
public class VoiceAgentContext: NSObject {
    public static let kSceneName = "VoiceAgent"
    
    public static func preLoadPreset() {
        let agentManager = AgentManager(host: AppContext.shared.baseServerUrl)
        agentManager.fetchAgentPresets { error, result in
            if error != nil {
                return
            }
            
            guard let result = result else {
                return
            }
            
            AgentPreferenceManager.shared.setPresets(presets: result)
        }
    }
    
    public static func voiceAgentScene(viewController: UIViewController) {
//        let vc = PreparedToStartViewController()
//        vc.showMineContent = false
//        viewController.navigationController?.pushViewController(vc, animated: true)
        SVProgressHUD.setMaximumDismissTimeInterval(1)
        let vc = ChatViewController()
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
