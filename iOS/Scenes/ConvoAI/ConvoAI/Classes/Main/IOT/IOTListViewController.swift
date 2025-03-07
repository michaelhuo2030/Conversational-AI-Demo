//
//  IOTListViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit
import SVProgressHUD
import Common

class IOTListViewController: BaseViewController {
    // MARK: - Properties
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(IOTDeviceCell.self, forCellReuseIdentifier: "IOTDeviceCell")
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = UITableView.automaticDimension
        tableView.allowsSelection = false
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private lazy var emptyView: EmptyDeviceView = {
        let view = EmptyDeviceView()
        view.isHidden = true
        view.onAddDeviceButtonTapped = { [weak self] in
            let vc = DeviceIntroductionViewController()
            self?.navigationController?.pushViewController(vc)
        }
        return view
    }()
    
    private lazy var devices: [IOTDevice] = {
        var data = AppContext.iotPreferenceManager()?.allDevices()
        return data ?? []
    }()
    
    // MARK: - Lifecycle
    deinit {
        unregisterDelegage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    // MARK: - Private Methods
    
    private func registerDelegate() {
        AppContext.iotPreferenceManager()?.addDelegate(self)
    }
    
    private func unregisterDelegage() {
        AppContext.iotPreferenceManager()?.removeDelegate(self)
    }
    
    private func setupViews() {
        navigationTitle = "声网IOT设备"
        naviBar.setRightButtonTarget(self, action: #selector(navigationRightButtonTapped), image: UIImage.ag_named("ic_iot_bar_add_icon"))
        
        view.addSubview(tableView)
        view.addSubview(emptyView)
        
        updateViewsVisibility()
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateViewsVisibility() {
        let isEmpty = devices.isEmpty
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        naviBar.rightButton.isHidden = isEmpty
    }
    
    private func addDevice(device: IOTDevice) {
        // Insert at the beginning of the array
        devices.insert(device, at: 0)
        
        tableView.reloadData()
        
        // Show a success message
        SVProgressHUD.showSuccess(withStatus: "设备添加成功")
        
        updateViewsVisibility()
    }
    
    // MARK: - Actions
    override func navigationRightButtonTapped() {
         let vc = AddIotDeviceViewController()
         self.navigationController?.pushViewController(vc)
    }
    
    @objc private func addDeviceButtonTapped() {
        let vc = DeviceIntroductionViewController()
        self.navigationController?.pushViewController(vc)
    }
    
    private func showRenameAlert(for device: IOTDevice) {
        let alert = UIAlertController(
            title: "修改设备名称",
            message: nil,
            preferredStyle: .alert
        )
        
        // Add text field
        alert.addTextField { textField in
            textField.text = device.name
            textField.clearButtonMode = .whileEditing
            textField.returnKeyType = .done
        }
        
        // Add cancel action
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        // Add confirm action
        let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            // Update device name
            AppContext.iotPreferenceManager()?.updateDeviceName(deviceId: device.deviceId, newName: newName)
        }
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension IOTListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IOTDeviceCell", for: indexPath) as! IOTDeviceCell
        let index = indexPath.row
        let device = devices[index]
        cell.selectionStyle = .none
        cell.configData(device: device, index: index)
        cell.onTitleTapped = { [weak self] in
            self?.showRenameAlert(for: device)
        }
        
        cell.onSettingsTapped = { [weak self] in
            let settingsVC = IOTSettingViewController()
            self?.present(settingsVC, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension IOTListViewController: IOTPreferenceManagerDelegate {
    func preferenceManager(_ manager: IOTPreferenceManager, didAddedDevice device: IOTDevice) {
        addDevice(device: device)
        updateViewsVisibility()
    }
    
    func preferenceManager(_ manager: IOTPreferenceManager, didUpdatedDevice device: IOTDevice) {
        if let index = devices.firstIndex(where: { $0.deviceId == device.deviceId }) {
            devices[index] = device
            tableView.reloadData()
            SVProgressHUD.showSuccess(withStatus: "设备名称已更新")
        }
    }
    
    func preferenceManager(_ manager: IOTPreferenceManager, didRemovedDevice device: IOTDevice) {
        if let index = devices.firstIndex(where: { $0.deviceId == device.deviceId }) {
            devices.remove(at: index)
            tableView.reloadData()
            updateViewsVisibility()
        }
    }
}
