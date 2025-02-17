import UIKit
public class GradientBorderView: UIView {
    // MARK: - Properties
    private let borderWidth: CGFloat = 1.0
    private var displayLink: CADisplayLink?
    private var rotationAngle: CGFloat = 0
    
    private let colors: [CGColor] = [
        UIColor(red: 0, green: 0.76, blue: 1, alpha: 1).cgColor,  // #00C2FF
        UIColor(white: 1, alpha: 0.1).cgColor                      // #19FFFFFF
    ]
    
    private lazy var gradientPaint: CGGradient = {
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                         colors: colors as CFArray,
                         locations: nil)!
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .current, forMode: .common)
    }
        
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.saveGState()
        
        let colors = [
            UIColor(red: 0, green: 0.76, blue: 1, alpha: 1).cgColor,
            UIColor(white: 1, alpha: 0.1).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors as CFArray,
                                 locations: nil)!
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let gradientLength = sqrt(rect.width * rect.width + rect.height * rect.height)
        
        let startPoint = CGPoint(x: center.x + gradientLength * cos(rotationAngle),
                               y: center.y + gradientLength * sin(rotationAngle))
        let endPoint = CGPoint(x: center.x + gradientLength * cos(rotationAngle + .pi),
                             y: center.y + gradientLength * sin(rotationAngle + .pi))
        
        let borderRect = rect.insetBy(dx: borderWidth/2, dy: borderWidth/2)
        let path = UIBezierPath(roundedRect: borderRect, cornerRadius: rect.height / 2.0)
        
        context.setLineWidth(borderWidth)
        context.addPath(path.cgPath)
        context.replacePathWithStrokedPath()
        context.clip()
        
        context.drawLinearGradient(gradient,
                                 start: startPoint,
                                 end: endPoint,
                                 options: [])
        
        context.restoreGState()
    }

    @objc private func update() {
        rotationAngle += 0.05
        if rotationAngle >= .pi * 2 {
            rotationAngle = 0
        }
        setNeedsDisplay()
    }
        
    deinit {
        displayLink?.invalidate()
    }
}
