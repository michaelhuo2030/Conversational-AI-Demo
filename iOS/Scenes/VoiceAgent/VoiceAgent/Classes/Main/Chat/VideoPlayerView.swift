import UIKit
import AVFoundation

class VideoPlayerView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var sizeAnimator: CAAnimationGroup?
    private var isPendingStop = false
    private var currentVolume: Float = 0
    
    // 视频容器视图
    private let videoCardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupPlayer()
    }
    
    private func setupView() {
        addSubview(videoCardView)
        videoCardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoCardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            videoCardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            videoCardView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            videoCardView.heightAnchor.constraint(equalTo: videoCardView.widthAnchor)
        ])
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "ball_small_video", withExtension: "mov") else { return }
        
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            videoCardView.layer.addSublayer(playerLayer)
            playerLayer.frame = videoCardView.bounds
        }
        
        // 设置循环播放
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                             object: player?.currentItem,
                                             queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = videoCardView.bounds
    }
    
    // 根据音量更新动画
    func updateWithVolume(_ volume: Float) {
        currentVolume = volume
        if volume > 50 {
            startAgentSpeaker()
        } else {
            stopAgentSpeaker()
        }
    }
    
    private func startAgentSpeaker() {
        if sizeAnimator != nil {
            isPendingStop = false
            return
        }
        
        isPendingStop = false
        startSizeAnimation()
    }
    
    private func stopAgentSpeaker() {
        isPendingStop = true
    }
    
    private func startSizeAnimation() {
        // 根据音量计算缩放范围
        let minScale: CGFloat = {
            switch currentVolume {
            case 200...: return 0.9
            case 150...: return 0.92
            case 100...: return 0.94
            case 50...: return 0.96
            default: return 0.96
            }
        }()
        
        // 根据音量调整动画速度
        let baseDuration: CFTimeInterval = {
            switch currentVolume {
            case 200...: return 0.25
            case 150...: return 0.3
            case 100...: return 0.35
            case 50...: return 0.4
            default: return 0.45
            }
        }()
        
        // 创建缩放动画
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1.0
        scaleDown.toValue = minScale
        scaleDown.duration = baseDuration
        scaleDown.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let scaleUp1 = CABasicAnimation(keyPath: "transform.scale")
        scaleUp1.fromValue = minScale
        scaleUp1.toValue = minScale + 0.03
        scaleUp1.duration = baseDuration / 3
        scaleUp1.timingFunction = CAMediaTimingFunction(name: .easeIn)
        scaleUp1.beginTime = baseDuration
        
        let scaleDown2 = CABasicAnimation(keyPath: "transform.scale")
        scaleDown2.fromValue = minScale + 0.03
        scaleDown2.toValue = minScale
        scaleDown2.duration = baseDuration / 3
        scaleDown2.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleDown2.beginTime = baseDuration + baseDuration / 3
        
        let scaleUp2 = CABasicAnimation(keyPath: "transform.scale")
        scaleUp2.fromValue = minScale
        scaleUp2.toValue = 1.0
        scaleUp2.duration = baseDuration
        scaleUp2.timingFunction = CAMediaTimingFunction(name: .easeIn)
        scaleUp2.beginTime = baseDuration + (2 * baseDuration / 3)
        
        let group = CAAnimationGroup()
        group.animations = [scaleDown, scaleUp1, scaleDown2, scaleUp2]
        group.duration = baseDuration * 2.5
        group.delegate = self
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        
        sizeAnimator = group
        videoCardView.layer.add(group, forKey: "sizeAnimation")
        
        // 调整视频播放速度
        player?.rate = 1.5
    }
}

extension VideoPlayerView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag && !isPendingStop {
            startSizeAnimation()
        } else {
            videoCardView.layer.removeAllAnimations()
            sizeAnimator = nil
            isPendingStop = false
            player?.rate = 0.6
        }
    }
}
