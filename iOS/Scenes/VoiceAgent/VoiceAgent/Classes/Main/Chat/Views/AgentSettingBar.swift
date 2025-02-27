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
        
    let netStateView = UIView()
    private let netTrackView = UIImageView(image: UIImage.ag_named("ic_agent_net_4"))
    private let netRenderView = UIImageView(image: UIImage.ag_named("ic_agent_net_3"))
    
    let settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_agent_setting"), for: .normal)
        return button
    }()
    
    private let titleContentView = {
       let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let centerTitleView = UIView()
    private lazy var centerTipsLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: ResourceManager.L10n.Join.tips, 10)
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    private let countDownLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .center
        label.layerCornerRadius = 11
        label.isHidden = true
        label.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        label.textColor = UIColor.themColor(named: "ai_brand_white10")
        return label
    }()
    let centerTitleButton = UIButton()
    
    var showTipsTimer: Timer?
    var isShowTips = false
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerDelegate()
        setupViews()
        setupConstraints()
        updateNetWorkView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unregisterDelegate()
    }
    
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
    
    public func startWithRestTime(_ seconds: Int) {
        showTips(seconds: seconds)
        countDownLabel.isHidden = false
        updateRestTime(seconds)
    }
    
    public func updateButtonVisible(_ visible: Bool) {
        if (visible) {
            infoListButton.isHidden = false
            settingButton.isHidden = false
            updateNetWorkView()
        } else {
            infoListButton.isHidden = true
            settingButton.isHidden = true
            netStateView.isHidden = true
        }
    }
    
    public func updateRestTime(_ seconds: Int) {
        if seconds < 20 {
            countDownLabel.textColor = UIColor.themColor(named: "ai_red6")
        } else if seconds < 59 {
            countDownLabel.textColor = UIColor.themColor(named: "ai_green6")
        } else {
            countDownLabel.textColor = UIColor.themColor(named: "ai_brand_white10")
        }
        let minutes = seconds / 60
        let s = seconds % 60
        countDownLabel.text = String(format: "%02d:%02d", minutes, s)
    }
    
    public func stop() {
        countDownLabel.isHidden = true
        hideTips()
    }
    
    public func showTips(seconds: Int = 10 * 60) {
        if isShowTips {
            return
        }
        let minutes = seconds / 60
        centerTipsLabel.text = String(format: ResourceManager.L10n.Join.tips, minutes)
        isShowTips = true
        showTipsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(hideTips), userInfo: nil, repeats: false)
        self.centerTitleView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalTo(self.snp.top)
        }
        self.centerTipsLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        UIView.animate(withDuration: 1.0, animations: {
            self.layoutIfNeeded()
        }) { _ in
            self.centerTitleView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.height.equalToSuperview()
                make.top.equalTo(self.snp.bottom)
            }
            self.layoutIfNeeded()
        }
    }
    
    // MARK: - Private Methods
    @objc private func hideTips() {
        if !isShowTips {
            return
        }
        isShowTips = false
        showTipsTimer?.invalidate()
        showTipsTimer = nil
        self.centerTipsLabel.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalTo(self.snp.top)
        }
        self.centerTitleView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        UIView.animate(withDuration: 1.0, animations: {
            self.layoutIfNeeded()
        }) { _ in
            self.centerTipsLabel.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.height.equalToSuperview()
                make.top.equalTo(self.snp.bottom)
            }
            self.layoutIfNeeded()
        }
    }
    
    private func updateNetWorkView() {
        guard let manager = AppContext.preferenceManager() else {
            netStateView.isHidden = true
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
        [titleContentView, infoListButton, netStateView, settingButton, countDownLabel].forEach { addSubview($0) }
        [centerTipsLabel, centerTitleView, centerTitleButton].forEach { titleContentView.addSubview($0) }
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
    }
    
    private func setupConstraints() {
        infoListButton.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.width.height.equalTo(42)
            make.centerY.equalToSuperview()
        }
        titleContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        centerTitleView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        centerTipsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
        }
        centerTitleButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        settingButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.width.height.equalTo(42)
            make.centerY.equalToSuperview()
        }
        netStateView.snp.remakeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.width.height.equalTo(42)
            make.centerY.equalToSuperview()
        }
        netTrackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        netRenderView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        countDownLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(49)
            make.height.equalTo(22)
            make.top.equalTo(self.snp.bottom)
        }
    }
}

extension AgentSettingBar: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {
        updateNetWorkView()
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus) {
        updateNetWorkView()
    }
}
