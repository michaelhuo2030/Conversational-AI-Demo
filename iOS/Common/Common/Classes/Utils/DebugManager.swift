//
//  DebugManager.swift
//  Common
//
//  Created by qinhui on 2025/2/12.
//

import Foundation

public class DebugManager: NSObject {
    static let key = "TOOLBOXENV"
    
    public static func isDebugMode() -> Bool {
        let value = UserDefaults.standard.integer(forKey: key)
        return value == 1
    }
    
    public static func openDebugMode() {
        UserDefaults.standard.setValue(1, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    public static func closeDebugMode() {
        UserDefaults.standard.setValue(0, forKey: key)
        UserDefaults.standard.synchronize()
    }
}
