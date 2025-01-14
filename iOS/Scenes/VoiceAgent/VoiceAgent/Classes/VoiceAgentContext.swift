//
//  VoiceAgentContext.swift
//  VoiceAgent-VoiceAgent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit

let kSceneName = "VoiceAgent"

@objcMembers
public class VoiceAgentContext: NSObject {
    public static func voiceAgentScene(viewController: UIViewController) {
        let vc = AgentHomeViewController()
        vc.hidesBottomBarWhenPushed = true
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    public static func voiceAgentHomePage() -> UIViewController {
        return AgentHomeViewController()
    }
}
