//
//  TypewriterLabel.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/25.
//

import UIKit

class TypewriterLabel: UILabel {
    // 文本内容
    private var text1 = "你好，欢迎体验声网对话式 AI 引擎"
    private var text2 = "秒应智答，零滞畅聊"
    private let cursor = "●"
    
    // 动画参数
    private let speed: Double = 12 // 每秒字符数
    private let pauseTime1: Double = 0.5 // 第一次停顿时间
    private let pauseTime2: Double = 1.5 // 第二次停顿时间
    private let blinkSpeed: Double = 1 // 光标闪烁速度
    
    // 动画控制
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    
    // 计算时间
    private var typeTime1: Double { Double(text1.count) / speed }
    private var typeTime2: Double { Double(text2.count) / speed }
    private var deleteTime1: Double { Double(text1.count) / speed }
    private var deleteTime2: Double { Double(text2.count) / speed }
    private var totalTime: Double {
        typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 +
        typeTime2 + pauseTime2 + deleteTime2 + pauseTime1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        textAlignment = .center
        numberOfLines = 0
    }
    
    func startAnimation() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .current, forMode: .common)
    }
    
    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func update() {
        let currentTime = CACurrentMediaTime() - startTime
        let cycleTime = currentTime.truncatingRemainder(dividingBy: totalTime)
        
        var visibleText = ""
        
        // 第一次打字
        if cycleTime < typeTime1 {
            let charCount = Int(cycleTime * speed)
            visibleText = String(text1.prefix(charCount))
        }
        // 第一次打字后的停顿
        else if cycleTime < typeTime1 + pauseTime2 {
            visibleText = text1
        }
        // 第一次删除
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 {
            let charCount = text1.count - Int((cycleTime - typeTime1 - pauseTime2) * speed)
            visibleText = String(text1.prefix(max(0, charCount)))
        }
        // 第一次删除后的停顿
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 {
            visibleText = ""
        }
        // 第二次打字
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 {
            let charCount = Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1) * speed)
            visibleText = String(text2.prefix(charCount))
        }
        // 第二次打字后的停顿
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 {
            visibleText = text2
        }
        // 第二次删除
        else if cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2 {
            let charCount = text2.count - Int((cycleTime - typeTime1 - pauseTime2 - deleteTime1 - pauseTime1 - typeTime2 - pauseTime2) * speed)
            visibleText = String(text2.prefix(max(0, charCount)))
        }
        
        // 添加光标
        if cycleTime < typeTime1 ||
            (cycleTime >= typeTime1 && cycleTime < typeTime1 + pauseTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2) ||
            (cycleTime >= typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 && cycleTime < typeTime1 + pauseTime2 + deleteTime1 + pauseTime1 + typeTime2 + pauseTime2 + deleteTime2) {
            
            let isVisible = sin(currentTime * .pi * 2 * blinkSpeed) >= 0
            if isVisible {
                visibleText += cursor
            }
        }
        
        text = visibleText
    }
    
    deinit {
        stopAnimation()
    }
}