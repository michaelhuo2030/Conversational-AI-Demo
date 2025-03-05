//
//  AddIotDeviceViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit

class AddIotDeviceViewController: BaseViewController {
    
    // MARK: - UI Components
    private lazy var circleBackgroundView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var rightCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line2")
        return view
    }()
    
    private lazy var leftCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line2")
        return view
    }()
    
    private lazy var mascotImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_mascot_icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "欢迎"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "让我们现在添加设备吧"
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_arrow_icon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.themColor(named: "ai_icontext1")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var addDeviceButton: CustomButtonView = {
        var view = CustomButtonView()
        view.startButton.setTitle("添加设备", for: .normal)
        view.startButton.setImage(UIImage.ag_named("ic_iot_bar_add_icon"), for: .normal)
        view.startButton.addTarget(self, action: #selector(addDeviceButtonTapped), for: .touchUpInside)
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationTitle = "对话式 AI 设备"
        setupUI()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Add subviews
        view.addSubview(circleBackgroundView)
        circleBackgroundView.addSubview(leftCircleView)
        circleBackgroundView.addSubview(rightCircleView)
        view.addSubview(mascotImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(arrowImageView)
        view.addSubview(addDeviceButton)
        
        // Setup constraints
        circleBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.equalTo(0)
            make.height.equalTo(368)
        }
        
        let screenWidth = UIScreen.main.bounds.width
        let circleWidth = screenWidth * (240.0 / 375.0)
        let cornerRadius = circleWidth / 2
        
        rightCircleView.layer.cornerRadius = cornerRadius
        leftCircleView.layer.cornerRadius = cornerRadius
        
        rightCircleView.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.top.equalTo(0)
            make.size.equalTo(CGSize(width: circleWidth, height: circleWidth))
        }
        
        leftCircleView.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.bottom.equalTo(0)
            make.size.equalTo(CGSize(width: circleWidth, height: circleWidth))
        }
        
        mascotImageView.snp.makeConstraints { make in
            make.center.equalTo(circleBackgroundView)
            make.size.equalTo(CGSize(width: 181, height: 255))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(circleBackgroundView.snp.bottom)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        addDeviceButton.snp.makeConstraints { make in
            make.bottom.equalTo(-58)
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.height.equalTo(58)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addDeviceButtonTapped() {
        // Handle add device button tap
        let vc = DeviceIntroductionViewController()
        self.navigationController?.pushViewController(vc)
    }
}
