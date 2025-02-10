import UIKit
import AVFoundation
import AgoraRtcKit

enum AgentState {
    case idel
    case listening
    case speaking
}

class AnimateView: NSObject {
    private struct VolumeConstants {
        static let minVolume: Int = 0
        static let maxVolume: Int = 255
        static let highVolume: Int = 200
        static let mediumVolume: Int = 120
        static let lowVolume: Int = 80
    }
    
    private struct ScaleConstants {
        static let scaleHigh: Float = 1.1
        static let scaleMedium: Float = 1.06
        static let scaleLow: Float = 1.04
    }
    
    private struct AnimationConstants {
        static let durationHigh: TimeInterval = 0.4
        static let durationMedium: TimeInterval = 0.5
        static let durationLow: TimeInterval = 0.6
        static let bounceScale: Float = 0.02
        static let videoFileName = "ball_small_video.mov"
    }
    
    private let videoView: UIView
    private weak var rtcMediaPlayer: AgoraRtcMediaPlayerProtocol?
    private var scaleAnimator: CAAnimationGroup?
    private var currentAnimParams = AnimParams()
    private var pendingAnimParams: AnimParams?
    
    private var currentState: AgentState = .idel {
        didSet {
            if oldValue != currentState {
                switch currentState {
                case .idel:
                    rtcMediaPlayer?.setPlaybackSpeed(50)
                case .listening:
                    rtcMediaPlayer?.setPlaybackSpeed(100)
                case .speaking:
                    rtcMediaPlayer?.setPlaybackSpeed(200)
                }
            }
        }
    }
    
    private struct AnimParams {
        var minScale: Float = 1.0
        var duration: TimeInterval = 0.2
    }
    
    init(videoView: UIView) {
        self.videoView = videoView
    }
    
    func setupMediaPlayer(_ rtcEngine: AgoraRtcEngineKit) {
        createMediaPlayer(rtcEngine)
    }
    
    private func createMediaPlayer(_ rtcEngine: AgoraRtcEngineKit) {
        rtcMediaPlayer = rtcEngine.createMediaPlayer(with: nil)
        if let player = rtcMediaPlayer {
            player.setView(videoView)
            player.mute(true)
            player.setPlaybackSpeed(50)
            
            if let filePath = Bundle.main.path(forResource: AnimationConstants.videoFileName, ofType: nil) {
                let source = AgoraMediaSource()
                source.url = filePath
                source.autoPlay = true
                player.setLoopCount(-1)
                player.open(with: source)
            }
        }
    }
    
    func updateAgentState(_ newState: AgentState, volume: Int = 0) {
        let oldState = currentState
        currentState = newState
        handleStateTransition(oldState: oldState, newState: newState, volume: volume)
    }
    
    private func handleStateTransition(oldState: AgentState, newState: AgentState, volume: Int = 0) {
        switch newState {
        case .idel:
            break
        case .listening, .speaking:
            if newState == .speaking {
                startAgentAnimation(volume)
            }
        }
    }
    
    private func startAgentAnimation(_ currentVolume: Int) {
        let safeVolume = min(max(currentVolume, VolumeConstants.minVolume), VolumeConstants.maxVolume)
        let newParams = AnimParams(
            minScale: calculateMinScale(safeVolume),
            duration: calculateDuration(safeVolume)
        )
        
        if newParams.minScale == currentAnimParams.minScale && scaleAnimator != nil {
            return
        }
        
        pendingAnimParams = newParams
        
        if scaleAnimator != nil {
            return
        }
        
        startNewAnimation(newParams)
        pendingAnimParams = nil
    }
    
    private func calculateMinScale(_ volume: Int) -> Float {
        switch volume {
        case VolumeConstants.highVolume...: return ScaleConstants.scaleHigh
        case VolumeConstants.mediumVolume...: return ScaleConstants.scaleMedium
        case VolumeConstants.lowVolume...: return ScaleConstants.scaleLow
        default: return ScaleConstants.scaleLow
        }
    }
    
    private func calculateDuration(_ volume: Int) -> TimeInterval {
        switch volume {
        case VolumeConstants.highVolume...: return AnimationConstants.durationHigh
        case VolumeConstants.mediumVolume...: return AnimationConstants.durationMedium
        case VolumeConstants.lowVolume...: return AnimationConstants.durationLow
        default: return AnimationConstants.durationLow
        }
    }
    
    private func startNewAnimation(_ params: AnimParams) {
        currentAnimParams = params
        
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1.0
        scaleDown.toValue = params.minScale
        scaleDown.duration = params.duration
        scaleDown.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let scaleUp1 = CABasicAnimation(keyPath: "transform.scale")
        scaleUp1.fromValue = params.minScale
        scaleUp1.toValue = params.minScale + AnimationConstants.bounceScale
        scaleUp1.duration = params.duration / 3
        scaleUp1.beginTime = params.duration
        scaleUp1.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        let scaleDown2 = CABasicAnimation(keyPath: "transform.scale")
        scaleDown2.fromValue = params.minScale + AnimationConstants.bounceScale
        scaleDown2.toValue = params.minScale
        scaleDown2.duration = params.duration / 3
        scaleDown2.beginTime = params.duration + params.duration / 3
        scaleDown2.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let scaleUp2 = CABasicAnimation(keyPath: "transform.scale")
        scaleUp2.fromValue = params.minScale
        scaleUp2.toValue = 1.0
        scaleUp2.duration = params.duration
        scaleUp2.beginTime = params.duration + (2 * params.duration / 3)
        scaleUp2.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        let group = CAAnimationGroup()
        group.animations = [scaleDown, scaleUp1, scaleDown2, scaleUp2]
        group.duration = params.duration * 2.5
        group.delegate = self
        group.repeatCount = .infinity
        
        scaleAnimator = group
        videoView.layer.add(group, forKey: "sizeAnimation")
    }
    
    private func updateParentScale(_ scale: Float) {
        if let parentView = videoView.superview {
            parentView.transform = CGAffineTransform(scaleX: CGFloat(scale), y: CGFloat(scale))
        }
    }
    
    func release() {
        rtcMediaPlayer?.stop()
        rtcMediaPlayer = nil
        
        scaleAnimator = nil
        videoView.layer.removeAllAnimations()
        currentState = .idel
    }
}

extension AnimateView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && currentState == .speaking {
            if let params = pendingAnimParams {
                startNewAnimation(params)
                pendingAnimParams = nil
            }
        } else {
            videoView.layer.removeAllAnimations()
            scaleAnimator = nil
            updateParentScale(1.0)
        }
    }
}
