//
//  VoiceAgentContext.swift
//  VoiceAgent-VoiceAgent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit


@objcMembers
public class VoiceAgentContext: NSObject {
    public static let kSceneName = "VoiceAgent"

    public static func voiceAgentScene(viewController: UIViewController) {
        let vc = PreparedToStartViewController()
        vc.showMineContent = false
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
