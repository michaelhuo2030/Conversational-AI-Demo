//
//  AgentSettingTopView.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentSettingTopView: UIView {
    private let leftTitleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    private let centerImageView = UIImageView()
    private let line = UIView()
    
    var onCloseButtonTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createViews()
        createConstrains()
    }
    
    private func createViews() {
        backgroundColor = UIColor.themColor(named: "ai_fill2")
        
        leftTitleLabel.textColor = .white
        leftTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        addSubview(leftTitleLabel)
        
        closeButton.setImage(UIImage.ag_named("ic_agent_setting_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose(_:)), for: .touchUpInside)
        addSubview(closeButton)
        
        centerImageView.image = UIImage.ag_named("ic_setting_bar_icon")
        centerImageView.contentMode = .scaleAspectFit
        addSubview(centerImageView)
        
        line.backgroundColor = UIColor.themColor(named: "ai_line1")
        addSubview(line)
    }
    
    private func createConstrains() {
        leftTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.right.equalTo(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        centerImageView.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }
        
        line.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(1.0)
        }
    }
    
    public func setTitle(title: String) {
        leftTitleLabel.text = title
    }
    
    @objc private func onClickClose(_ sender: UIButton) {
        onCloseButtonTapped?()
    }
}
