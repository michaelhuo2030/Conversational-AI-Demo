//
//  ViewController.swift
//  Agent
//  
//  Created by HeZhengQing on 2024/9/29.
//

import UIKit
import SnapKit
import AgoraRtcKit
import SwifterSwift
import Common
import DigitalHuman
import VoiceAgent
import SVProgressHUD

class AgentHomeViewController: UIViewController {
    private lazy var nextStepButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Main.getStart, for: .normal)
        button.addTarget(self, action: #selector(onClickNextStep), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.themColor(named: "ai_icontext1"), for: .normal)
        button.layerCornerRadius = 29
        button.clipsToBounds = true
        button.setBackgroundColor(color: UIColor(hex: "#0097D4")!, forState: .normal)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private lazy var testSSOButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(ssoLogin), for: .touchUpInside)
        button.backgroundColor = .white
        button.setTitle("SSO", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    private lazy var titleImageView: UIImageView = {
        let imageView = UIImageView()
        if AppContext.shared.appArea == .mainland {
            imageView.image = UIImage.ag_named("ic_shengwang_icon")?.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = UIColor.themColor(named: "ai_icontext1")
        } else {
            imageView.image = UIImage.ag_named("ic_agent_home_agora")
        }
        return imageView
    }()

    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(onClickLogo(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var centerImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.ag_named("ic_agent_home_center"))
        return imageView
    }()

    private lazy var privacyCheckBox: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_checkbox_unchecked"), for: .normal)
        button.setImage(UIImage.ag_named("ic_checkbox_checked"), for: .selected)
        button.addTarget(self, action: #selector(onPrivacyCheckBoxClicked), for: .touchUpInside)
        return button
    }()

    private lazy var privacyLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Main.agreeTo
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private lazy var termsButton: UIButton = {
        let button = UIButton(type: .custom)
        let attributedString = NSAttributedString(
            string: ResourceManager.L10n.Main.termsService,
            attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 14)
            ]
        )
        button.setAttributedTitle(attributedString, for: .normal)
        button.addTarget(self, action: #selector(onTermsClicked), for: .touchUpInside)
        return button
    }()
    
    private lazy var devModeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("ic_setting_debug"), for: .normal)
        button.isHidden = !DeveloperModeViewController.getDeveloperMode()
        button.addTarget(self, action: #selector(onClickDevMode), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressDevMode(_:)))
        button.addGestureRecognizer(longPressGesture)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    @objc func onClickNextStep() {
        let vc = AgentSceneViewController()
        self.navigationController?.pushViewController(vc)
    }
    
    private func addLog(_ txt: String) {
        print(txt)
    }
    
    var clickCount = 0
    var lastClickTime: Date?
    @objc private func onClickLogo(_ sender: UIButton) {
        let currentTime = Date()
        if let lastTime = lastClickTime, currentTime.timeIntervalSince(lastTime) > 1.0 {
            clickCount = 0
        }
        lastClickTime = currentTime
        clickCount += 1
        if clickCount >= 5 {
            onThresholdReached()
            clickCount = 0
        }
    }
    
    @objc private func onLongPressDevMode(_ sender: UILongPressGestureRecognizer) {
        devModeButton.isHidden = true
        DeveloperModeViewController.setDeveloperMode(false)
    }
    
    @objc func onClickDevMode() {
        DeveloperModeViewController.show(
            from: self,
            audioDump: false,
            serverHost: "", onCloseDevMode: {
                self.devModeButton.isHidden = true
            })
    }
    
    func onThresholdReached() {
        devModeButton.isHidden = false
        DeveloperModeViewController.setDeveloperMode(true)
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return url.scheme != nil && url.host != nil
        }
        return false
    }
    
    // MARK: - Create
    private func setupViews() {
        view.addSubview(titleImageView)
        view.addSubview(centerImageView)
        view.addSubview(titleButton)
        view.addSubview(devModeButton)
        view.addSubview(nextStepButton)
        view.addSubview(privacyCheckBox)
        view.addSubview(privacyLabel)
        view.addSubview(termsButton)
        view.addSubview(testSSOButton)
    }

    private func setupConstraints() {
        view.backgroundColor = UIColor(hex: 0x111111)
        testSSOButton.snp.makeConstraints { make in
            make.top.equalTo(200)
            make.left.equalTo(0)
            make.width.equalTo(100)
            make.height.equalTo(45)
        }
        titleImageView.snp.makeConstraints { make in
            make.top.equalTo(80)
            make.width.equalTo(100)
            make.height.equalTo(60)
            make.centerX.equalToSuperview()
        }
        centerImageView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(390)
            make.centerX.equalTo(self.view)
            make.top.equalTo(titleImageView.snp.bottom).offset(140)
            make.height.equalTo(centerImageView.snp.width).multipliedBy(180.0/390.0)
        }
        
        titleButton.snp.makeConstraints { make in
            make.edges.equalTo(centerImageView)
        }
        
        nextStepButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
            make.height.equalTo(58)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        
        privacyCheckBox.snp.makeConstraints { make in
            make.bottom.equalTo(nextStepButton.snp.top).offset(-52)
            make.width.height.equalTo(24)
        }
        
        privacyLabel.snp.makeConstraints { make in
            make.centerY.equalTo(privacyCheckBox)
            make.left.equalTo(privacyCheckBox.snp.right).offset(8)
        }
        
        termsButton.snp.makeConstraints { make in
            make.centerY.equalTo(privacyCheckBox)
            make.left.equalTo(privacyLabel.snp.right).offset(4)
        }
        
        privacyLabel.setContentHuggingPriority(.required, for: .horizontal)
        termsButton.setContentHuggingPriority(.required, for: .horizontal)
        
        privacyCheckBox.snp.makeConstraints { make in
            make.right.equalTo(privacyLabel.snp.left).offset(-8)
            make.centerX.equalToSuperview().offset(-((24 + 8 + privacyLabel.intrinsicContentSize.width + 4 + termsButton.intrinsicContentSize.width) / 2))
        }
        
        devModeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(-20)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
    }

    @objc private func onPrivacyCheckBoxClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        nextStepButton.isEnabled = sender.isSelected
        nextStepButton.alpha = sender.isSelected ? 1.0 : 0.5
    }

    @objc private func onTermsClicked() {
        let webVC = TermsServiceWebViewController()
        self.navigationController?.pushViewController(webVC)
    }
    
    @objc func ssoLogin() {
        let ssoWebVC = SSOWebViewController()
        let baseUrl = AppContext.shared.baseServerUrl
        ssoWebVC.urlString = "\(baseUrl)/v1/convoai/sso/login"
        ssoWebVC.completionHandler = { [weak self] token in
            if let token = token {
                print("Received token: \(token)")
                let model = LoginModel()
                model.token = token
                UserCenter.shared.storeUserInfo(model)
                LoginApiService.getUserInfo { [weak self] error in
                    guard let self = self else { return }
                    
                    if let err = error {
                        UserCenter.shared.logout()
                        SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                print("Failed to get token")
            }
        }
        navigationController?.pushViewController(ssoWebVC, animated: true)
    }
}

