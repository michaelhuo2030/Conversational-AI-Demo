//
//  AgentSettingBar.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentSettingBar: UIView {
    // MARK: - Callbacks
    var onBackButtonTapped: (() -> Void)?
    var onTipsButtonTapped: (() -> Void)?
    var onSettingButtonTapped: (() -> Void)?
    var onNetworkStatusChanged: (() -> Void)?
    
    private let signalBarCount = 5
    private var signalBars: [UIView] = []
    
    lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.va_named("ic_agora_back"), for: .normal)
        button.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.title
        label.font = .systemFont(ofSize: 16)
        label.textColor = PrimaryColors.c_b3b3b3
        return label
    }()
    
    private let tipsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.va_named("ic_agent_tips_icon"), for: .normal)
        return button
    }()
    
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.va_named("ic_agent_setting"), for: .normal)
        button.addTarget(self, action: #selector(settingButtonClicked), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        tipsButton.addTarget(self, action: #selector(tipsButtonClicked), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        [backButton, titleLabel, tipsButton, settingButton].forEach { addSubview($0) }
    }
    
    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        
        settingButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        tipsButton.snp.remakeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
    }
    
    // MARK: - Actions
    @objc func backEvent() {
        onBackButtonTapped?()
    }
    
    @objc private func tipsButtonClicked() {
        onTipsButtonTapped?()
    }
    
    @objc private func settingButtonClicked() {
        onSettingButtonTapped?()
    }
}
