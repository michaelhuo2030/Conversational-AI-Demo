//
//  UIImage+Bundle.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import Foundation

public extension UIImage {
    static func ag_named(_ name: String) -> UIImage? {
        return ResourceManager.image(named: name, bundleName: "Common")
    }
}
