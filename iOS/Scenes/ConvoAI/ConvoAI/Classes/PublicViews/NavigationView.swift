//
//  NavigationView.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit

class NavigationView: UIView {
    
    // MARK: - Public Properties
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var titleColor: UIColor? {
        didSet {
            titleLabel.textColor = titleColor
        }
    }
    
    var titleFont: UIFont? {
        didSet {
            titleLabel.font = titleFont
        }
    }
    
    var leftButtonImage: UIImage? {
        didSet {
            leftButton.setImage(leftButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            leftButton.isHidden = leftButtonImage == nil
        }
    }
    
    var rightButtonImage: UIImage? {
        didSet {
            rightButton.setImage(rightButtonImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            rightButton.isHidden = rightButtonImage == nil
        }
    }
    
    var leftButtonTintColor: UIColor? {
        didSet {
            leftButton.tintColor = leftButtonTintColor
        }
    }
    
    var rightButtonTintColor: UIColor? {
        didSet {
            rightButton.tintColor = rightButtonTintColor
        }
    }
    
    var onLeftButtonTapped: (() -> Void)?
    var onRightButtonTapped: (() -> Void)?
    
    // MARK: - Private Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.themColor(named: "ai_brand_black10")
        return label
    }()
    
    private lazy var leftButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = UIColor.themColor(named: "ai_brand_black10")
        button.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var rightButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = UIColor.themColor(named: "ai_brand_black10")
        button.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line1")
        return view
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(separatorLine)
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(snp.bottom).offset(-22)
            make.left.greaterThanOrEqualTo(leftButton.snp.right).offset(10)
            make.right.lessThanOrEqualTo(rightButton.snp.left).offset(-10)
        }
        
        leftButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        rightButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        separatorLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    // MARK: - Actions
    
    @objc private func leftButtonTapped() {
        onLeftButtonTapped?()
    }
    
    @objc private func rightButtonTapped() {
        onRightButtonTapped?()
    }
}

