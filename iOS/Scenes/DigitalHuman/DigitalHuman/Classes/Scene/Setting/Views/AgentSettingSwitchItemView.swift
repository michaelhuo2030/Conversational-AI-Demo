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
        addSubview(titleLabel)
        
        bottomLine.backgroundColor = PrimaryColors.c_27272a_a
        addSubview(bottomLine)
        
        addSubview(switcher)
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
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
}
