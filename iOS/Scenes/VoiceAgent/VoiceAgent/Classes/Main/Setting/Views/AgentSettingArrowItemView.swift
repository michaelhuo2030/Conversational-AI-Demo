//
//  AgentSettingView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import UIKit
import Common

class AgentSettingArrowItemView: UIView {
    let titleLabel = UILabel()
    let detialLabel = UILabel()
    let imageView = UIImageView(image: UIImage.va_named("ic_agent_setting_arrow"))
    let bottomLine = UIView()
    let button = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgentSettingArrowItemView {
    private func createViews() {
        self.backgroundColor = PrimaryColors.c_1d1d1d
        titleLabel.textColor = UIColor(hex:0xFFFFFF)
        addSubview(titleLabel)
        
        detialLabel.textColor = PrimaryColors.c_ffffff_a
        addSubview(detialLabel)
        
        addSubview(imageView)
        
        bottomLine.backgroundColor = UIColor(hex:0x545456, transparency: 0.34)
        addSubview(bottomLine)
        
        addSubview(button)
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        detialLabel.snp.makeConstraints { make in
            make.right.equalTo(imageView.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
}
