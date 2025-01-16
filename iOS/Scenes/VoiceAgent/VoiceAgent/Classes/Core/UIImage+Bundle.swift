//
//  UIImage+Bundle.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import Foundation
import Common

public extension UIImage {
    static func va_named(_ name: String) -> UIImage? {
        return ResourceManager.image(named: name, bundleName: VoiceAgentContext.kSceneName)
    }
}
