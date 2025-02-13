//
//  AgentInformationViewController.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/7.
//

import UIKit
import Common

class AgentInformationViewController: UIViewController {
    private let backgroundViewHeight: CGFloat = 492
    private var initialCenter: CGPoint = .zero
    private var panGesture: UIPanGestureRecognizer?
    private var networkItems: [UIView] = []
    private var channelInfoItems: [UIView] = []
    
    var channelName = ""
    
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
        view.alpha = 0.95
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var networkInfoTitle: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.ChannelInfo.networkInfoTitle
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.themColor(named: "ai_icontext4")
        return label
    }()
    
    private lazy var networkInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        view.layerCornerRadius = 10
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        return view
    }()
    
    private lazy var networkItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourNetwork
        view.detailLabel.textColor = UIColor.themColor(named: "ai_green6")
        view.imageView.isHidden = true
        return view
    }()
    
    private lazy var channelInfoTitle: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.ChannelInfo.title
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
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
        backgroundView.transform = CGAffineTransform(translationX: 0, y: backgroundViewHeight)
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.transform = .identity
        }
    }
    
    private func animateBackgroundViewOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.transform = CGAffineTransform(translationX:0, y: self.backgroundViewHeight)
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
            let newY = max(translation.y, 0)
            backgroundView.transform = CGAffineTransform(translationX:0, y: newY)
        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldDismiss = translation.y > backgroundViewHeight / 2 || velocity.y > 500
            
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
}

extension AgentInformationViewController {
    private func createViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(backgroundView)
        backgroundView.addSubview(topView)
        backgroundView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        networkItems = [networkItem]
        channelInfoItems = [agentItem, agentIDItem, roomItem, roomIDItem, idItem]
        
        contentView.addSubview(networkInfoTitle)
        contentView.addSubview(networkInfoView)
        contentView.addSubview(channelInfoTitle)
        contentView.addSubview(channelInfoView)
        
        networkItems.forEach { networkInfoView.addSubview($0) }
        channelInfoItems.forEach { channelInfoView.addSubview($0) }
    }
    
    private func createConstrains() {
        backgroundView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(backgroundViewHeight)
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
            make.width.equalTo(self.view)
            make.left.right.top.bottom.equalToSuperview()
        }
        
        networkInfoTitle.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(20)
        }
        
        networkInfoView.snp.makeConstraints { make in
            make.top.equalTo(networkInfoTitle.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }

        for (index, item) in networkItems.enumerated() {
            item.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(60)
                
                if index == 0 {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(networkItems[index - 1].snp.bottom)
                }
                
                if index == networkItems.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
        }
        
        channelInfoTitle.snp.makeConstraints { make in
            make.top.equalTo(networkInfoView.snp.bottom).offset(32)
            make.left.equalTo(20)
        }
        
        channelInfoView.snp.makeConstraints { make in
            make.top.equalTo(channelInfoTitle.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
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
    }
    
    private func initStatus() {
        guard let manager = AppContext.preferenceManager() else {
            return
        }
        
        // Update Network Status
        networkItem.detailLabel.text = manager.information.networkState == .unknown ? ConnectionStatus.disconnected.rawValue : manager.information.networkState.rawValue
        networkItem.detailLabel.textColor = manager.information.networkState.color
        
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
    }
    
    @objc func handleTapGesture(_: UIGestureRecognizer) {
        animateBackgroundViewOut()
    }
}

extension AgentInformationViewController: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, networkDidUpdated networkState: NetworkStatus) {
        networkItem.detailLabel.text = networkState == .unknown ? ConnectionStatus.disconnected.rawValue : networkState.rawValue
        networkItem.detailLabel.textColor = networkState.color
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, agentStateDidUpdated agentState: ConnectionStatus) {
        agentItem.detailLabel.text = agentState == .unload ? ConnectionStatus.disconnected.rawValue : agentState.rawValue
        agentItem.detailLabel.textColor = agentState == .unload ? ConnectionStatus.disconnected.color : agentState.color
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
