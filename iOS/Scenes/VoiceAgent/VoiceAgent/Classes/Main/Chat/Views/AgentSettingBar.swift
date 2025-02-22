//
//  AgentSettingBar.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentSettingBar: UIView {
    
    let infoListButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.ag_named("ic_agent_info_list")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.themColor(named: "ai_icontext1")
        return button
    }()
    
    private lazy var centerTipsLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.tips
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    let netStateView = UIView()
    private let netTrackView = UIImageView(image: UIImage.ag_named("ic_agent_net_4"))
    private let netRenderView = UIImageView(image: UIImage.ag_named("ic_agent_net_3"))
    
    let settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_agent_setting"), for: .normal)
        return button
    }()
    
    private let centerTitleView = UIView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerDelegate()
        setupViews()
        setupConstraints()
        updateNetWorkView()
        
        startFlippingAnimation()
        
        tempView = centerTitleView
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
    
    func startFlippingAnimation() {
        Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(flipViews), userInfo: nil, repeats: true)
    }
    
    var tempView: UIView?
    @objc func flipViews() {
        guard let view = tempView else {
            return
        }
        // 开始动画
        UIView.animate(withDuration: 1.0, animations: {
            self.centerTitleView.snp.updateConstraints { make in
                make.bottom.equalTo(self.snp.top)
            }
            self.centerTipsLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
        }) { _ in
            
        }
    }
    
    private func updateNetWorkView() {
        guard let manager = AppContext.preferenceManager() else {
            return
        }
        let roomState = manager.information.rtcRoomState
        if (roomState == .unload) {
            netStateView.isHidden = true
        } else if (roomState == .connected) {
            netStateView.isHidden = false
            netTrackView.isHidden = false
            netRenderView.isHidden = false
            netTrackView.image = UIImage.ag_named("ic_agent_net_0")
            let netState = manager.information.networkState
            var imageName = "ic_agent_net_1"
            switch netState {
            case .good:
                imageName = "ic_agent_net_3"
                break
            case .fair:
                imageName = "ic_agent_net_2"
                break
            case .poor:
                imageName = "ic_agent_net_1"
                break
            }
            netRenderView.image = UIImage.ag_named(imageName)
        } else {
            netStateView.isHidden = false
            netTrackView.isHidden = false
            netRenderView.isHidden = true
            netTrackView.image = UIImage.ag_named("ic_agent_net_4")
        }
    }
    
    private func setupViews() {
        [infoListButton, centerTipsLabel, centerTitleView, netStateView, settingButton].forEach { addSubview($0) }
        [netTrackView, netRenderView].forEach { netStateView.addSubview($0) }
        
        let titleImageView = UIImageView()
        titleImageView.image = UIImage.ag_named("ic_agent_detail_logo")
        centerTitleView.addSubview(titleImageView)
        titleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let titleLabel = UILabel()
        titleLabel.text = ResourceManager.L10n.Join.title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        centerTitleView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleImageView.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        netTrackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        netRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupConstraints() {
        infoListButton.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.width.height.equalTo(42)
            make.centerY.equalToSuperview()
        }
        
        centerTitleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        centerTipsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalToSuperview().offset(-44)
        }
        
        settingButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.height.equalTo(42)
            make.centerY.equalToSuperview()
        }
        
        netStateView.snp.remakeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
    }
}

extension AgentSettingBar: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {
        updateNetWorkView()
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus) {
        if roomState == .unload {
//            tipsButton.setImage(UIImage.ag_named("ic_agent_tips_icon"), for: .normal)
        }
    }
}
