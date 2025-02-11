////
////  AgentSettingInfoViewController.swift
////  Agent
////
////  Created by qinhui on 2024/10/31.
////
//
//import UIKit
//import Common
//
//class AgentNetworkInfoView: AgentSettingInfoView {
//    private let networkItem = AgentSettingTableItemView(frame: .zero)
//
//    override func createViews() {
//        backgroundColor = PrimaryColors.c_1d1d1d
//        addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        
//        content1Title.text = ResourceManager.L10n.ChannelInfo.networkInfoTitle
//        content1Title.textColor = PrimaryColors.c_ffffff_a
//        contentView.addSubview(content1Title)
//        
//        contentView1.backgroundColor = PrimaryColors.c_141414
//        contentView1.layerCornerRadius = 10
//        contentView1.layer.borderWidth = 1
//        contentView1.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
//        contentView.addSubview(contentView1)
//        
//        networkItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourNetwork
//        networkItem.detialLabel.textColor = PrimaryColors.c_36b37e
//        networkItem.backgroundColor = PrimaryColors.c_141414
//        networkItem.imageView.isHidden = true
//        contentView1.addSubview(networkItem)
//    }
//    
//    override func createConstrains() {
//        scrollView.snp.makeConstraints { make in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//        contentView.snp.makeConstraints { make in
//            make.width.equalTo(self)
//            make.left.right.top.bottom.equalToSuperview()
//        }
//        content1Title.snp.makeConstraints { make in
//            make.top.equalTo(20)
//            make.left.equalTo(20)
//        }
//        contentView1.snp.makeConstraints { make in
//            make.top.equalTo(content1Title.snp.bottom).offset(8)
//            make.left.equalTo(8)
//            make.right.equalTo(-8)
//        }
//        networkItem.snp.makeConstraints { make in
//            make.top.left.right.equalToSuperview()
//            make.bottom.equalTo(-6)
//            make.height.equalTo(44)
//        }
//    }
//    
//    override func updateStatus() {
//        let manager = AgentSettingManager.shared
//        networkItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourNetwork
//        networkItem.detialLabel.text = manager.networkStatus == .unknown ? "" : manager.networkStatus.rawValue
//        networkItem.detialLabel.textColor = manager.networkStatus.color
//    }
//}
//
//class AgentSettingInfoView: UIView {
//    lazy var scrollView: UIScrollView = {
//        let view = UIScrollView()
//        return view
//    }()
//    
//    lazy var content1Title: UILabel = {
//        let label = UILabel()
//        label.text = ResourceManager.L10n.ChannelInfo.title
//        label.textColor = PrimaryColors.c_ffffff_a
//        return label
//    }()
//    
//    lazy var contentView: UIView = {
//        let view = UIView()
//        return view
//    }()
//    
//    lazy var contentView1: UIView = {
//        let view = UIView()
//        view.backgroundColor = PrimaryColors.c_141414
//        view.layerCornerRadius = 10
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
//        return view
//    }()
//    
//    private lazy var agentItem: AgentSettingTableItemView = {
//        let view = AgentSettingTableItemView(frame: .zero)
//        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
//        view.detialLabel.textColor = PrimaryColors.c_36b37e
//        view.backgroundColor = PrimaryColors.c_141414
//        view.imageView.isHidden = true
//        return view
//    }()
//    
//    private lazy var roomItem: AgentSettingTableItemView = {
//        let view = AgentSettingTableItemView(frame: .zero)
//        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
//        view.detialLabel.textColor = PrimaryColors.c_36b37e
//        view.backgroundColor = PrimaryColors.c_141414
//        view.imageView.isHidden = true
//        return view
//    }()
//    
//    private lazy var roomIDItem: AgentSettingTableItemView = {
//        let view = AgentSettingTableItemView(frame: .zero)
//        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
//        view.imageView.isHidden = true
//        view.backgroundColor = PrimaryColors.c_141414
//        return view
//    }()
//    
//    private lazy var idItem: AgentSettingTableItemView = {
//        let view = AgentSettingTableItemView(frame: .zero)
//        view.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
//        view.bottomLine.isHidden = true
//        view.backgroundColor = PrimaryColors.c_141414
//        view.imageView.isHidden = true
//        return view
//    }()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.layer.cornerRadius = 15
//        self.layer.masksToBounds = true
//        registerDelegate()
//        createViews()
//        createConstrains()
//        initStatus()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        registerDelegate()
//        createViews()
//        createConstrains()
//        initStatus()
//    }
//    
//    deinit {
//        unregisterDelegate()
//    }
//    
//    private func registerDelegate() {
//        AgentPreferenceManager.shared.addDelegate(self)
//    }
//    
//    private func unregisterDelegate() {
//        AgentPreferenceManager.shared.removeDelegate(self)
//    }
//    
//    private func initStatus() {
//        let manager = AgentSettingManager.shared
//        
//        // Update Agent Status
//        agentItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
//        agentItem.detialLabel.text = manager.agentStatus == .unload ? "" : manager.agentStatus.rawValue
//        agentItem.detialLabel.textColor = manager.agentStatus.color
//        agentItem.bottomLineStyle2()
//        
//        // Update Room Status
//        roomItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
//        roomItem.detialLabel.text = manager.roomStatus == .unload ? "" : manager.roomStatus.rawValue
//        roomItem.detialLabel.textColor = manager.roomStatus.color
//        roomItem.bottomLineStyle2()
//        
//        // Update Room ID
//        roomIDItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
//        roomIDItem.detialLabel.text = manager.roomId
//        roomIDItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
//        roomIDItem.bottomLineStyle2()
//        
//        // Update Participant ID
//        idItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
//        idItem.detialLabel.text = manager.agentStatus == .unload ? "" : manager.yourId
//        idItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
//        idItem.bottomLineStyle2()
//    }
//    
//    func createViews() {
//        backgroundColor = PrimaryColors.c_1d1d1d
//        
//        addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        contentView.addSubview(content1Title)
//        contentView.addSubview(contentView1)
//        
//        contentView1.addSubview(agentItem)
//        contentView1.addSubview(roomItem)
//        contentView1.addSubview(roomIDItem)
//        contentView1.addSubview(idItem)
//    }
//    
//    func createConstrains() {
//        scrollView.snp.makeConstraints { make in
//            make.top.left.right.bottom.equalToSuperview()
//        }
//        contentView.snp.makeConstraints { make in
//            make.width.equalTo(self)
//            make.left.right.top.bottom.equalToSuperview()
//        }
//        content1Title.snp.makeConstraints { make in
//            make.top.equalTo(20)
//            make.left.equalTo(20)
//        }
//        contentView1.snp.makeConstraints { make in
//            make.top.equalTo(content1Title.snp.bottom).offset(8)
//            make.left.equalTo(8)
//            make.right.equalTo(-8)
//        }
//        agentItem.snp.makeConstraints { make in
//            make.top.left.right.equalToSuperview()
//            make.height.equalTo(56)
//        }
//        roomItem.snp.makeConstraints { make in
//            make.top.equalTo(agentItem.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(56)
//        }
//        roomIDItem.snp.makeConstraints { make in
//            make.top.equalTo(roomItem.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(56)
//        }
//        idItem.snp.makeConstraints { make in
//            make.top.equalTo(roomIDItem.snp.bottom)
//            make.left.right.bottom.equalToSuperview()
//            make.height.equalTo(56)
//        }
//    }
//}
