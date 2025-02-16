//
//  ToastView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/10.
//

import UIKit
import Common
import Kingfisher

class TextContentView: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .white
        label.text = ResourceManager.L10n.Join.agentConnecting
        label.textColor = UIColor.themColor(named: "ai_red6")
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .black

        self.addSubview(textLabel)
        
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ImageContentView: UIView {
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        if let bundlePath = Bundle.main.path(forResource: VoiceAgentEntrance.kSceneName, ofType: "bundle"),
           let bundle = Bundle(path: bundlePath),
           let gifPath = bundle.path(forResource: "agent_connecting", ofType: "gif") {
            let gifURL = URL(fileURLWithPath: gifPath)
            view.kf.setImage(with: gifURL)
        }
        return view
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = .white
        label.text = ResourceManager.L10n.Join.agentConnecting
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(imageView)
        self.addSubview(textLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        textLabel.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ToastView: UIView {
    private lazy var imageToast: ImageContentView = {
        let view = ImageContentView()
        return view
    }()
    
    private lazy var textToast: TextContentView = {
        let view = TextContentView()
        view.layer.cornerRadius = 40 / 2.0
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()
    
    func showLoading() {
        self.isHidden = false
        imageToast.isHidden = false
        textToast.isHidden = true
    }
    
    func showToast(text: String) {
        self.isHidden = false
        textToast.textLabel.text = text
        textToast.isHidden = false
        imageToast.isHidden = true
    }
    
    func dismiss() {
        self.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(textToast)
        self.addSubview(imageToast)
        imageToast.snp.makeConstraints { make in
            make.width.equalTo(111)
            make.height.equalTo(40)
            make.center.equalTo(self)
        }
        
        textToast.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.center.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
