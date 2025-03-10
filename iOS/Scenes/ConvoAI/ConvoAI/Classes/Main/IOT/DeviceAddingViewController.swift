//
//  DeviceAddingViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common
import SVProgressHUD

class DeviceAddingViewController: BaseViewController {
    private lazy var circleBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block1")
        view.layer.cornerRadius = 225 / 2.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage.ag_named("ic_iot_mascot_icon")
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupConstraints()
        
        //TODO: Complete the code.
//        guard let presets = AppContext.iotPresetsManager()?.allPresets(), let defaultPreset = presets.first, let defaultLanguage = defaultPreset.support_languages.first(where: {$0.isDefault}) else { return }
//        let localDevice = LocalDevice(name: "smaug", deviceId: "123", rssi: 123, currentPreset: defaultPreset, currentLanguage: defaultLanguage, aiVad: false)
//        
//        AppContext.iotDeviceManager()?.addDevice(device: localDevice)
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Iot.deviceAddProgress)
        testErrorAlert()
    }
    
    private func requestData() {
        
    }
    
    func testSuccessAlert() {
        TimeoutAlertView.show(
            in: view,
            image: UIImage.ag_named("ic_alert_success_icon"),
            title: ResourceManager.L10n.Iot.deviceAddSuccessTitle,
            description: ResourceManager.L10n.Iot.deviceAddSuccessDescription
        ) { [weak self] in
            guard let self = self else { return }
            
            // Find and pop to IOTListViewController
            if let targetVC = self.navigationController?.viewControllers.first(where: { $0 is IOTListViewController }) {
                self.navigationController?.popToViewController(targetVC, animated: true)
            }
        }
    }
    
    func testErrorAlert() {
        let errorAlert = IOTErrorAlertViewController { [weak self] in
            guard let self = self else { return }

            if let targetVC = self.navigationController?.viewControllers.first(where: { $0 is IOTListViewController }) {
                self.navigationController?.popToViewController(targetVC, animated: true)
            }
        }
        present(errorAlert, animated: false)
    }
    
    func setupView() {
        navigationTitle = ResourceManager.L10n.Iot.deviceAddTitle
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        [circleBackgroundView, iconImageView].forEach { view.addSubview($0) }
    }
    
    func setupConstraints() {
        circleBackgroundView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom).offset(121)
            make.width.height.equalTo(225)
            make.centerX.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalTo(circleBackgroundView)
            make.width.equalTo(119)
            make.height.equalTo(168)
        }
    }
}
