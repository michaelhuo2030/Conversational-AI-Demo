//
//  AgoraWaveGroupView.swift
//  TestWave
//
//  Created by agora on 2024/9/30.
//

import UIKit

class AgoraWaveView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShadow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShadow()
    }
    
    private func setupShadow() {
        //add shadow
        layer.shadowColor = UIColor.cyan.cgColor
        layer.shadowOpacity = 0
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.masksToBounds = false
    }
}

class AgoraWaveGroupView: UIView {
    private var count: Int
    private var padding: CGFloat
    private var waveViews: [AgoraWaveView] = []
    var waveColor: UIColor = .white {
        didSet {
            //update wave background color
            waveViews.forEach{ view in
                view.backgroundColor = waveColor
            }
        }
    }
    
    required init(frame: CGRect, count: Int, padding: CGFloat) {
        self.count = count
        self.padding = padding
        super.init(frame: frame)
        
        var x: CGFloat = 0
        let w = (self.frame.size.width - padding * CGFloat(count - 1)) / CGFloat(count)
        let h = w * 1.2
        //create wave views
        waveViews = (0..<count).map { _ in
            let rect = CGRect(x: x, y: (self.frame.size.height - h) / 2, width: w, height: h)
            let view = AgoraWaveView(frame: rect)
            view.layer.cornerRadius = view.frame.size.width / 2
            x += w + padding
            view.backgroundColor = waveColor
            self.addSubview(view)
            return view
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateAnimation(duration: TimeInterval, heights: [CGFloat]) {
        //update wave view frame
        UIView.animate(withDuration: duration) {
            self.waveViews.enumerated().forEach { (index, view) in
                let height = heights[index]
                view.frame = CGRect(x: view.frame.origin.x, y: (self.frame.size.height - height) / 2, width: view.frame.size.width, height: height)
            }
        }
    }
    
    func getWaveWidth() -> CGFloat{
        return waveViews.first?.frame.size.width ?? 0
    }
}
