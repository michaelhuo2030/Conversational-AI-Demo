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
        self.backgroundColor = PrimaryColors.c_1d1d1d

        titleLabel.textColor = PrimaryColors.c_ffffff
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        addSubview(titleLabel)
        
        detailLabel.textColor = PrimaryColors.c_ffffff_a
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        addSubview(detailLabel)
        
        bottomLine.backgroundColor = PrimaryColors.c_27272a_a
        addSubview(bottomLine)
        
        addSubview(switcher)
        
        switcher.onTintColor = PrimaryColors.c_a0faff
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
}
