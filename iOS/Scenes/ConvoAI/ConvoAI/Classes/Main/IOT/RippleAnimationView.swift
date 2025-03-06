import UIKit

class RippleAnimationView: UIView {
    
    // 表示涟漪数量(原图层加复制图层)
    private static let rippleCount: Int = 3
    
    // 涟漪间隔时间
    private static let rippleDuration: Double = 0.5  // 缩短间隔，使三波更紧凑
    
    // 表示单次动画持续时间
    private static let animationDuration: Double = 2.5
    
    // 动画暂停时间
    private static let pauseDuration: Double = 4.0
    
    // 渐入渐出时间（占总动画时间的比例）
    private static let fadeRatio: Double = 0.2
    
    // 缩放因子
    var scaleFactor: CGFloat = 3.2  // 从1.6增加到6.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        
        // 添加复制图层
        self.layer.addSublayer(createReplicatorLayer(frame: frame))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // 创建复制图层
    private func createReplicatorLayer(frame: CGRect) -> CAReplicatorLayer {
        let replicatorLayer = CAReplicatorLayer()
        replicatorLayer.instanceCount = RippleAnimationView.rippleCount
        replicatorLayer.instanceDelay = RippleAnimationView.rippleDuration
        
        replicatorLayer.addSublayer(createRippleLayer(rect: frame))
        return replicatorLayer
    }
    
    // 创建基础动画图层
    private func createRippleLayer(rect: CGRect) -> CALayer {
        let rippleLayer = CALayer()
        
        rippleLayer.frame = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        rippleLayer.cornerRadius = rect.size.height / 2
        
        // 添加组合动画
        let groupAnimation = createGroupAnimation()
        rippleLayer.add(groupAnimation, forKey: "rippleAnimation")
        
        return rippleLayer
    }
    
    // 缩放动画
    private func createScaleAnimation() -> CABasicAnimation {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.2
        scaleAnimation.toValue = scaleFactor
        
        // 添加缓动效果
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        return scaleAnimation
    }
    
    // 背景颜色变化动画
    private func createColorAnimation() -> CAKeyframeAnimation {
        let colorAnimation = CAKeyframeAnimation(keyPath: "backgroundColor")
        
        // 使用 #446CFF 颜色
        let baseColor = UIColor(red: 68/255.0, green: 108/255.0, blue: 255/255.0, alpha: 1.0)
        
        colorAnimation.values = [
            baseColor.withAlphaComponent(1.0).cgColor,
            baseColor.withAlphaComponent(0.5).cgColor,
            baseColor.withAlphaComponent(0.0).cgColor
        ]
        colorAnimation.keyTimes = [0.0, 0.5, 1.0] as [NSNumber]
        
        // 添加缓动效果
        colorAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        return colorAnimation
    }
    
    // 创建不透明度动画（渐入渐出效果）
    private func createOpacityAnimation() -> CAKeyframeAnimation {
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        
        // 计算渐入渐出的时间点
        let fadeTime = RippleAnimationView.fadeRatio
        
        // 设置关键帧值和时间点
        opacityAnimation.values = [0.0, 1.0, 1.0, 0.0]
        opacityAnimation.keyTimes = [0.0, fadeTime, 1.0 - fadeTime, 1.0] as [NSNumber]
        
        // 添加缓动效果
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        return opacityAnimation
    }
    
    // 创建组合动画（包含暂停效果和渐入渐出）
    private func createGroupAnimation() -> CAAnimationGroup {
        // 创建动画组
        let group = CAAnimationGroup()
        
        // 设置动画
        group.animations = [
            createScaleAnimation(),
            createColorAnimation(),
            createOpacityAnimation()
        ]
        
        // 设置关键时间点
        let animationPeriod = RippleAnimationView.animationDuration
        let pausePeriod = RippleAnimationView.pauseDuration
        let totalDuration = animationPeriod + pausePeriod
        
        // 设置动画持续时间为总周期
        group.duration = totalDuration
        
        // 设置动画的活跃时间比例
        let activeRatio = animationPeriod / totalDuration
        
        // 使用媒体时间设置，让动画只在总时间的前一部分活跃
        group.speed = Float(1.0 / activeRatio)
        group.timeOffset = 0
        
        // 设置重复
        group.repeatCount = .infinity
        
        // 确保动画完成后被移除
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        
        return group
    }
    
    // 添加波纹效果（可选）
    func addWaveEffect() {
        // 创建波纹图层
        let waveLayer = CAShapeLayer()
        waveLayer.frame = bounds
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.strokeColor = UIColor(red: 68/255.0, green: 108/255.0, blue: 255/255.0, alpha: 0.3).cgColor
        waveLayer.lineWidth = 1.0
        
        // 创建波纹路径
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.width/2, y: bounds.height/2),
                               radius: bounds.width/2 * 0.8,
                               startAngle: 0,
                               endAngle: 2 * .pi,
                               clockwise: true)
        waveLayer.path = path.cgPath
        
        // 添加到视图
        layer.addSublayer(waveLayer)
        
        // 创建波纹动画
        let waveAnimation = CABasicAnimation(keyPath: "transform.scale")
        waveAnimation.fromValue = 0.9
        waveAnimation.toValue = 1.1
        waveAnimation.duration = 2.0
        waveAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        waveAnimation.repeatCount = .infinity
        waveAnimation.autoreverses = true
        
        // 添加动画
        waveLayer.add(waveAnimation, forKey: "waveAnimation")
    }
}
