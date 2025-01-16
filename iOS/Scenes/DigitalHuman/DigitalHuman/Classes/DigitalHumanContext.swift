//
//  VoiceAgentContext.swift
//  VoiceAgent-VoiceAgent
//
//  Created by qinhui on 2024/12/10.
//

import UIKit


@objcMembers
public class DigitalHumanContext: NSObject {
    public static let kSceneName = "DigitalHuman"

    public static func digitalHumanAgentScene(viewController: UIViewController) {
        let vc = DigitalHumanViewController()
        viewController.navigationController?.pushViewController(vc)
    }
    
}
