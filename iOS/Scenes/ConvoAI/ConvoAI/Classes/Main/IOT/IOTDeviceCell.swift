//
//  IOTDeviceCell.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/5.
//

import UIKit

class IOTDeviceCell: UITableViewCell {
    lazy var deviceCardView: IotDeviceCardView = {
        let view = IotDeviceCardView()
        view.backgroundImage = UIImage.ag_named("ic_iot_card_bg_green")
        view.settingsButtonBackgroundColor = UIColor.themColor(named: "ai_brand_white8")
        view.layer.cornerRadius = 28
        view.layer.masksToBounds = true
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        configUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(deviceCardView)
    }
    
    func configUI() {
        deviceCardView.snp.makeConstraints { make in
            make.left.equalTo(25)
            make.right.equalTo(-25)
            make.top.equalTo(10)
            make.height.equalTo(160)
            make.bottom.equalTo(-10)
        }
    }
    
    func configData(device: Device, index: Int) {
        deviceCardView.configure(title: device.title, subtitle: device.description)
        deviceCardView.backgroundImage = index % 2 == 0 ? UIImage.ag_named("ic_iot_card_bg_green") : UIImage.ag_named("ic_iot_card_bg_blue")
    }
}
