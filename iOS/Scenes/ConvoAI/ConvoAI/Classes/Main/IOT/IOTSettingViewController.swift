//
//  IOTSettingViewController.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/6.
//

import UIKit
import Common

class IOTSettingViewController: UIViewController {
    
    // MARK: - Properties
    
    private let languages = ["简体中文", "English", "日本語"]
    
    private var selectedPresetIndex: Int = 0 // Track current selected preset index
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.ag_named("iot_setting_close_icon"), for: .normal)
        button.backgroundColor = UIColor.themColor(named: "ai_block1")
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "配置"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.bounces = false  // Disable bouncing effect
        scrollView.alwaysBounceVertical = false  // Disable vertical bounce
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
        
    private lazy var presetLabel: UILabel = {
        let label = UILabel()
        label.text = "预设人设"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor.themColor(named: "ai_icontext4")
        return label
    }()
    
    private lazy var presetContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_fill1")
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        return view
    }()
    
    private lazy var presetStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    
    private lazy var languageCell: SettingCell = {
        let cell = SettingCell()
        cell.titleLabel.text = "Language"
        cell.detailLabel.text = "English"
        cell.addTarget(self, action: #selector(languageCellTapped), for: .touchUpInside)
        return cell
    }()
    
    private lazy var advancedLabel: UILabel = {
        let label = UILabel()
        label.text = "Advanced Settings"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.themColor(named: "ai_icontext2")
        return label
    }()
    
    private lazy var interruptSwitch: SettingCell = {
        let cell = SettingCell()
        cell.titleLabel.text = "启用 优雅打断"
        cell.setupAsSwitch()
        return cell
    }()
    
    private lazy var reconnectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("重新配网", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.themColor(named: "ai_block2")
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(reconnectButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("删除设备", for: .normal)
        button.setTitleColor(UIColor.themColor(named: "ai_brand_white10"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.backgroundColor = UIColor.themColor(named: "ai_red6")
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line2")
        view.layer.cornerRadius = 1.5
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupPresetModes()
        
        // Disable interactive dismissal
        isModalInPresentation = true
    }
    
    // MARK: - UI Setup
    
    private func setupViews() {
        view.backgroundColor = .clear
                
        view.addSubview(containerView)
        containerView.addSubview(grabberView)
        containerView.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(presetContainerView)
        presetContainerView.addSubview(presetStackView)
        
        [presetLabel, presetContainerView, languageCell, advancedLabel, interruptSwitch, reconnectButton, deleteButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(view.snp.height).multipliedBy(0.85)
        }
        
        grabberView.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.centerX.equalToSuperview()
            make.width.equalTo(36)
            make.height.equalTo(3)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.right.equalTo(-16)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(32)
            make.left.equalTo(20)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        presetLabel.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.left.equalTo(20)
        }
        
        presetContainerView.snp.makeConstraints { make in
            make.top.equalTo(presetLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
        }
        
        presetStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        languageCell.snp.makeConstraints { make in
            make.top.equalTo(presetStackView.snp.bottom).offset(24)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        advancedLabel.snp.makeConstraints { make in
            make.top.equalTo(languageCell.snp.bottom).offset(24)
            make.left.equalTo(20)
        }
        
        interruptSwitch.snp.makeConstraints { make in
            make.top.equalTo(advancedLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        reconnectButton.snp.makeConstraints { make in
            make.top.equalTo(interruptSwitch.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(reconnectButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalTo(-30)
        }
    }
    
    private func setupPresetModes() {
        guard let presets = AppContext.iotPreferenceManager()?.allPresets() else { return }
        
        for (index, preset) in presets.enumerated() {
            let cell = createPresetModeCell(
                title: preset.display_name,
                description: preset.preset_brief,
                isSelected: index == 0,  // 第一个默认选中
                isLastCell: index == presets.count - 1,  // 最后一个设置为 isLastCell
                index: index
            )
            presetStackView.addArrangedSubview(cell)
        }
    }
    
    private func createPresetModeCell(
        title: String,
        description: String,
        isSelected: Bool = false,
        isLastCell: Bool = false,
        index: Int
    ) -> PresetModeCell {
        let cell = PresetModeCell()
        cell.configure(title: title, description: description, isSelected: isSelected, isLastCell: isLastCell)
        cell.tag = index
        cell.onCheckChanged = { [weak self] isSelected in
            self?.handlePresetSelection(at: index, isSelected: isSelected)
        }
        return cell
    }
    
    private func handlePresetSelection(at index: Int, isSelected: Bool) {
        guard isSelected else { return } // Only handle selection event, ignore deselection
        
        // Update previously selected cell
        if let previousCell = presetStackView.arrangedSubviews[selectedPresetIndex] as? PresetModeCell {
            previousCell.setSelected(false)
        }
        
        // Update currently selected cell
        if let currentCell = presetStackView.arrangedSubviews[index] as? PresetModeCell {
            currentCell.setSelected(true)
        }
        
        selectedPresetIndex = index
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        AgentAlertView.show(in: view, title: "您是否要保存当前更改？", content: "确认更改后，会在智能设备下次联网时修改配置。", cancelTitle: "放弃更改", confirmTitle: "确认更改") { [weak self] in
            self?.dismiss(animated: true)
        } onCancel: { [weak self] in
            self?.dismiss(animated: true)
        }

    }
    
    @objc private func languageCellTapped() {
        let alert = UIAlertController(title: "选择语言", message: nil, preferredStyle: .actionSheet)
        
        languages.forEach { language in
            let action = UIAlertAction(title: language, style: .default) { [weak self] _ in
                self?.languageCell.detailLabel.text = language
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func reconnectButtonTapped() {
        // Handle reconnect
    }
    
    @objc private func deleteButtonTapped() {
        // Handle delete
        AgentAlertView.show(in: view, title: "您是否要删除大聪明？", content: "删除后，将不能更改它的对话设定。是否继续删除？",cancelTitle: "取消", confirmTitle: "删除", onConfirm: {
            
        })
    }
}

// MARK: - SettingCell
private class SettingCell: UIControl {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    let detailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.themColor(named: "ai_line1").cgColor
        view.backgroundColor = UIColor.themColor(named: "ai_block2")

        return view
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.ag_named("ic_iot_arrow_right")
        return imageView
    }()
    
    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor.themColor(named: "ai_brand_main6")
        return switchControl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(detailLabel)
        containerView.addSubview(arrowImageView)
        
        containerView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.bottom.equalTo(0)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        
        detailLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowImageView.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }
    
    @objc func switcherValueChanged(_ sender: UISwitch) {
    }
    
    func setupAsSwitch() {
        arrowImageView.removeFromSuperview()
        detailLabel.removeFromSuperview()
        
        containerView.addSubview(switchControl)
        switchControl.onTintColor = UIColor.themColor(named: "ai_brand_lightbrand6")
        switchControl.backgroundColor = UIColor.themColor(named: "ai_brand_white10")
        switchControl.layer.cornerRadius = switchControl.frame.height / 2
        switchControl.clipsToBounds = true
        switchControl.addTarget(self, action: #selector(switcherValueChanged(_:)), for: .valueChanged)
        
        switchControl.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    func setupAsDeviceName() {
        arrowImageView.removeFromSuperview()
        detailLabel.removeFromSuperview()
        
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - PresetModeCell
private class PresetModeCell: UIView {
    var onCheckChanged: ((Bool) -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_block2")
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.themColor(named: "ai_icontext1")
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor.themColor(named: "ai_icontext3")
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var checkmarkView: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.ag_named("ic_iot_uncheck_icon"), for: .normal)
        button.setImage(UIImage.ag_named("ic_iot_check_icon"), for: .selected)
        button.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)

        return button
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.themColor(named: "ai_line1")
        return view
    }()
    
    private lazy var overlayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
        return button
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        [titleLabel, descriptionLabel, checkmarkView, separatorLine].forEach { containerView.addSubview($0) }
        containerView.addSubview(overlayButton)
        
        checkmarkView.isUserInteractionEnabled = false
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.right.equalTo(checkmarkView.snp.left).offset(-8)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(16)
            make.right.equalTo(checkmarkView.snp.left).offset(-8)
            make.bottom.equalTo(-16)
        }
        
        checkmarkView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
        
        separatorLine.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.left.equalTo(16)
            make.height.equalTo(1)
        }
        
        overlayButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    @objc private func cellTapped() {
        // If already selected, do nothing
        guard !checkmarkView.isSelected else { return }
        
        checkmarkView.isSelected = true
        onCheckChanged?(true)
    }
    
    func setSelected(_ selected: Bool) {
        checkmarkView.isSelected = selected
    }
    
    func configure(title: String, description: String, isSelected: Bool, isLastCell: Bool = false) {
        titleLabel.text = title
        descriptionLabel.text = description
        checkmarkView.isSelected = isSelected
        separatorLine.isHidden = isLastCell
    }
}
