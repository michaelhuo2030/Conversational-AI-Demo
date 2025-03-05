//
//  IotDeviceCardView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit

class IotDeviceCardView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 25
        if let image = UIImage.ag_named("ic_iot_card_edit_icon") {
            button.setImage(image, for: .normal)
        }
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        button.setBackgroundColor(color: UIColor.themColor(named: "ai_brand_white6"), forState: .normal)
        return button
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    var onSettingsTapped: (() -> Void)?
    
    var settingsIcon: UIImage? {
        didSet {
            settingsButton.setImage(settingsIcon, for: .normal)
        }
    }
    
    var backgroundImage: UIImage? {
        didSet {
            backgroundImageView.image = backgroundImage
        }
    }
    
    var settingsButtonBackgroundColor: UIColor? {
        didSet {
            settingsButton.backgroundColor = settingsButtonBackgroundColor
        }
    }
    
    var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    var subtitleFont: UIFont? {
        didSet {
            subtitleLabel.font = subtitleFont
        }
    }
    
    var subtitleColor: UIColor? {
        didSet {
            subtitleLabel.textColor = subtitleColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(backgroundImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(settingsButton)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(24)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(titleLabel)
        }
        
        settingsButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 50, height: 50))
        }
    }
    
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    @objc private func settingsButtonTapped() {
        onSettingsTapped?()
    }
}
