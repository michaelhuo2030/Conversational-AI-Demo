//
//  AgentSettingVieController.swift
//  Agent
//
//  Created by qinhui on 2024/10/31.
//

import UIKit
import Common
import SVProgressHUD

class DigitalHumanSettingViewController: UIViewController {
        
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let contentView1 = UIView()
    private let infoItem = AgentSettingTableItemView(frame: .zero)
    
    private let content2Title = UILabel()
    private let contentView2 = UIView()
    private let voiceItem = AgentSettingTableItemView(frame: .zero)
    private let modelItem = AgentSettingTableItemView(frame: .zero)
    private let languageItem = AgentSettingTableItemView(frame: .zero)
    
    private let content3Title = UILabel()
    private let contentView3 = UIView()
//    private let microphoneItem = AgentSettingTableItemView(frame: .zero)
//    private let speakerItem = AgentSettingTableItemView(frame: .zero)
    private let cancellationItem = AgentSettingSwitchItemView(frame: .zero)
    
    private var selectTable: AgentSelectTableView? = nil
    private var selectTableMask = UIButton(type: .custom)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = PrimaryColors.c_171717
        createViews()
        createConstrains()
        updateUIWithCurrentSettings()
    }
    
    private func updateUIWithCurrentSettings() {
        // Update UI with current settings
        infoItem.detialLabel.text = AgentSettingManager.shared.currentPresetType.rawValue
        voiceItem.detialLabel.text = AgentSettingManager.shared.currentVoiceType.displayName
        modelItem.detialLabel.text = AgentSettingManager.shared.currentModelType.rawValue
        languageItem.detialLabel.text = AgentSettingManager.shared.currentLanguageType.rawValue
        cancellationItem.switcher.isOn = AgentSettingManager.shared.isNoiseCancellationEnabled
    }
    
    @objc func onClickClose(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc func onClickPreset(_ sender: UIButton) {
        selectTableMask.isHidden = false
        let types = AgentPresetType.availablePresets
        let currentIndex = types.firstIndex(of: AgentSettingManager.shared.currentPresetType) ?? 0
        let table = AgentSelectTableView(items: types.map {$0.rawValue}) { index in
            AgentSettingManager.shared.currentPresetType = types[index]
            self.infoItem.detialLabel.text = types[index].rawValue
        }
        table.setSelectedIndex(currentIndex)
        view.addSubview(table)
        selectTable = table
        table.snp.makeConstraints { make in
            make.top.equalTo(sender.snp.centerY)
            make.width.equalTo(table.getWith())
            make.height.equalTo(table.getHeight())
            make.right.equalTo(sender).offset(-20)
        }
    }
    
    @objc func onClickVoice(_ sender: UIButton) {
        print("onClickVoice")
        selectTableMask.isHidden = false
        let currentPreset = AgentSettingManager.shared.currentPresetType
        let types = AgentVoiceType.availableVoices(for: currentPreset)
        let currentIndex = types.firstIndex(of: AgentSettingManager.shared.currentVoiceType) ?? 0
        let table = AgentSelectTableView(items: types.map {$0.displayName}) { [weak self] index in
            guard let self = self else { return }
            AgentSettingManager.shared.currentVoiceType = types[index]
            self.voiceItem.detialLabel.text = types[index].displayName
            updateVoiceConfig()
        }
        table.setSelectedIndex(currentIndex)
        view.addSubview(table)
        selectTable = table
        table.snp.makeConstraints { make in
            make.top.equalTo(sender.snp.centerY)
            make.width.equalTo(table.getWith())
            make.height.equalTo(table.getHeight())
            make.right.equalTo(sender).offset(-20)
        }
    }
    
    @objc func onClickModel(_ sender: UIButton) {
        print("onClickModel")
        selectTableMask.isHidden = false
        let currentPreset = AgentSettingManager.shared.currentPresetType
        let types = AgentModelType.availableModels(for: currentPreset)
        let currentIndex = types.firstIndex(of: AgentSettingManager.shared.currentModelType) ?? 0
        let table = AgentSelectTableView(items: types.map {$0.rawValue}) { index in
            AgentSettingManager.shared.currentModelType = types[index]
            self.modelItem.detialLabel.text = types[index].rawValue
        }
        table.setSelectedIndex(currentIndex)
        view.addSubview(table)
        selectTable = table
        table.snp.makeConstraints { make in
            make.top.equalTo(sender.snp.centerY)
            make.width.equalTo(table.getWith())
            make.height.equalTo(table.getHeight())
            make.right.equalTo(sender).offset(-20)
        }
    }
    
    @objc func onClickLanguage(_ sender: UIButton) {
        print("onClickLanguage")
        selectTableMask.isHidden = false
        let currentPreset = AgentSettingManager.shared.currentPresetType
        let types = AgentLanguageType.availableLanguages(for: currentPreset)
        let currentIndex = types.firstIndex(of: AgentSettingManager.shared.currentLanguageType) ?? 0
        let table = AgentSelectTableView(items: types.map {$0.rawValue}) { index in
            AgentSettingManager.shared.currentLanguageType = types[index]
            self.languageItem.detialLabel.text = types[index].rawValue
        }
        table.setSelectedIndex(currentIndex)
        view.addSubview(table)
        selectTable = table
        table.snp.makeConstraints { make in
            make.top.equalTo(sender.snp.centerY)
            make.width.equalTo(table.getWith())
            make.height.equalTo(table.getHeight())
            make.right.equalTo(sender).offset(-20)
        }
    }
    
    @objc func onClickNoiseCancellation(_ sender: UISwitch) {
        AgentSettingManager.shared.isNoiseCancellationEnabled = sender.isOn
//        delegate?.onClickNoiseCancellationChanged(isOn: sender.isOn)
    }

    @objc func onClickMicrophone(_ sender: UIButton) {
        print("onClickMicrophone")
//        selectTableMask.isHidden = false
//        let types = AgentMicrophoneType.allCases
//        let table = AgentSelectTableView(items: types.map {$0.rawValue}, selected: { index in
//            AgentSettingManager.shared.currentMicrophoneType = types[index]
//            self.microphoneItem.detialLabel.text = types[index].rawValue
//        })
//        view.addSubview(table)
//        selectTable = table
//        table.snp.makeConstraints { make in
//            make.top.equalTo(sender.snp.centerY)
//            make.width.equalTo(table.getWith())
//            make.height.equalTo(table.getHeight())
//            make.right.equalTo(sender).offset(-20)
//        }
    }
    
    @objc func onClickSpeaker(_ sender: UIButton) {
        print("onClickSpeaker")
//        selectTableMask.isHidden = false
//        let types = AgentSpeakerType.allCases
//        let table = AgentSelectTableView(items: types.map {$0.rawValue}, selected: { index in
//            AgentSettingManager.shared.currentSpeakerType = types[index]
//            self.speakerItem.detialLabel.text = types[index].rawValue
//        })
//        view.addSubview(table)
//        selectTable = table 
//        table.snp.makeConstraints { make in
//            make.top.equalTo(sender.snp.centerY)
//            make.width.equalTo(table.getWith())
//            make.height.equalTo(table.getHeight())
//            make.right.equalTo(sender).offset(-20)
//        }
    }
    
    @objc func onClickHideTable(_ sender: UIButton) {
        selectTable?.removeFromSuperview()
        selectTable = nil
        selectTableMask.isHidden = true
    }
    
    func onClickNoiseCancellationChanged(isOn: Bool) {
        AgoraManager.shared.updateDenoise(isOn: isOn)
    }
    
    func updateVoiceConfig() {
        let voiceId = AgentSettingManager.shared.currentVoiceType.voiceId
        SVProgressHUD.show()
        DigitalHumanAPI.shared.updateAgent(appId: AppContext.shared.appId, voiceId: voiceId) { error in
            SVProgressHUD.dismiss()
            guard let error = error else {
                return
            }
            SVProgressHUD.showError(withStatus: error.message)
            self.dismiss(animated: false)
        }
    }
}

extension DigitalHumanSettingViewController {
    private func createViews() {
        let leftTitleLabel = UILabel()
        leftTitleLabel.text = ResourceManager.L10n.Settings.title
        leftTitleLabel.textColor = .white
        leftTitleLabel.font = UIFont.systemFont(ofSize: 20)
        
        let leftTitleItem = UIBarButtonItem(customView: leftTitleLabel)
        self.navigationItem.leftBarButtonItem = leftTitleItem
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage.dh_named("ic_agent_setting_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClose(_ :)), for: .touchUpInside)
        
        let rightItem = UIBarButtonItem(customView: closeButton)
        self.navigationItem.rightBarButtonItem = rightItem
        
        if let navigationController = self.navigationController {
            let navBarApperance = UINavigationBarAppearance()
            navBarApperance.configureWithOpaqueBackground()
            navBarApperance.backgroundColor = PrimaryColors.c_171717
            
            navigationController.navigationBar.standardAppearance = navBarApperance
            navigationController.navigationBar.scrollEdgeAppearance = navBarApperance
        }
        
        let customView = UIView()
        customView.backgroundColor = .clear
        let centerImageView = UIImageView(image: UIImage.dh_named("ic_setting_bar_icon"))
        customView.addSubview(centerImageView)
        centerImageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = customView

        customView.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
        centerImageView.frame = CGRect(x: 0, y: 8, width: 40, height: 4)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView1.backgroundColor = PrimaryColors.c_1d1d1d
        contentView1.layerCornerRadius = 10
        contentView1.layer.borderWidth = 1.0
        contentView1.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView1)
        
        infoItem.titleLabel.text = ResourceManager.L10n.Settings.preset
        infoItem.bottomLine.isHidden = true
        infoItem.button.addTarget(self, action: #selector(onClickPreset(_ :)), for: .touchUpInside)
        contentView1.addSubview(infoItem)
        
        content2Title.text = ResourceManager.L10n.Settings.advanced
        content2Title.font = UIFont.boldSystemFont(ofSize: 16)
        content2Title.textColor = PrimaryColors.c_ffffff_a
        contentView.addSubview(content2Title)
        
        contentView2.backgroundColor = PrimaryColors.c_1d1d1d
        contentView2.layerCornerRadius = 10
        contentView2.layer.borderWidth = 1.0
        contentView2.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView2)
        
        let currentPreset = AgentSettingManager.shared.currentPresetType

        languageItem.titleLabel.text = ResourceManager.L10n.Settings.language
        languageItem.detialLabel.text = AgentLanguageType.availableLanguages(for: currentPreset).first?.rawValue
        languageItem.button.addTarget(self, action: #selector(onClickLanguage(_ :)), for: .touchUpInside)
        contentView2.addSubview(languageItem)
        
        voiceItem.titleLabel.text = ResourceManager.L10n.Settings.voice
        voiceItem.detialLabel.text = AgentVoiceType.availableVoices(for: currentPreset).first?.rawValue
        voiceItem.button.addTarget(self, action: #selector(onClickVoice(_ :)), for: .touchUpInside)
        contentView2.addSubview(voiceItem)
        
        modelItem.titleLabel.text = ResourceManager.L10n.Settings.model
        modelItem.detialLabel.text = AgentModelType.allCases.first?.rawValue
        modelItem.button.addTarget(self, action: #selector(onClickModel(_ :)), for: .touchUpInside)
        contentView2.addSubview(modelItem)
        
        content3Title.text = ResourceManager.L10n.Settings.device
        content3Title.font = UIFont.boldSystemFont(ofSize: 16)
        content3Title.textColor = PrimaryColors.c_ffffff_a
        contentView.addSubview(content3Title)
        
        contentView3.backgroundColor = PrimaryColors.c_1d1d1d
        contentView3.layerCornerRadius = 10
        contentView3.layer.borderWidth = 1.0
        contentView3.layer.borderColor = PrimaryColors.c_262626.cgColor
        contentView.addSubview(contentView3)
        
//        microphoneItem.titleLabel.text = ResourceManager.L10n.Settings.microphone
//        microphoneItem.detialLabel.text = AgentSettingManager.shared.currentMicrophoneType.rawValue
//        microphoneItem.button.addTarget(self, action: #selector(onClickMicrophone(_ :)), for: .touchUpInside)
//        contentView3.addSubview(microphoneItem)
//        
//        speakerItem.titleLabel.text = ResourceManager.L10n.Settings.speaker
//        speakerItem.detialLabel.text = AgentSettingManager.shared.currentSpeakerType.rawValue
//        speakerItem.button.addTarget(self, action: #selector(onClickSpeaker(_ :)), for: .touchUpInside)
//        contentView3.addSubview(speakerItem)
        
        cancellationItem.titleLabel.text = ResourceManager.L10n.Settings.noiseCancellation
        cancellationItem.bottomLine.isHidden = true
        cancellationItem.switcher.addTarget(self, action: #selector(onClickNoiseCancellation(_ :)), for: .touchUpInside)
        cancellationItem.switcher.isOn = AgentSettingManager.shared.isNoiseCancellationEnabled
        contentView3.addSubview(cancellationItem)
        
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
    }
    
    private func createConstrains() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self.view)
            make.left.right.top.bottom.equalToSuperview()
        }
        contentView1.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        infoItem.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        content2Title.snp.makeConstraints { make in
            make.top.equalTo(contentView1.snp.bottom).offset(32)
            make.left.equalTo(20)
        }
        contentView2.snp.makeConstraints { make in
            make.top.equalTo(content2Title.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }
        languageItem.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        voiceItem.snp.makeConstraints { make in
            make.top.equalTo(languageItem.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        modelItem.snp.makeConstraints { make in
            make.top.equalTo(voiceItem.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        content3Title.snp.makeConstraints { make in
            make.top.equalTo(contentView2.snp.bottom).offset(32)
            make.left.equalTo(20)
        }
        contentView3.snp.makeConstraints { make in
            make.top.equalTo(content3Title.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
        }
//        microphoneItem.snp.makeConstraints { make in
//            make.top.left.right.equalToSuperview()
//            make.height.equalTo(56)
//        }
//        speakerItem.snp.makeConstraints { make in
//            make.top.equalTo(microphoneItem.snp.bottom)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(56)
//        }
        cancellationItem.snp.makeConstraints { make in
//            make.top.equalTo(speakerItem.snp.bottom)
            make.top.left.right.bottom.equalToSuperview()
            make.height.equalTo(56)
        }
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
