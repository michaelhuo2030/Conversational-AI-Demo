//
//  AgentSettingInfoViewController.swift
//  Agent
//
//  Created by qinhui on 2024/10/31.
//

import UIKit
import Common

class AgentNetworkInfoView: AgentSettingInfoView {
    private let networkItem = AgentSettingTableItemView(frame: .zero)

    override func createViews() {
        backgroundColor = PrimaryColors.c_1d1d1d
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        content1Title.text = ResourceManager.L10n.ChannelInfo.networkInfoTitle
        content1Title.textColor = PrimaryColors.c_ffffff_a
        contentView.addSubview(content1Title)
        
        contentView1.backgroundColor = PrimaryColors.c_141414
        contentView1.layerCornerRadius = 10
        contentView1.layer.borderWidth = 1
        contentView1.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView1)
        
        networkItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourNetwork
        networkItem.detialLabel.textColor = PrimaryColors.c_36b37e
        networkItem.backgroundColor = PrimaryColors.c_141414
        networkItem.imageView.isHidden = true
        contentView1.addSubview(networkItem)
    }
    
    override func createConstrains() {
        scrollView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.left.right.top.bottom.equalToSuperview()
        }
        content1Title.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(20)
        }
        contentView1.snp.makeConstraints { make in
            make.top.equalTo(content1Title.snp.bottom).offset(8)
            make.left.equalTo(8)
            make.right.equalTo(-8)
        }
        networkItem.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(-6)
            make.height.equalTo(44)
        }
    }
    
    override func updateStatus() {
        let manager = DHSceneManager.shared
        networkItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourNetwork
        networkItem.detialLabel.text = manager.networkStatus == .unknown ? "" : manager.networkStatus.rawValue
        networkItem.detialLabel.textColor = manager.networkStatus.color
    }
}

class AgentSettingInfoView: UIView {
    let scrollView = UIScrollView()
    let content1Title = UILabel()
    let contentView = UIView()
    let contentView1 = UIView()
    
    private let agentItem = AgentSettingTableItemView(frame: .zero)
    private let roomItem = AgentSettingTableItemView(frame: .zero)
    private let roomIDItem = AgentSettingTableItemView(frame: .zero)
    private let idItem = AgentSettingTableItemView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        createViews()
        createConstrains()
        updateStatus()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        createViews()
        createConstrains()
        updateStatus()
    }
    
    func updateStatus() {
        let manager = DHSceneManager.shared
        let status = DHSceneManager.shared.roomStatus
        
        // Update Agent Status
        agentItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
        agentItem.detialLabel.text = (status == .unload) ? "" : status.rawValue
        agentItem.detialLabel.textColor = status.color
        agentItem.bottomLineStyle2()
        
        // Update Room Status
        roomItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
        roomItem.detialLabel.text = (status == .unload) ? "" : status.rawValue
        roomItem.detialLabel.textColor = manager.roomStatus.color
        roomItem.bottomLineStyle2()
        
        // Update Room ID
        roomIDItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
        roomIDItem.detialLabel.text = manager.channelName
        roomIDItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
        roomIDItem.bottomLineStyle2()
        
        // Update Participant ID
        idItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
        idItem.detialLabel.text = (status == .unload) ? "" : String(manager.uid)
        idItem.detialLabel.textColor = PrimaryColors.c_ffffff_a
        idItem.bottomLineStyle2()
    }
    
    func createViews() {
        backgroundColor = PrimaryColors.c_1d1d1d
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        content1Title.text = ResourceManager.L10n.ChannelInfo.title
        content1Title.textColor = PrimaryColors.c_ffffff_a
        contentView.addSubview(content1Title)
        
        contentView1.backgroundColor = PrimaryColors.c_141414
        contentView1.layerCornerRadius = 10
        contentView1.layer.borderWidth = 1
        contentView1.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView1)
        
        agentItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.agentStatus
        agentItem.detialLabel.textColor = PrimaryColors.c_36b37e
        agentItem.backgroundColor = PrimaryColors.c_141414
        agentItem.imageView.isHidden = true
        contentView1.addSubview(agentItem)
        
        roomItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomStatus
        roomItem.detialLabel.textColor = PrimaryColors.c_36b37e
        roomItem.backgroundColor = PrimaryColors.c_141414
        roomItem.imageView.isHidden = true

        contentView1.addSubview(roomItem)
        
        roomIDItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.roomId
        roomIDItem.imageView.isHidden = true
        roomIDItem.backgroundColor = PrimaryColors.c_141414
        contentView1.addSubview(roomIDItem)
        
        idItem.titleLabel.text = ResourceManager.L10n.ChannelInfo.yourId
        idItem.bottomLine.isHidden = true
        idItem.backgroundColor = PrimaryColors.c_141414
        idItem.imageView.isHidden = true
        contentView1.addSubview(idItem)
    }
    
    func createConstrains() {
        scrollView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self)
            make.left.right.top.bottom.equalToSuperview()
        }
        content1Title.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.left.equalTo(20)
        }
        contentView1.snp.makeConstraints { make in
            make.top.equalTo(content1Title.snp.bottom).offset(8)
            make.left.equalTo(8)
            make.right.equalTo(-8)
        }
        agentItem.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        roomItem.snp.makeConstraints { make in
            make.top.equalTo(agentItem.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        roomIDItem.snp.makeConstraints { make in
            make.top.equalTo(roomItem.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        idItem.snp.makeConstraints { make in
            make.top.equalTo(roomIDItem.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
    }
}
