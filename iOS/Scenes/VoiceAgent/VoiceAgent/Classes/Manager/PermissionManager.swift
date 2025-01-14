//
//  PermissionHelper.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/29.
//

import UIKit
import AVFAudio

///This class is used to request system permissions.
class PermissionManager: NSObject {
    typealias MicrophonePermissionHandler = (Bool) -> Void

    static func checkMicrophonePermission(completion: @escaping MicrophonePermissionHandler) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            // The user has authorized
            completion(true)
        case .undetermined:
            // The user has not made a choice to apply for permission.
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied:
            // The user rejected the permission.
            completion(false)
        @unknown default:
            fatalError("Unknown permission status")
        }
    }

    
}
