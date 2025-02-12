//
//  ToastView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/10.
//

import UIKit
import Common
import Kingfisher

class ToastView: UIView {
    
    private let imageView = UIImageView()
    
    lazy var content: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .white
        label.text = ResourceManager.L10n.Join.agentConnecting
        return label
    }()
    
    func showLoading() {
        content.text = ResourceManager.L10n.Join.agentConnecting
        content.textColor = .white
        self.isHidden = false
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
    
    func showToast(text: String) {
        content.text = text
        content.textColor = UIColor.themColor(named: "ai_icontext1")
        self.isHidden = false
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
    
    func dismiss() {
        self.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let bundlePath = Bundle.main.path(forResource: VoiceAgentContext.kSceneName, ofType: "bundle"),
           let bundle = Bundle(path: bundlePath),
           let gifPath = bundle.path(forResource: "agent_connecting", ofType: "gif") {
            let gifURL = URL(fileURLWithPath: gifPath)
            imageView.kf.setImage(with: gifURL)
        }
        
        self.addSubview(content)
        
        content.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerY.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
