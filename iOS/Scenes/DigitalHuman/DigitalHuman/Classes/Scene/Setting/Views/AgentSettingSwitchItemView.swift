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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgentSettingSwitchItemView {
    private func createViews() {
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
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview().offset(-10)
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
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }
    
    func updateLayout() {
        if let text = detailLabel.text, !text.isEmpty {
            detailLabel.isHidden = false
            titleLabel.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(-10)
            }
        } else {
            detailLabel.isHidden = true
            titleLabel.snp.updateConstraints { make in
                make.centerY.equalToSuperview()
            }
        }
    }
}
