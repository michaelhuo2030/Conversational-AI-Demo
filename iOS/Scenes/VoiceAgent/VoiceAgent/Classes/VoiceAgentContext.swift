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
    
    public static func voiceAgentScene(viewController: UIViewController) {
        SVProgressHUD.setMaximumDismissTimeInterval(1)
        SVProgressHUD.setBackgroundColor(UIColor.themColor(named: "ai_mask1"))
        SVProgressHUD.setForegroundColor(.white)
        
        let vc = ChatViewController()
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
