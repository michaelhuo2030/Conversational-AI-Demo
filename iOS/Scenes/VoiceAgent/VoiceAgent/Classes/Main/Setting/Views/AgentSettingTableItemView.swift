//
//  AgentSettingView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import UIKit
import Common

class AgentSettingTableItemView: UIView {
    let titleLabel = UILabel()
    let detialLabel = UILabel()
    let imageView = UIImageView(image: UIImage.va_named("ic_agent_setting_tab"))
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
    
    @objc func onClickButton(_ sender: UIButton) {
        print("click button")
    }
}

extension AgentSettingTableItemView {
    private func createViews() {
        self.backgroundColor = PrimaryColors.c_1d1d1d

        titleLabel.textColor = PrimaryColors.c_ffffff
        addSubview(titleLabel)
        
        detialLabel.textColor = PrimaryColors.c_ffffff_a
        addSubview(detialLabel)
        
        addSubview(imageView)
        
        bottomLine.backgroundColor = PrimaryColors.c_27272a_a
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
            make.right.equalTo(imageView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }
        button.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    
    func bottomLineStyle2() {
        bottomLine.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }
    }
    
}
