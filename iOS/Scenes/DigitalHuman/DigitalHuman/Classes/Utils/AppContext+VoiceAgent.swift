//
//  AppContext.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import Foundation
import Common

class AgentLogger: NSObject {
    static let kLogKey = DigitalHumanContext.kSceneName
    
    static func info(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).info(text, context: context)
        }
    }

    static func warn(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).warning(text, context: context)
        }
    }

    static func error(_ text: String, context: String? = nil) {
        agoraDoMainThreadTask {
            AgoraEntLog.getSceneLogger(with: kLogKey).error(text, context: context)
        }
    }
}

extension AppContext {
    static var agentUid: Int {
        return Int(arc4random_uniform(10000000))
    }
    
    static var uid: Int {
        return Int(arc4random_uniform(90000000))
    }
}
