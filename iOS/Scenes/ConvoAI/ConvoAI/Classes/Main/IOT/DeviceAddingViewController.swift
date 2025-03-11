//
//  DeviceAddingViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common
import SVProgressHUD
import BLEManager

class DeviceAddingViewController: BaseViewController {
    var deviceId: String = ""
    var rssi: Int = 0
    var password: String = ""
    
    private let apiManger = IOTApiManager()
    private var bluetoothManager: AIBLEManager = .shared

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
        addDevice()
    }
    
    private func setupView() {
        navigationTitle = ResourceManager.L10n.Iot.deviceAddTitle
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        [circleBackgroundView, iconImageView].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
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
    
    private func addDevice() {
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Iot.deviceAddProgress)
        Task {
            do {
                let tokenModel = try await requestToken()
//                bluetoothManager.sendWifiInfo(BLEWifiInfo(ssid: ssid, password: password, authToken: tokenModel.auth_token))
                await MainActor.run {
                    guard let presets = AppContext.iotPresetsManager()?.allPresets(), let preset = presets.first, let language = preset.support_languages.first(where: { $0.isDefault }) else {
                        return
                    }
                    
                    AppContext.iotDeviceManager()?.addDevice(device: LocalDevice(name: "smaug123", deviceId: "\(Int.random(in: 0...1000))", rssi: rssi, currentPreset: preset, currentLanguage: language, aiVad: false))
                    showSuccessAlert()
                }
            } catch {
                showErrorAlert()
            }
        }
    }
    
    private func requestToken() async throws -> CovIotTokenModel {
        return try await withCheckedThrowingContinuation { continuation in
            apiManger.generatorToken(deviceId: deviceId) { tokenModel, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let tokenModel = tokenModel else {
                    let error = NSError(
                        domain: "DeviceAddingViewController",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Token generation failed"]
                    )
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: tokenModel)
            }
        }
    }
    
    private func showSuccessAlert() {
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
    
    private func showErrorAlert() {
        let errorAlert = IOTErrorAlertViewController { [weak self] in
            guard let self = self else { return }
            self.goToDeviceViewController()
        } onClose: { [weak self] in
            guard let self = self else { return }
            self.goToDeviceViewController()
        }

        present(errorAlert, animated: false)
    }
    
    private func goToDeviceViewController() {
        if let targetVC = self.navigationController?.viewControllers.first(where: { $0 is IOTListViewController }) {
            self.navigationController?.popToViewController(targetVC, animated: true)
        }
    }
}
