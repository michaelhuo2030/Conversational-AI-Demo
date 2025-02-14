////
////  PreparedToStartViewController.swift
////  VoiceAgent
////
////  Created by qinhui on 2024/12/23.
////
//
//import UIKit
//import Common
//import SVProgressHUD
//
//// MARK: - PreparedToStartViewController
//class PreparedToStartViewController: UIViewController {
//    public var showMineContent: Bool = false
//    // MARK: - Properties
//    private lazy var host: String = AppContext.shared.baseServerUrl
//    private lazy var rtcToken: String = ""
//    private lazy var channelName: String = "agora_\(RtcEnum.getChannel())"
//    private lazy var uid: Int = RtcEnum.getUid()
//    
//    // MARK: - UI Components
//    private lazy var topBar: AgentSettingBar = {
//        let view = AgentSettingBar()
//        view.onTipsButtonTapped = { [weak self] in
//            self?.handleTipsButtonTapped()
//        }
//        view.onSettingButtonTapped = { [weak self] in
//            self?.handleSettingButtonTapped()
//        }
//        view.onNetworkStatusChanged = { [weak self] in
//            self?.handleNetworkButtonTapped()
//        }
//        view.onBackButtonTapped = { [weak self] in
//            self?.navigationController?.popViewController(animated: true)
//        }
//        return view
//    }()
//    
//    private lazy var centerContainer: UIView = UIView()
//    
//    private lazy var statusContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.themColor(named: "ai_line1")
//        view.layer.cornerRadius = 12
//        return view
//    }()
//    
//    private lazy var agentImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.image = UIImage.ag_named("ic_agent_circle")
//        return imageView
//    }()
//    
//    private lazy var statusLabel: UILabel = {
//        let label = UILabel()
//        label.text = ResourceManager.L10n.Join.state
//        label.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
//        label.textColor = UIColor.themColor(named: "ai_icontext4")
//        return label
//    }()
//    
//    private lazy var agentTagContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = PrimaryColors.c_000000_a
//        view.layer.cornerRadius = 4
//        return view
//    }()
//    
//    private lazy var agentTagLabel: UILabel = {
//        let label = UILabel()
//        label.text = ResourceManager.L10n.Join.agentName
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = UIColor.themColor(named: "ai_icontext1")
//        return label
//    }()
//    
//    private lazy var joinButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.setTitle(ResourceManager.L10n.Join.buttonTitle, for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 18)
//        button.setTitleColor(UIColor.themColor(named: "ai_icontext1"), for: .normal)
//        button.backgroundColor = PrimaryColors.c_0097d4
//        button.layer.cornerRadius = 32
//        button.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
//        button.setImage(UIImage.ag_named("ic_agent_join_button_icon"), for: .normal)
//        
//        let spacing: CGFloat = 5
//        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
//        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
//        
//        return button
//    }()
//    
//    private var selectTable: AgentSettingInfoView? = nil
//    private var selectTableMask = UIButton(type: .custom)
//        
//    // MARK: - Lifecycle
//    public override func viewDidLoad() {
//        super.viewDidLoad()
//        setupViews()
//        setupConstraints()
//        setupConfig()
//    }
//    
//    // MARK: - Private Methods
//    private func setupViews() {
//        view.backgroundColor = PrimaryColors.c_0a0a0a
//        
//        view.addSubview(topBar)
//        view.addSubview(statusContainer)
//        view.addSubview(joinButton)
//        
//        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
//        selectTableMask.isHidden = true
//        view.addSubview(selectTableMask)
//        
//        statusContainer.addSubview(centerContainer)
//        centerContainer.addSubview(agentImageView)
//        centerContainer.addSubview(statusLabel)
//        
//        statusContainer.addSubview(agentTagContainer)
//        agentTagContainer.addSubview(agentTagLabel)
//        
//    }
//    
//    private func setupConstraints() {
//        topBar.snp.makeConstraints { make in
//            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
//            make.left.equalTo(20)
//            make.right.equalTo(-20)
//            make.height.equalTo(48)
//        }
//        
//        statusContainer.snp.makeConstraints { make in
//            make.top.equalTo(topBar.snp.bottom).offset(20)
//            make.left.right.equalToSuperview().inset(20)
//            make.bottom.equalTo(joinButton.snp.top).offset(-20)
//        }
//        
//        agentTagContainer.snp.makeConstraints { make in
//            make.bottom.equalTo(-20)
//            make.left.equalTo(12)
//            make.height.equalTo(32)
//        }
//        
//        agentTagLabel.snp.makeConstraints { make in
//            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
//        }
//        
//        centerContainer.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//        }
//        
//        agentImageView.snp.makeConstraints { make in
//            make.top.left.right.equalToSuperview()
//            make.width.height.equalTo(254)
//        }
//        
//        statusLabel.snp.makeConstraints { make in
//            make.top.equalTo(agentImageView.snp.bottom).offset(20)
//            make.centerX.equalToSuperview()
//            make.bottom.equalToSuperview()
//        }
//        
//        joinButton.snp.makeConstraints { make in
//            make.left.right.equalToSuperview().inset(20)
//            make.height.equalTo(64)
//            make.bottom.equalTo(-40)
//        }
//        
//        selectTableMask.snp.makeConstraints { make in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//    }
//    
//    private func setupConfig() {
//        SVProgressHUD.setMaximumDismissTimeInterval(3)
//        AgentSettingManager.shared.updateYourId("\(RtcEnum.getUid())")
//    }
//    
//    private func joinCall() {
//        if host.isEmpty {
//            SVProgressHUD.showError(withStatus: "Invalid host address.")
//            return
//        }
//        
//        PermissionManager.checkMicrophonePermission { granted in
//            if !granted {
//                DispatchQueue.main.async {
//                    SVProgressHUD.showInfo(withStatus: "Microphone usage refused")
//                }
//            }
//        }
//                
//        SVProgressHUD.show()
//        NetworkManager.shared.generateToken(
//            channelName: "",
//            uid: "\(uid)",
//            types: [.rtc]
//        ) { [weak self] token in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                if let token = token {
//                    print("rtc token is : \(token)")
//                    self.rtcToken = token
//                    self.showAgent()
//                } else {
//                    SVProgressHUD.dismiss()
//                    SVProgressHUD.showInfo(withStatus: "generate token error")
//                }
//            }
//        }
//    }
//    
//    private func showAgent() {
////        ChatViewController.showAgent(host: host, token: rtcToken, uid: uid, agentUid: AppContext.agentUid, channel: channelName, showMineContent: showMineContent, vc: self)
//    }
//    
//    // MARK: - Actions
//    @objc private func joinButtonTapped() {
//        if host.isEmpty {
//            SVProgressHUD.showError(withStatus: "Invalid host address.")
//        } else {
//            joinCall()
//        }
//    }
//    
//    private func handleTipsButtonTapped() {
//        selectTableMask.isHidden = false
//        let v = AgentSettingInfoView()
//        self.view.addSubview(v)
//        selectTable = v
////        let button = topBar.networkSignalView
////        v.snp.makeConstraints { make in
////            make.right.equalTo(button.snp.right).offset(20)
////            make.top.equalTo(button.snp.bottom)
////            make.width.equalTo(320)
////            make.height.equalTo(290)
////        }
//        
//    }
//    
//    private func handleNetworkButtonTapped() {
//        selectTableMask.isHidden = false
//        let v = AgentNetworkInfoView()
//        self.view.addSubview(v)
//        selectTable = v
////        let button = topBar.networkSignalView
////        v.snp.makeConstraints { make in
////            make.right.equalTo(button.snp.right).offset(20)
////            make.top.equalTo(button.snp.bottom)
////            make.width.equalTo(304)
////            make.height.equalTo(104)
////        }
//    }
//    
//    @objc func onClickHideTable(_ sender: UIButton) {
//        selectTable?.removeFromSuperview()
//        selectTable = nil
//        selectTableMask.isHidden = true
//    }
//    
//    private func handleSettingButtonTapped() {
//        let settingVc = AgentSettingViewController()
//        let navigationVC = UINavigationController(rootViewController: settingVc)
//        present(navigationVC, animated: true)
//    }
//}
