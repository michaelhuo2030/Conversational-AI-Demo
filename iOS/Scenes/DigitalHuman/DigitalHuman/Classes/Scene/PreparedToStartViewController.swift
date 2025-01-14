//
//  PreparedToStartViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/23.
//

import UIKit
import Common
import SVProgressHUD

// MARK: - AgentSettingBar
class AgentSettingBar: UIView {
    // MARK: - Callbacks
    var onBackButtonTapped: (() -> Void)?
    var onTipsButtonTapped: (() -> Void)?
    var onSettingButtonTapped: (() -> Void)?
    
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
    
    let networkSignalView: NetworkSignalView = {
        let view = NetworkSignalView()
        return view
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
        [backButton, titleLabel, networkSignalView, tipsButton, settingButton].forEach { addSubview($0) }
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
        
        networkSignalView.snp.makeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
        
        tipsButton.snp.remakeConstraints { make in
            make.right.equalTo(networkSignalView.snp.left)
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
    
    func updateNetworkStatus(_ status: NetworkStatus) {
        networkSignalView.updateStatus(status)
    }
}

// MARK: - PreparedToStartViewController
class PreparedToStartViewController: UIViewController {
    var showMineContent: Bool = false
    // MARK: - Properties
    private lazy var host: String = AppContext.shared.baseServerUrl
    private lazy var rtcToken: String = ""
    private lazy var channelName: String = "agora_\(RtcEnum.getChannel())"
    private lazy var uid: Int = RtcEnum.getUid()
    
    // MARK: - UI Components
    private lazy var topBar: AgentSettingBar = {
        let view = AgentSettingBar()
        view.onTipsButtonTapped = { [weak self] in
            self?.handleTipsButtonTapped()
        }
        view.onSettingButtonTapped = { [weak self] in
            self?.handleSettingButtonTapped()
        }
        view.onBackButtonTapped = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return view
    }()
    
    private lazy var centerContainer: UIView = UIView()
    
    private lazy var statusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = PrimaryColors.c_27272a_a
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var agentImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.va_named("ic_agent_circle")
        return imageView
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.state
        label.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
        label.textColor = PrimaryColors.c_b3b3b3
        return label
    }()
    
    private lazy var agentTagContainer: UIView = {
        let view = UIView()
        view.backgroundColor = PrimaryColors.c_000000_a
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var agentTagLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.agentName
        label.font = .systemFont(ofSize: 14)
        label.textColor = PrimaryColors.c_ffffff
        return label
    }()
    
    private lazy var joinButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Join.buttonTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18)
        button.setTitleColor(PrimaryColors.c_ffffff, for: .normal)
        button.backgroundColor = PrimaryColors.c_0097d4
        button.layer.cornerRadius = 32
        button.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        button.setImage(UIImage.va_named("ic_agent_join_button_icon"), for: .normal)
        
        let spacing: CGFloat = 5
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        
        return button
    }()
    
    private var selectTable: AgentSettingInfoView? = nil
    private var selectTableMask = UIButton(type: .custom)
        
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupConfig()
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        view.backgroundColor = PrimaryColors.c_0a0a0a
        
        view.addSubview(topBar)
        view.addSubview(statusContainer)
        view.addSubview(joinButton)
        
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
        
        statusContainer.addSubview(centerContainer)
        centerContainer.addSubview(agentImageView)
        centerContainer.addSubview(statusLabel)
        
        statusContainer.addSubview(agentTagContainer)
        agentTagContainer.addSubview(agentTagLabel)
        
    }
    
    private func setupConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(48)
        }
        
        statusContainer.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(joinButton.snp.top).offset(-20)
        }
        
        agentTagContainer.snp.makeConstraints { make in
            make.bottom.equalTo(-20)
            make.left.equalTo(12)
            make.height.equalTo(32)
        }
        
        agentTagLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
        
        centerContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        agentImageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.height.equalTo(254)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(agentImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        joinButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(64)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    private func setupConfig() {
        SVProgressHUD.setMaximumDismissTimeInterval(3)
        AgentSettingManager.shared.updateYourId("\(RtcEnum.getUid())")
    }
    
    private func joinCall() {
        if host.isEmpty {
            SVProgressHUD.showError(withStatus: "Invalid host address.")
            return
        }
        
        PermissionManager.checkMicrophonePermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    SVProgressHUD.showInfo(withStatus: "Microphone usage refused")
                }
            }
        }
        
        SVProgressHUD.show(withStatus: "loading...")
        
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: "\(uid)",
            types: [.rtc]
        ) { [weak self] token in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                if let token = token {
                    print("rtc token is : \(token)")
                    self.rtcToken = token
                    self.showAgent()
                } else {
                    SVProgressHUD.showInfo(withStatus: "generate token error")
                }
            }
        }
    }
    
    private func showAgent() {
        ChatViewController.showAgent(host: host, token: rtcToken, uid: uid, agentUid: AppContext.agentUid, channel: channelName, showMineContent: showMineContent, vc: self)
    }
    
    // MARK: - Actions
    @objc private func joinButtonTapped() {
        if host.isEmpty {
            SVProgressHUD.showError(withStatus: "Invalid host address.")
        } else {
            joinCall()
        }
    }
    
    private func handleTipsButtonTapped() {
        selectTableMask.isHidden = false
        let v = AgentSettingInfoView()
        self.view.addSubview(v)
        selectTable = v
        let button = topBar.networkSignalView
        v.snp.makeConstraints { make in
            make.right.equalTo(button.snp.right).offset(20)
            make.top.equalTo(button.snp.bottom)
            make.width.equalTo(320)
            make.height.equalTo(290)
        }
        
    }
    
    @objc func onClickHideTable(_ sender: UIButton) {
        selectTable?.removeFromSuperview()
        selectTable = nil
        selectTableMask.isHidden = true
    }
    
    private func handleSettingButtonTapped() {
        let settingVc = AgentSettingViewController()
        let navigationVC = UINavigationController(rootViewController: settingVc)
        present(navigationVC, animated: true)
    }
}
