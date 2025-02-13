//
//  AgentSettingView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import UIKit
import Common

class AgentSettingSwitchItemView: UIView {
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let switcher = UISwitch()
    let bottomLine = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
        updateEnableState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgentSettingSwitchItemView {
    
    private func createViews() {
        self.backgroundColor = UIColor.themColor(named: "ai_block2")

        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(titleLabel)
        
        detailLabel.textColor = UIColor.themColor(named: "ai_icontext3")
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        addSubview(detailLabel)
        
        bottomLine.backgroundColor = UIColor.themColor(named: "ai_line1")
        addSubview(bottomLine)
        
        addSubview(switcher)
        
        switcher.onTintColor = UIColor.themColor(named: "ai_brand_lightbrand6")
        switcher.backgroundColor = UIColor.themColor(named: "ai_brand_white10")
        switcher.layer.cornerRadius = switcher.frame.height / 2
        switcher.clipsToBounds = true
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        switcher.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }
    }
    
    func updateLayout() {
        if let text = detailLabel.text, !text.isEmpty {
            detailLabel.isHidden = false
            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(16)
                make.bottom.equalTo(self.snp.centerY)
            }
        } else {
            detailLabel.isHidden = true
            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(16)
                make.centerY.equalToSuperview()
            }
        }
    }
    
    func updateEnableState() {
        guard let manager = AppContext.preferenceManager(), let language = manager.preference.language else {
            return
        }
        
        if AppContext.shared.appArea == .overseas {
            if language.languageCode == "en-US" {
                switcher.isEnabled = true
                switcher.onTintColor = UIColor.themColor(named: "ai_brand_lightbrand6")
                switcher.backgroundColor = UIColor.themColor(named: "ai_line2")
            } else {
                switcher.isEnabled = false
                switcher.onTintColor = UIColor.themColor(named: "ai_disable")
                switcher.backgroundColor = UIColor.themColor(named: "ai_disable")
            }
        } else {
            let state = manager.information.agentState == .unload
            switcher.isEnabled = state
            switcher.onTintColor = state ? UIColor.themColor(named: "ai_brand_lightbrand6") : UIColor.themColor(named: "ai_disable")
            switcher.backgroundColor = state ? UIColor.themColor(named: "ai_line2") : UIColor.themColor(named: "ai_disable")
        }
    }
}

