//
//  AgentSettingSubOptionCell.swift
//  Agent
//
//  Created by Jonathan on 2024/10/1.
//

import UIKit
import Common

class AgentSettingSubOptionCell: UITableViewCell {
    private lazy var checkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.va_named("ic_agent_setting_sel"))
        imageView.isHidden = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = PrimaryColors.c_ffffff_a
        label.font = .systemFont(ofSize: 15)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = UIColor.themColor(named: "ai_line1")
        selectionStyle = .none
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(checkImageView)
        checkImageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
    }
    
    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        checkImageView.isHidden = !isSelected
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
