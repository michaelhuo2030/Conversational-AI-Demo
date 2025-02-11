//
//  AgentSettingVieController.swift
//  Agent
//
//  Created by qinhui on 2024/10/31.
//

import UIKit
import Common
import SVProgressHUD

class AgentSettingViewController: UIViewController {
    private let backgroundViewHeight: CGFloat = 427
    private var initialCenter: CGPoint = .zero
    private var panGesture: UIPanGestureRecognizer?
    private var basicSettingItems: [UIView] = []
    private var advancedSettingItems: [UIView] = []
    weak var agentManager: AgentManager!
    var channelName = ""
    
    private lazy var topView: AgentSettingTopView = {
        let view = AgentSettingTopView()
        view.onCloseButtonTapped = { [weak self] in
            self?.animateBackgroundViewOut()
        }
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = PrimaryColors.c_171717
        view.alpha = 0.95
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var basicSettingView: UIView = {
        let view = UIView()
        view.backgroundColor = PrimaryColors.c_1d1d1d
        view.layerCornerRadius = 10
        view.layer.borderWidth = 1.0
        view.layer.borderColor = PrimaryColors.c_262626.cgColor
        return view
    }()
    
    private lazy var presetItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.Settings.preset
        if let manager = AppContext.preferenceManager() {
            view.detailLabel.text = manager.preference.preset?.displayName ?? ""
        }
        view.button.addTarget(self, action: #selector(onClickPreset(_:)), for: .touchUpInside)
        return view
    }()
    
    private lazy var languageItem: AgentSettingTableItemView = {
        let view = AgentSettingTableItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.Settings.language
        if let manager = AppContext.preferenceManager() {
            if let currentLanguage = manager.preference.language {
                view.detailLabel.text = currentLanguage.languageName
            } else {
                view.detailLabel.text = manager.preference.preset?.defaultLanguageName
            }
        }
        view.button.addTarget(self, action: #selector(onClickLanguage(_:)), for: .touchUpInside)
        return view
    }()
    
    private lazy var advancedSettingTitle: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Settings.advanced
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = PrimaryColors.c_ffffff_a
        return label
    }()
    
    private lazy var advancedSettingView: UIView = {
        let view = UIView()
        view.backgroundColor = PrimaryColors.c_1d1d1d
        view.layerCornerRadius = 10
        view.layer.borderWidth = 1.0
        view.layer.borderColor = PrimaryColors.c_262626.cgColor
        return view
    }()
    
    private lazy var bhvsResponseItem: AgentSettingSwitchItemView = {
        let view = AgentSettingSwitchItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.Settings.bhvs
        view.switcher.addTarget(self, action: #selector(onClickForceResponse(_:)), for: .touchUpInside)
        if let manager = AppContext.preferenceManager() {
            view.switcher.isOn = manager.preference.bhvs
        }
        return view
    }()
    
    private lazy var aiVadItem: AgentSettingSwitchItemView = {
        let view = AgentSettingSwitchItemView(frame: .zero)
        view.titleLabel.text = ResourceManager.L10n.Settings.aiVad
        view.switcher.addTarget(self, action: #selector(onClickAiVad(_:)), for: .touchUpInside)
        if let manager = AppContext.preferenceManager() {
            view.switcher.isOn = manager.preference.aiVad
        }
        view.bottomLine.isHidden = true
        view.updateLayout()
        return view
    }()
    
    private lazy var selectTableMask: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(onClickHideTable(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private var selectTable: AgentSelectTableView? = nil
        
    deinit {
        unRegisterDelegate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerDelegate()
        createViews()
        createConstrains()
        setupPanGesture()
        animateBackgroundViewIn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestPresetsIfNeed()
    }
    
    private func registerDelegate() {
        AppContext.preferenceManager()?.addDelegate(self)
    }
    
    private func unRegisterDelegate() {
        AppContext.preferenceManager()?.removeDelegate(self)
    }
    
    private func requestPresetsIfNeed() {
        guard AppContext.preferenceManager()?.allPresets() == nil else {
            return
        }
        
        SVProgressHUD.show()
        AgentLogger.info("request presets in setting page")
        agentManager.fetchAgentPresets { error, result in
            SVProgressHUD.dismiss()
            if let error = error {
                SVProgressHUD.showError(withStatus: error.message)
                AgentLogger.info(error.message)
                return
            }
            
            guard let result = result else {
                AgentLogger.info("preset is empty")
                SVProgressHUD.showError(withStatus: "preset is empty")
                return
            }
            
            AppContext.preferenceManager()?.setPresets(presets: result)
        }
    }
    
    private func setupPanGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        backgroundView.addGestureRecognizer(panGesture!)
    }
    
    private func animateBackgroundViewIn() {
        backgroundView.transform = CGAffineTransform(translationX: 0, y: backgroundViewHeight)
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.transform = .identity
        }
    }
    
    private func animateBackgroundViewOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.transform = CGAffineTransform(translationX:0, y: self.backgroundViewHeight)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            initialCenter = backgroundView.center
        case .changed:
            let newY = max(translation.y, 0)
            backgroundView.transform = CGAffineTransform(translationX:0, y: newY)
        case .ended:
            let velocity = gesture.velocity(in: view)
            let shouldDismiss = translation.y > backgroundViewHeight / 2 || velocity.y > 500
            
            if shouldDismiss {
                animateBackgroundViewOut()
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.backgroundView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc func onClickClose(_ sender: UIButton) {
        animateBackgroundViewOut()
    }
    
    @objc func onClickPreset(_ sender: UIButton) {
        selectTableMask.isHidden = false
        guard let allPresets = AppContext.preferenceManager()?.allPresets() else {
            return
        }
        
        guard let currentPreset = AppContext.preferenceManager()?.preference.preset else {
            return
        }
    
        let currentIndex = allPresets.firstIndex { $0.displayName == currentPreset.displayName } ?? 0
        let table = AgentSelectTableView(items: allPresets.map {$0.displayName}) { index in
            let selected = allPresets[index]
            if selected.displayName == currentPreset.displayName { return }
            
            AppContext.preferenceManager()?.updatePreset(selected)
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
        guard let currentPreset = AppContext.preferenceManager()?.preference.preset else { return }
        let allLanguages = currentPreset.supportLanguages
        
        guard let currentLanguage = AppContext.preferenceManager()?.preference.language else { return }
        
        let currentIndex = allLanguages.firstIndex { $0.languageName == currentLanguage.languageName } ?? 0
        let table = AgentSelectTableView(items: allLanguages.map { $0.languageName }) { index in
            let selected = allLanguages[index]
            if currentLanguage.languageCode == selected.languageCode { return }
            
            AppContext.preferenceManager()?.updateLanguage(selected)
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
    
    @objc func onClickAiVad(_ sender: UISwitch) {
        let state = sender.isOn
        AppContext.preferenceManager()?.updateAiVadState(state)
        AppContext.preferenceManager()?.updateForceThresholdState(state)
    }
    
    @objc func onClickForceResponse(_ sender: UISwitch) {
        let state = sender.isOn
        AppContext.preferenceManager()?.updateForceThresholdState(state)
    }
    
    @objc func onClickHideTable(_ sender: UIButton) {
        selectTable?.removeFromSuperview()
        selectTable = nil
        selectTableMask.isHidden = true
    }
}

extension AgentSettingViewController {
    private func createViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(backgroundView)
        backgroundView.addSubview(topView)
        backgroundView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        basicSettingItems = [presetItem, languageItem]
        advancedSettingItems = [bhvsResponseItem, aiVadItem]
        
        contentView.addSubview(basicSettingView)
        contentView.addSubview(advancedSettingTitle)
        contentView.addSubview(advancedSettingView)
        
        basicSettingItems.forEach { basicSettingView.addSubview($0) }
        advancedSettingItems.forEach { advancedSettingView.addSubview($0) }
        
        view.addSubview(selectTableMask)
        
//        let agentState = AppContext.preferenceManager()?.information.agentState
//        maskView.isHidden = agentState == .unload
    }
    
    private func createConstrains() {
        backgroundView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(backgroundViewHeight)
        }
        
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.width.equalTo(self.view)
            make.left.right.top.bottom.equalToSuperview()
        }
        
        basicSettingView.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(20)
            make.right.equalTo(-20)
        }

        for (index, item) in basicSettingItems.enumerated() {
            item.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(50)
                
                if index == 0 {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(basicSettingItems[index - 1].snp.bottom)
                }
                
                if index == basicSettingItems.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
        }
        
        advancedSettingTitle.snp.makeConstraints { make in
            make.top.equalTo(basicSettingView.snp.bottom).offset(32)
            make.left.equalTo(20)
        }
        
        advancedSettingView.snp.makeConstraints { make in
            make.top.equalTo(advancedSettingTitle.snp.bottom).offset(8)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
        }

        for (index, item) in advancedSettingItems.enumerated() {
            item.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(70)
                
                if index == 0 {
                    make.top.equalTo(0)
                } else {
                    make.top.equalTo(advancedSettingItems[index - 1].snp.bottom)
                }
                
                if index == advancedSettingItems.count - 1 {
                    make.bottom.equalToSuperview().priority(30)
                } else {
                    make.bottom.equalToSuperview().priority(20)
                }
            }
        }
        
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    @objc func handleTapGesture(_: UIGestureRecognizer) {
        animateBackgroundViewOut()
    }
}

extension AgentSettingViewController: AgentPreferenceManagerDelegate {
    func preferenceManager(_ manager: AgentPreferenceManager, presetDidUpdated preset: AgentPreset) {
        presetItem.detailLabel.text =  preset.displayName
        
        let defaultLanguageCode = preset.defaultLanguageCode
        let supportLanguages = preset.supportLanguages
        
        var resetLanguageCode = defaultLanguageCode
        if defaultLanguageCode.isEmpty, let languageCode = supportLanguages.first?.languageCode {
            resetLanguageCode = languageCode
        }
        
        if let language = supportLanguages.first(where: { $0.languageCode == resetLanguageCode }) {
            manager.updateLanguage(language)
        }
    }
    
    func preferenceManager(_ manager: AgentPreferenceManager, languageDidUpdated language: SupportLanguage) {
        languageItem.detailLabel.text = language.languageName
    }
}

extension AgentSettingViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view
    }
}
