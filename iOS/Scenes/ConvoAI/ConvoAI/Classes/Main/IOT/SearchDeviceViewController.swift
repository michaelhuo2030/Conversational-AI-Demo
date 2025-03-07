//
//  SearchDeviceViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import Foundation
import Common
import CoreBluetooth
import BLEManager

class SearchDeviceViewController: BaseViewController {
    private var bluetoothManager: AIBLEManager = .shared

    private lazy var searchingView:SearchingView = {
        let rippleView = SearchingView(frame: CGRectMake(0, naviBar.height, view.bounds.width, view.bounds.height - naviBar.height))
        rippleView.delegate = self
        return rippleView
    }()
    
    private lazy var searchFailedView: DeviceSearchFailedView = {
        let view = DeviceSearchFailedView()
        view.delegate = self
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.estimatedRowHeight = 160
        tableView.rowHeight = 90
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private var devices: [IOTDevice] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bluetoothManager.deviceConnectTimeout = 10
        setupViews()
        setupConstraints()
        startSearchDevice()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluetoothManager.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bluetoothManager.delegate = nil
    }
    
    private func startSearchDevice() {
        bluetoothManager.startScan()
    }
    
    private func setupViews() {
        navigationTitle = "扫描附近设备"
        naviBar.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.clipsToBounds = true
        
        [searchingView, tableView, searchFailedView].forEach { view.addSubview($0) }
        
        searchingView.startSearch()
        searchFailedView.isHidden = true
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalTo(0)
        }
        
        searchFailedView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalTo(0)
        }
    }
    
    private func showWifiAlert() {
        let permissions = [
            PermissionAlertViewController.Permission(
                icon: UIImage.ag_named("ic_iot_wifi_white_icon"),
                iconBackgroundColor: UIColor.themColor(named: "ai_brand_white2"),
                cardBackgroundColor: UIColor.themColor(named: "ai_green6"),
                title: "请打开Wi-Fi",
                action: {
                    // Open Location Settings
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            )
        ]

        let alertVC = PermissionAlertViewController(
            title: "开启开关",
            description: "需开启Wi-Fi开关，用于添加附近设备",
            permissions: permissions
        )
        present(alertVC, animated: false)
    }
}

extension SearchDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        let index = indexPath.row
        let device = devices[index]
        cell.configData(device: device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = IOTWifiSettingViewController()
        self.navigationController?.pushViewController(vc)
//        showWifiAlert()
    }
}

extension SearchDeviceViewController: SearchingViewDelegate, DeviceSearchFailedViewDelegate {
    func searchTimeout() {
        searchFailedView.isHidden = false
        searchingView.isHidden = true
    }
    
    func researchCallback() {
        searchFailedView.isHidden = true
        searchingView.isHidden = false
        searchingView.startSearch()
    }
}

extension SearchDeviceViewController: BLEManagerDelegate {
    func bleManagerOnDevicConfigStateChanged(manager: AIBLEManager, oldState: AIBLEManager.DeviceConfigState, newState: AIBLEManager.DeviceConfigState) {
        switch newState {
        case .readyToScanDevices:
            bluetoothManager.startScan()
        case .deviceConnected:
            // 步骤3 - 蓝牙连接成功
            print("deviceConnected")
        case .wifiConfiguration:
            print("show load...")
        case .wifiConfigurationDone:
            print("dismiss load...")
        default:
            print("state = \(newState)")
        }
    }
    
    func bleManagerDidScanDevice(_ manager: AIBLEManager, device: BLEDevice, error: Error?) {
        if let data = device.data[CBAdvertisementDataManufacturerDataKey] as? Data {
            if bluetoothManager.bekenDeviceManufacturerData == data {
                if !devices.contains(where: { $0.deviceId == device.id.uuidString }) {
                    let iotDevice = IOTDevice(name: device.name, deviceId: device.id.uuidString, rssi: device.rssi, data: device.data)
                    devices.append(iotDevice)
                    tableView.reloadData()
                }
            }
        }
    }
}
