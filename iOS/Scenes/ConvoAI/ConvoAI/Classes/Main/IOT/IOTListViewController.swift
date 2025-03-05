//
//  IOTListViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/4.
//

import UIKit

struct Device {
    let title: String
    let description: String
}

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
    
    private var devices: [Device] = [
        Device(title: "Agora X1", description: "客厅智能音箱"),
        Device(title: "Agora X2", description: "卧室智能音箱"),
        Device(title: "Agora X3", description: "书房智能音箱"),
        Device(title: "Agora X1 Pro", description: "办公室智能音箱"),
        Device(title: "Agora X2 Plus", description: "会议室智能音箱")
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationTitle = "声网IOT设备"
        naviBar.setRightButtonTarget(self, action: #selector(navigationRightButtonTapped), image: UIImage.ag_named("ic_iot_bar_add_icon"))
        setupUI()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(naviBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Actions
    
    override func navigationRightButtonTapped() {
        let vc = AddIotDeviceViewController()
        self.navigationController?.pushViewController(vc)
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
        cell.configData(device: device, index: index)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}
