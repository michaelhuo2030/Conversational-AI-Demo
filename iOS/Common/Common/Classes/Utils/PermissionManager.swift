//
//  PermissionHelper.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/29.
//

import UIKit
import AVFAudio
import AVFoundation

/// This class is used to request system permissions.
public class PermissionManager: NSObject {
    public typealias MicrophonePermissionHandler = (Bool) -> Void
    public typealias CameraPermissionHandler = (Bool) -> Void
    public typealias BothPermissionsHandler = (Bool, Bool) -> Void

    public static func getMicrophonePermission() -> AVAudioSession.RecordPermission {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.recordPermission
    }
    
    public static func checkMicrophonePermission(completion: @escaping MicrophonePermissionHandler) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            // User has granted microphone permission
            completion(true)
        case .undetermined:
            // User hasn't made a choice yet, request permission
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied:
            // User has denied microphone permission
            completion(false)
        @unknown default:
            fatalError("Unknown permission status")
        }
    }

    public static func checkCameraPermission(completion: @escaping CameraPermissionHandler) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            // User has granted camera permission
            completion(true)
        case .notDetermined:
            // User hasn't made a choice yet, request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            // User has denied or restricted camera permission
            completion(false)
        @unknown default:
            fatalError("Unknown permission status")
        }
    }

    public static func checkBothMediaPermissions(completion: @escaping BothPermissionsHandler) {
        checkMicrophonePermission { micGranted in
            checkCameraPermission { cameraGranted in
                DispatchQueue.main.async {
                    completion(micGranted, cameraGranted)
                }
            }
        }
    }
}
