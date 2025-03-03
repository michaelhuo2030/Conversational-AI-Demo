//
//  ResourceManager.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import Foundation

public class ResourceManager {
    private static func getBundle(bundleName: String?) -> Bundle {
        let mainBundle = Bundle(for: ResourceManager.self)
        
        if let bundleName = bundleName,
           let resourceBundlePath = mainBundle.path(forResource: bundleName, ofType: "bundle"),
           let bundle = Bundle(path: resourceBundlePath) {
            return bundle
        }
        
        print("Warning: Falling back to main bundle")
        return mainBundle
    }
    
    public static func image(named: String, bundleName: String?) -> UIImage? {
        let resourceBundle = (bundleName != nil) ? getBundle(bundleName: bundleName) : Bundle.main
        return UIImage(named: named, in: resourceBundle, compatibleWith: nil)
    }
    
    public static func localizedString(_ key: String, bundleName: String?) -> String {
        let resourceBundle = (bundleName != nil) ? getBundle(bundleName: bundleName) : Bundle.main
        
        let localeIdentifier = "zh-Hans"

        guard let bundlePath = resourceBundle.path(forResource: localeIdentifier, ofType: "lproj"),
              let localizedBundle = Bundle(path: bundlePath)
        else {
            return key
        }
        
        return localizedBundle.localizedString(forKey: key, value: nil, table: nil)
    }
}


