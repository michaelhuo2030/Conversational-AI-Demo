//
//  AgentSettingView.swift
//  Agent
//
//  Created by HeZhengQing on 2024/9/30.
//

import UIKit
import SwifterSwift
import Common

class AgentSettingInfoItemView: UIView {
    let titleLabel = UILabel()
    let detialLabel = UILabel()
    let bottomLine = UIView()
    let botton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgentSettingInfoItemView {
    private func createViews() {
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        addSubview(titleLabel)
        
        detialLabel.textColor = UIColor.themColor(named: "ai_icontext3")
        addSubview(detialLabel)
        
        bottomLine.backgroundColor = UIColor.themColor(named: "ai_line1")
        addSubview(bottomLine)
        
        addSubview(botton)
    }
    
    private func createConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        detialLabel.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
        botton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
