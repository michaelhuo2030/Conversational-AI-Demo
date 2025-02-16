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
        button.setImage(UIImage.ag_named("ic_agora_back"), for: .normal)
        button.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.title
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.themColor(named: "ai_icontext2")
        return label
    }()
    
    private let tipsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_agent_tips_icon"), for: .normal)
        return button
    }()
    
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_agent_setting"), for: .normal)
        button.addTarget(self, action: #selector(settingButtonClicked), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerDelegate()
        setupViews()
        setupConstraints()
        tipsButton.addTarget(self, action: #selector(tipsButtonClicked), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unregisterDelegate()
    }
    
    // MARK: - Private Methods
    
    func registerDelegate() {
        if let manager = AppContext.preferenceManager() {
            manager.addDelegate(self)
        }
    }
    
    func unregisterDelegate() {
        if let manager = AppContext.preferenceManager() {
            manager.removeDelegate(self)
        }
    }
    
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

extension AgentSettingBar: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {
        let roomState = manager.information.rtcRoomState
        if roomState == .unload {
            return
        }
        
        var imageName = "ic_agent_tips_icon"
        switch networkState {
        case .good:
            imageName = "ic_agent_tips_icon"
            break
        case .fair:
            imageName = "ic_agent_tips_icon_yellow"
            break
        case .poor:
            imageName = "ic_agent_tips_icon_red"
            break
        }
        
        tipsButton.setImage(UIImage.ag_named(imageName), for: .normal)
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus) {
        if roomState == .unload {
            tipsButton.setImage(UIImage.ag_named("ic_agent_tips_icon"), for: .normal)
        }
    }
}
