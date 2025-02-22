import UIKit
import SnapKit
import Common
import AgoraRtcKit
import SVProgressHUD

public class DeveloperModeViewController: UIViewController {
    
    public static func setDeveloperMode(_ enable: Bool) {
        UserDefaults.standard.set(enable, forKey: "DeveloperMode")
    }
    public static func getDeveloperMode() -> Bool {
        return UserDefaults.standard.bool(forKey: "DeveloperMode")
    }
    
    public static func show(from vc: UIViewController,
                            audioDump: Bool,
                            serverHost: String,
                            onCloseDevMode: (() -> Void)? = nil,
                            onAudioDump: ((Bool) -> Void)? = nil,
                            onSwitchServer: (() -> Void)? = nil,
                            onCopy: (() -> Void)? = nil) {
        let devViewController = DeveloperModeViewController()
        devViewController.modalTransitionStyle = .crossDissolve
        devViewController.modalPresentationStyle = .overCurrentContext
        devViewController.isAudioDumpEnabled = audioDump
        devViewController.serverHost = serverHost
        devViewController.onCloseDevModeCallback = onCloseDevMode
        devViewController.audioDumpCallback = onAudioDump
        devViewController.copyCallback = onCopy
        devViewController.onSwitchServer = onSwitchServer
        vc.present(devViewController, animated: true)
    }
    
    private var onCloseDevModeCallback: (() -> Void)?
    private var audioDumpCallback: ((Bool) -> Void)?
    private var copyCallback: (() -> Void)?
    private var onSwitchServer: (() -> Void)?
    
    private var serverHost: String = ""
    private var isAudioDumpEnabled: Bool = false
    private let rtcVersionValueLabel = UILabel()
    private let serverHostValueLabel = UILabel()
    private let segmentCtrl = UISegmentedControl(items: AppContext.shared.environments.map { ($0["name"]) ?? "" })
    private let audioDumpSwitch = UISwitch()
    
    private let feedbackPresenter = FeedBackPresenter()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.7)
        setupViews()
        
        audioDumpSwitch.isOn = isAudioDumpEnabled
        rtcVersionValueLabel.text = AgoraRtcEngineKit.getSdkVersion()
        serverHostValueLabel.text = serverHost
        // update environment segment        
        for (index, envi) in AppContext.shared.environments.enumerated() {
            let host = envi["host"]
            if host == AppContext.shared.baseServerUrl {
                segmentCtrl.selectedSegmentIndex = index
                break
            }
        }
    }
}

// MARK: - Actions
extension DeveloperModeViewController {
    @objc private func onClickClosePage(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc private func onClickCloseMode(_ sender: UIButton) {
        DeveloperModeViewController.setDeveloperMode(false)
        onCloseDevModeCallback?()
        self.dismiss(animated: true)
    }
    
    @objc private func onClickAudioDump(_ sender: UISwitch) {
        audioDumpCallback?(sender.isOn)
    }
    
    @objc private func onClickCopy(_ sender: UIButton) {
        copyCallback?()
        feedbackPresenter.feedback(isSendLog: true, title: "111", feedback: "copy user question") { error, result in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.message)
            } else {
                SVProgressHUD.showSuccess(withStatus: "copy user question success")
            }
        }
    }
    
    @objc private func onSwitchButtonClicked(_ sender: UIButton) {
        let index = segmentCtrl.selectedSegmentIndex
        let environments = AppContext.shared.environments
        if index >= 0 && index < environments.count {
            let envi = environments[index]
            let host = envi["host"]
            AppContext.shared.baseServerUrl = host ?? ""
            AppContext.shared.appId = envi["appId"] ?? ""
            SVProgressHUD.showInfo(withStatus: host)
        }
        self.dismiss(animated: true)
        onSwitchServer?()
    }
}

// MARK: - Setup
extension DeveloperModeViewController {
    private func setupViews() {
        // Content View
        let cotentView = UIView()
        cotentView.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.addSubview(cotentView)
        cotentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(380)
        }
        
        // Title Grabber
        let titleGrabber = UIView()
        titleGrabber.backgroundColor = UIColor(hexString: "#404548")
        titleGrabber.layerCornerRadius = 2
        cotentView.addSubview(titleGrabber)
        titleGrabber.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(4)
            make.width.equalTo(34)
        }
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = ResourceManager.L10n.DevMode.title
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        cotentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleGrabber.snp.bottom).offset(10)
            make.left.equalTo(20)
        }
        
        // Close Button
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClosePage(_ :)), for: .touchUpInside)
        closeButton.tintColor = UIColor.themColor(named: "ai_icontext1")
        cotentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
        }
        
        // Divider Line
        let dividerLine = UIView()
        dividerLine.backgroundColor = UIColor.white.withAlphaComponent(0.11)
        cotentView.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        // RTC Version
        let rtcVersionLabel = UILabel()
        rtcVersionLabel.text = ResourceManager.L10n.DevMode.rtc
        rtcVersionLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        rtcVersionLabel.font = UIFont.systemFont(ofSize: 14)
        
        rtcVersionValueLabel.text = AgoraRtcEngineKit.getSdkVersion()
        rtcVersionValueLabel.textColor = UIColor.themColor(named: "ai_icontext4")
        rtcVersionValueLabel.font = UIFont.systemFont(ofSize: 14)
        
        let rtcStackView = UIStackView()
        rtcStackView.axis = .horizontal
        rtcStackView.alignment = .center
        rtcStackView.spacing = 12
        rtcStackView.addArrangedSubview(rtcVersionLabel)
        rtcStackView.addArrangedSubview(rtcVersionValueLabel)
        cotentView.addSubview(rtcStackView)
        rtcStackView.snp.makeConstraints { make in
            make.top.equalTo(dividerLine.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Environment
        let enviroimentTitleLabel = UILabel()
        enviroimentTitleLabel.text = "Convo AI服务器"
        enviroimentTitleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        enviroimentTitleLabel.font = UIFont.systemFont(ofSize: 14)
                
        // 添加切换按钮
        let switchButton = UIButton(type: .system)
        switchButton.setTitle("Switch", for: .normal)
        switchButton.addTarget(self, action: #selector(onSwitchButtonClicked(_:)), for: .touchUpInside)
        
        let enviroimentStack = UIStackView(arrangedSubviews: [enviroimentTitleLabel, segmentCtrl, switchButton])
        enviroimentStack.axis = .horizontal
        enviroimentStack.spacing = 12
        enviroimentStack.alignment = .center
        cotentView.addSubview(enviroimentStack)
        enviroimentStack.snp.makeConstraints { make in
            make.top.equalTo(rtcStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Server Host
        let serverHostLabel = UILabel()
        serverHostLabel.text = ResourceManager.L10n.DevMode.host
        serverHostLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        serverHostLabel.font = UIFont.systemFont(ofSize: 14)
        
        let serverHostValueLabel = UILabel()
        serverHostValueLabel.text = serverHost
        serverHostValueLabel.textColor = UIColor.themColor(named: "ai_icontext4")
        serverHostValueLabel.font = UIFont.systemFont(ofSize: 14)
        
        let serverHostStackView = UIStackView()
        serverHostStackView.axis = .horizontal
        serverHostStackView.alignment = .center
        serverHostStackView.spacing = 12
        serverHostStackView.addArrangedSubview(serverHostLabel)
        serverHostStackView.addArrangedSubview(serverHostValueLabel)
        cotentView.addSubview(serverHostStackView)
        serverHostStackView.snp.makeConstraints { make in
            make.top.equalTo(enviroimentStack.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Audio Dump
        let audioDumpLabel = UILabel()
        audioDumpLabel.text = ResourceManager.L10n.DevMode.dump
        audioDumpLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        audioDumpLabel.font = UIFont.systemFont(ofSize: 14)
        
        audioDumpSwitch.addTarget(self, action: #selector(onClickAudioDump(_ :)), for: .touchUpInside)
        
        let audioDumpStackView = UIStackView()
        audioDumpStackView.axis = .horizontal
        audioDumpStackView.alignment = .center
        audioDumpStackView.spacing = 12
        audioDumpStackView.addArrangedSubview(audioDumpLabel)
        audioDumpStackView.addArrangedSubview(audioDumpSwitch)
        cotentView.addSubview(audioDumpStackView)
        audioDumpStackView.snp.makeConstraints { make in
            make.top.equalTo(serverHostStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Copy User Question
        let copyUserQuestionLabel = UILabel()
        copyUserQuestionLabel.text = ResourceManager.L10n.DevMode.copy
        copyUserQuestionLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        copyUserQuestionLabel.font = UIFont.systemFont(ofSize: 14)
        
        let copyButton = UIButton()
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.addTarget(self, action: #selector(onClickCopy(_ :)), for: .touchUpInside)
        
        let copyStackView = UIStackView()
        copyStackView.axis = .horizontal
        copyStackView.spacing = 12
        copyStackView.alignment = .center
        copyStackView.addArrangedSubview(copyUserQuestionLabel)
        copyStackView.addArrangedSubview(copyButton)
        cotentView.addSubview(copyStackView)
        copyStackView.snp.makeConstraints { make in
            make.top.equalTo(audioDumpStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Close Debug Button
        let closeDebugButton = UIButton()
        closeDebugButton.setTitle(ResourceManager.L10n.DevMode.close, for: .normal)
        closeDebugButton.setTitleColor(.white, for: .normal)
        closeDebugButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        closeDebugButton.layerCornerRadius = 24
        closeDebugButton.clipsToBounds = true
        closeDebugButton.setBackgroundColor(color: UIColor(hexString: "#0097D4")!, forState: .normal)
        closeDebugButton.addTarget(self, action: #selector(onClickCloseMode(_ :)), for: .touchUpInside)
        cotentView.addSubview(closeDebugButton)
        closeDebugButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(48)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
        }
    }
}
