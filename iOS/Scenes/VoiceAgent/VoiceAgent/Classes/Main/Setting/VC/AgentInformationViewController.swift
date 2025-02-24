//
//  AgentInformationViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentInformationViewController: UIViewController {
    
    static func show(in viewController: UIViewController, rtcManager: RTCManager?) {
        let settingVC = AgentInformationViewController()
        settingVC.rtcManager = rtcManager
        settingVC.modalPresentationStyle = .overFullScreen
        viewController.present(settingVC, animated: false)
    }
    
    public var rtcManager: RTCManager?
    
    private let backgroundViewWidth: CGFloat = 315
    private var initialCenter: CGPoint = .zero
    private var panGesture: UIPanGestureRecognizer?
    private var moreItems: [UIView] = []
    private var channelInfoItems: [UIView] = []
    private let loadingMaskView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private lazy var feedBackPresenter = FeedBackPresenter()
        
    private lazy var topView: AgentSettingTopView = {
        let view = AgentSettingTopView()
        view.setTitle(title: ResourceManager.L10n.ChannelInfo.title)
        view.onCloseButtonTapped = { [weak self] in
            self?.animateBackgroundViewOut()
        }
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var moreInfoTitle: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.ChannelInfo.moreInfo
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext4")
        return label
    }()
    
    private lazy var moreInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        view.layerCornerRadius = 10
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        return view
    }()
    
    private lazy var feedbackItem: AgentSettingIconItemView = {
        let view = AgentSettingIconItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.feedback
        view.imageView.image = UIImage.ag_named("ic_info_debug")?.withRenderingMode(.alwaysTemplate)
        view.imageView.tintColor = UIColor.themColor(named: "ai_icontext1")
        view.button.addTarget(self, action: #selector(onClickFeedbackItem), for: .touchUpInside)
        return view
    }()
    
    private lazy var logoutItem: AgentSettingIconItemView = {
        let view = AgentSettingIconItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.logout
        view.imageView.image = UIImage.ag_named("ic_info_logout")?.withRenderingMode(.alwaysTemplate)
        view.imageView.tintColor = UIColor.themColor(named: "ai_icontext1")
        view.button.addTarget(self, action: #selector(onClickLogoutItem), for: .touchUpInside)
        return view
    }()
    
    private lazy var channelInfoTitle: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.ChannelInfo.subtitle
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext4")
        return label
    }()
    
    private lazy var channelInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        view.layerCornerRadius = 10
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        return view
    }()
    
    private lazy var agentItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
        view.detailLabel.textColor = UIColor.themColor(named: "ai_block2")
        view.imageView.isHidden = true
        return view
    }()
    
    private lazy var agentIDItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentId
        view.imageView.isHidden = true
        view.enableLongPressCopy = true
        return view
    }()
    
    private lazy var roomItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
        view.detailLabel.textColor = UIColor.themColor(named: "ai_green6")
        view.imageView.isHidden = true
        return view
    }()
    
    private lazy var roomIDItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
        view.imageView.isHidden = true
        return view
    }()
    
    private lazy var idItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
        view.bottomLine.isHidden = true
        view.imageView.isHidden = true
        return view
    }()
        
    deinit {
        unregisterDelegate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerDelegate()
        createViews()
        createConstrains()
        setupPanGesture()
        animateBackgroundViewIn()
        initStatus()
    }
    
    private func registerDelegate() {
        AppContext.preferenceManager()?.addDelegate(self)
    }
    
    private func unregisterDelegate() {
        AppContext.preferenceManager()?.removeDelegate(self)
    }
    
    private func setupPanGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        backgroundView.addGestureRecognizer(panGesture!)
    }
    
    private func animateBackgroundViewIn() {
        backgroundView.transform = CGAffineTransform(translationX: -self.backgroundViewWidth, y: 0)
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.transform = .identity
        }
    }
    
    private func animateBackgroundViewOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.transform = CGAffineTransform(translationX: -self.backgroundViewWidth, y: 0)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began:
            initialCenter = backgroundView.center
        case .changed:
            let newX = min(max(translation.x, -backgroundViewWidth), 0)
            backgroundView.transform = CGAffineTransform(translationX: newX, y: 0)
        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldDismiss = abs(translation.x) > backgroundViewWidth / 2 || abs(velocity.x) > 500
            
            if shouldDismiss {
                animateBackgroundViewOut()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.backgroundView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func onClickFeedbackItem() {
        guard let channelName = AppContext.preferenceManager()?.information.roomId,
              let rtcManager = rtcManager
        else {
            return
        }
        let agentId = AppContext.preferenceManager()?.information.agentId
        feedbackItem.startLoading()
        loadingMaskView.isHidden = false
        rtcManager.predump {
            self.feedBackPresenter.feedback(isSendLog: true, channel: channelName, agentId: agentId) { error, result in
                self.loadingMaskView.isHidden = true
                self.feedbackItem.stopLoading()
            }
        }
    }
    
    @objc private func onClickLogoutItem() {
        AgentAlertView.show(in: view, title: ResourceManager.L10n.Login.logoutAlertTitle, content: ResourceManager.L10n.Login.logoutAlertDescription, onConfirm:  {
            AppContext.loginManager()?.logout()
        })
    }
}

extension AgentInformationViewController {
    private func createViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickBackground(_:))))
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClickContent(_:))))
        
        view.addSubview(backgroundView)
        backgroundView.addSubview(topView)
        backgroundView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        moreItems = [feedbackItem, logoutItem]
        channelInfoItems = [agentItem, agentIDItem, roomItem, roomIDItem, idItem]
        
        contentView.addSubview(moreInfoTitle)
        contentView.addSubview(moreInfoView)
        contentView.addSubview(channelInfoTitle)
        contentView.addSubview(channelInfoView)
        
        moreItems.forEach { moreInfoView.addSubview($0) }
        channelInfoItems.forEach { channelInfoView.addSubview($0) }
        
        contentView.addSubview(loadingMaskView)
    }
    
    private func createConstrains() {
        backgroundView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(backgroundViewWidth)
        }
        
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self.backgroundView)
            make.left.right.top.bottom.equalToSuperview()
        }
        
        channelInfoTitle.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(32)
        }
        
        channelInfoView.snp.makeConstraints { make in
            make.top.equalTo(channelInfoTitle.snp.bottom).offset(8)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }

        for (index, item) in channelInfoItems.enumerated() {
            item.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(50)
                
                if index == 0 {
                    make.top.equalTo(0)
                } else {
                    make.top.equalTo(channelInfoItems[index - 1].snp.bottom)
                }
                
                if index == channelInfoItems.count - 1 {
                    make.bottom.equalToSuperview().priority(30)
                } else {
                    make.bottom.equalToSuperview().priority(20)
                }
            }
        }
        
        moreInfoTitle.snp.makeConstraints { make in
            make.top.equalTo(channelInfoView.snp.bottom).offset(32)
            make.left.equalTo(32)
        }
        
        moreInfoView.snp.makeConstraints { make in
            make.top.equalTo(moreInfoTitle.snp.bottom).offset(8)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalToSuperview()
        }

        for (index, item) in moreItems.enumerated() {
            item.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(60)
                
                if index == 0 {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(moreItems[index - 1].snp.bottom)
                }
                
                if index == moreItems.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
        }
        loadingMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func initStatus() {
        guard let manager = AppContext.preferenceManager() else {
            return
        }
        
        agentItem.detailLabel.text = manager.information.agentState == .unload ? ConnectionStatus.disconnected.rawValue : manager.information.agentState.rawValue
        agentItem.detailLabel.textColor = manager.information.agentState == .unload ? ConnectionStatus.disconnected.color : manager.information.agentState.color
        
        // Update Room Status
        roomItem.detailLabel.text = manager.information.rtcRoomState == .unload ? ConnectionStatus.disconnected.rawValue :  manager.information.rtcRoomState.rawValue
        roomItem.detailLabel.textColor = manager.information.rtcRoomState == .unload ? ConnectionStatus.disconnected.color : manager.information.rtcRoomState.color
        
        // Update Agent ID
        agentIDItem.detailLabel.text = manager.information.agentState == .unload ? "--" : manager.information.agentId
        agentIDItem.detailLabel.textColor = UIColor.themColor(named: "ai_icontext3")
        
        // Update Room ID
        roomIDItem.detailLabel.text = manager.information.rtcRoomState == .unload ? "--" : manager.information.roomId
        roomIDItem.detailLabel.textColor = UIColor.themColor(named: "ai_icontext3")
        
        // Update Participant ID
        idItem.detailLabel.text = manager.information.rtcRoomState == .unload ? "--" : manager.information.userId
        idItem.detailLabel.textColor = UIColor.themColor(named: "ai_icontext3")
        
        // Update Feedback Item
//        feedbackItem.setEnabled(isEnabled: manager.information.agentState != .unload)
        
        //Update Logout Item
        logoutItem.setEnabled(isEnabled: true)
    }
    
    @objc func onClickBackground(_ sender: UIGestureRecognizer) {
        animateBackgroundViewOut()
    }
    @objc func onClickContent(_ sender: UIGestureRecognizer) {
    }
}

extension AgentInformationViewController: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {
        
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, agentStateDidUpdated agentState: ConnectionStatus) {
        agentItem.detailLabel.text = agentState == .unload ? ConnectionStatus.disconnected.rawValue : agentState.rawValue
        agentItem.detailLabel.textColor = agentState == .unload ? ConnectionStatus.disconnected.color : agentState.color
        feedbackItem.setEnabled(isEnabled: agentState != .unload)
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, roomStateDidUpdated roomState: ConnectionStatus) {
        roomItem.detailLabel.text = roomState == .unload ? ConnectionStatus.disconnected.rawValue :  roomState.rawValue
        roomItem.detailLabel.textColor = roomState == .unload ? ConnectionStatus.disconnected.color : roomState.color
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, agentIdDidUpdated agentId: String) {
        agentIDItem.detailLabel.text = manager.information.agentState == .unload ? "--" : agentId
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, roomIdDidUpdated roomId: String) {
        roomIDItem.detailLabel.text = manager.information.rtcRoomState == .unload ? "--" : roomId
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, userIdDidUpdated userId: String) {
        idItem.detailLabel.text = manager.information.rtcRoomState == .unload ? "--" : userId
    }
}
