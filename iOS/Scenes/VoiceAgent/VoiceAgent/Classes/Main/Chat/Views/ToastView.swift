//
//  ToastView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/10.
//

import UIKit
import Common

class ToastView: UIView {
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
        content.textColor = PrimaryColors.c_e6544b
        self.isHidden = false
        self.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
    }
    
    func dismiss() {
        self.isHidden = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
