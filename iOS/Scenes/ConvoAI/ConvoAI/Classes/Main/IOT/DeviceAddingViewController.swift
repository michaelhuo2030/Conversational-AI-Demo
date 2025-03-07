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
        
        SVProgressHUD.showInfo(withStatus: "添加设备中...")
        testErrorAlert()
    }
    
    func testSuccessAlert() {
        TimeoutAlertView.show(
            in: view,
            image: UIImage.ag_named("ic_alert_success_icon"),
            title: "添加成功",
            description: "注意：设备添加信息将在本地保存，重新安装app后需要重新添加设备。"
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
        navigationTitle = "添加设备中"
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
