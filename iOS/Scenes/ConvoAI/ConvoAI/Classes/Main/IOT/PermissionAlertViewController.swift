//
//  PermissionAlertViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit
import Common

class PermissionAlertViewController: UIViewController {
    
    // MARK: - Properties
    
    private var permissions: [Permission] = []
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "开启权限和开关"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "需要开启以下权限和开关，用于添加附近设备"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var permissionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_iot_close_icon"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    
    init(permissions: [Permission]) {
        self.permissions = permissions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPermissionCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(permissionsStackView)
        containerView.addSubview(closeButton)
        
        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            // 高度会根据内容自适应
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.centerX.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        permissionsStackView.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(-30)
        }
    }
    
    private func setupPermissionCards() {
        permissions.forEach { permission in
            let cardView = createPermissionCard(permission: permission)
            permissionsStackView.addArrangedSubview(cardView)
        }
    }
    
    private func createPermissionCard(permission: Permission) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = UIColor.themColor(named: "ai_fill2")
        cardView.layer.cornerRadius = 12
        
        let iconBackground = UIView()
        iconBackground.backgroundColor = permission.iconBackgroundColor
        iconBackground.layer.cornerRadius = 20
        
        let iconImageView = UIImageView()
        iconImageView.image = permission.icon
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = permission.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        
        let goButton = UIButton(type: .custom)
        goButton.setTitle("去开启", for: .normal)
        goButton.setTitleColor(.white, for: .normal)
        goButton.titleLabel?.font = .systemFont(ofSize: 14)
        goButton.backgroundColor = UIColor.themColor(named: "ai_brand_main6")
        goButton.layer.cornerRadius = 15
        goButton.addTarget(self, action: #selector(goButtonTapped(_:)), for: .touchUpInside)
        
        cardView.addSubview(iconBackground)
        iconBackground.addSubview(iconImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(goButton)
        
        iconBackground.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconBackground.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        
        goButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        
        cardView.snp.makeConstraints { make in
            make.height.equalTo(72)
        }
        
        return cardView
    }
    
    // MARK: - Animations
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }, completion: { _ in
            completion()
        })
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }
    
    @objc private func goButtonTapped(_ sender: UIButton) {
        // Handle permission request
        if let index = permissionsStackView.arrangedSubviews.firstIndex(where: { $0.subviews.contains(sender) }) {
            let permission = permissions[index]
            permission.action()
        }
    }
}

// MARK: - Permission Model

extension PermissionAlertViewController {
    struct Permission {
        let icon: UIImage?
        let iconBackgroundColor: UIColor
        let title: String
        let action: () -> Void
    }
}
