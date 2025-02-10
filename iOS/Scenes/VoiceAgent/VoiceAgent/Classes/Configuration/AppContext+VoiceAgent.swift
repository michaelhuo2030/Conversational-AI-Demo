//
//  AppContext.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import Foundation
import Common

public class AgentLogger: NSObject {
    public static let kLogKey = "agent"
    
    public static func info(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).info(text, context: context)
        }
    }

    public static func warn(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).warning(text, context: context)
        }
    }

    public static func error(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).error(text, context: context)
        }
    }
}

extension AppContext {
    static private var _preferenceManager: AgentPreferenceManager?
    
    static func preferenceManager() -> AgentPreferenceManager? {
        if let manager = _preferenceManager {
            return manager
        }
        
        _preferenceManager = AgentPreferenceManager()
        
        return _preferenceManager
    }
    
    static func destory() {
        _preferenceManager = nil
    }
    
    static var agentUid: Int {
        return Int(arc4random_uniform(10000000))
    }
    
    static var uid: Int {
        return Int(arc4random_uniform(90000000))
    }
}
