import UIKit
import SnapKit
import Common
import AgoraRtcKit

public class DeveloperModeViewController: UIViewController {
    
    public static func show(from vc: UIViewController,
                            serverHost: String,
                            onClose: (() -> Void)? = nil,
                            onAudioDump: ((Bool) -> Void)? = nil,
                            onCopy: (() -> Void)? = nil) {
        let devViewController = DeveloperModeViewController()
        devViewController.modalTransitionStyle = .crossDissolve
        devViewController.modalPresentationStyle = .overCurrentContext
        devViewController.serverHost = serverHost
        devViewController.closeCallback = onClose
        devViewController.audioDumpCallback = onAudioDump
        devViewController.copyCallback = onCopy
        vc.present(devViewController, animated: true)
    }
    
    private var closeCallback: (() -> Void)?
    private var audioDumpCallback: ((Bool) -> Void)?
    private var copyCallback: (() -> Void)?
    
    private var serverHost: String = ""
    
    private let cotentView = UIView()
    private let titleGrabber = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    private let dividerLine = UIView()
    private let rtcVersionLabel = UILabel()
    private let rtcVersionValueLabel = UILabel()
    private let rtcStackView = UIStackView()
    private let serverHostLabel = UILabel()
    private let serverHostValueLabel = UILabel()
    private let serverHostStackView = UIStackView()
    private let audioDumpLabel = UILabel()
    private let audioDumpSwitch = UISwitch()
    private let audioDumpStackView = UIStackView()
    private let copyUserQuestionLabel = UILabel()
    private let copyButton = UIButton()
    private let copyStackView = UIStackView()
    private let closeDebugButton = UIButton()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.7)
        setupViews()
        rtcVersionValueLabel.text = AgoraRtcEngineKit.getSdkVersion()
        serverHostValueLabel.text = serverHost
    }
}

// MARK: - Actions
extension DeveloperModeViewController {
    @objc private func onClickClosePage(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc private func onClickCloseMode(_ sender: UIButton) {
        closeCallback?()
        self.dismiss(animated: true)
    }
    
    @objc private func onClickAudioDump(_ sender: UISwitch) {
        audioDumpCallback?(sender.isOn)
    }
    
    @objc private func onClickCopy(_ sender: UIButton) {
        copyCallback?()
    }
}

// MARK: - Setup
extension DeveloperModeViewController {
    private func setupViews() {
        cotentView.backgroundColor = UIColor.themColor(named: "ai_fill2")
        view.addSubview(cotentView)
        cotentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(330)
        }
                
        titleGrabber.backgroundColor = UIColor(hexString: "#404548")
        titleGrabber.layerCornerRadius = 2
        cotentView.addSubview(titleGrabber)
        titleGrabber.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(4)
            make.width.equalTo(34)
        }
        
        titleLabel.text = ResourceManager.L10n.DevMode.title
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        cotentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleGrabber.snp.bottom).offset(10)
            make.left.equalTo(20)
        }
        
        closeButton.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(onClickClosePage(_ :)), for: .touchUpInside)
        closeButton.tintColor = UIColor.themColor(named: "ai_icontext1")
        cotentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(titleLabel)
        }
        
        dividerLine.backgroundColor = UIColor.white.withAlphaComponent(0.11)
        cotentView.addSubview(dividerLine)
        dividerLine.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        rtcVersionLabel.text = ResourceManager.L10n.DevMode.rtc
        rtcVersionLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        rtcVersionLabel.font = UIFont.systemFont(ofSize: 14)
        
        rtcVersionValueLabel.textColor = UIColor.themColor(named: "ai_icontext4")
        rtcVersionValueLabel.font = UIFont.systemFont(ofSize: 14)
        
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
        
        // Server Host Layout
        serverHostLabel.text = ResourceManager.L10n.DevMode.host
        serverHostLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        serverHostLabel.font = UIFont.systemFont(ofSize: 14)
        
        serverHostValueLabel.text = "xxx"
        serverHostValueLabel.textColor = UIColor.themColor(named: "ai_icontext4")
        serverHostValueLabel.font = UIFont.systemFont(ofSize: 14)
        
        serverHostStackView.addArrangedSubview(serverHostLabel)
        serverHostStackView.addArrangedSubview(serverHostValueLabel)
        serverHostStackView.axis = .horizontal
        serverHostStackView.alignment = .center
        serverHostStackView.spacing = 12
        cotentView.addSubview(serverHostStackView)
        serverHostStackView.snp.makeConstraints { make in
            make.top.equalTo(rtcStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Audio Dump Layout
        audioDumpLabel.text = ResourceManager.L10n.DevMode.dump
        audioDumpLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        audioDumpLabel.font = UIFont.systemFont(ofSize: 14)
        
        audioDumpSwitch.isOn = true
        audioDumpSwitch.addTarget(self, action: #selector(onClickAudioDump(_ :)), for: .touchUpInside)
        
        audioDumpStackView.addArrangedSubview(audioDumpLabel)
        audioDumpStackView.addArrangedSubview(audioDumpSwitch)
        audioDumpStackView.axis = .horizontal
        audioDumpStackView.alignment = .center
        audioDumpStackView.spacing = 12
        cotentView.addSubview(audioDumpStackView)
        audioDumpStackView.snp.makeConstraints { make in
            make.top.equalTo(serverHostStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Copy User Question Layout
        copyUserQuestionLabel.text = ResourceManager.L10n.DevMode.copy
        copyUserQuestionLabel.textColor = UIColor.themColor(named: "ai_icontext1")
        copyUserQuestionLabel.font = UIFont.systemFont(ofSize: 14)
        
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        copyButton.addTarget(self, action: #selector(onClickCopy(_ :)), for: .touchUpInside)
        
        let copyStackView = UIStackView(arrangedSubviews: [copyUserQuestionLabel, copyButton])
        copyStackView.axis = .horizontal
        copyStackView.spacing = 12
        copyStackView.alignment = .center
        view.addSubview(copyStackView)
        copyStackView.snp.makeConstraints { make in
            make.top.equalTo(audioDumpStackView.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        // Close Debug Layout
        let closeDebugButton = UIButton()
        closeDebugButton.setTitle(ResourceManager.L10n.DevMode.close, for: .normal)
        closeDebugButton.setTitleColor(.white, for: .normal)
        closeDebugButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        closeDebugButton.layer.cornerRadius = 8
        closeDebugButton.addTarget(self, action: #selector(onClickCloseMode(_ :)), for: .touchUpInside)
        closeDebugButton.layerCornerRadius = 24
        closeDebugButton.clipsToBounds = true
        closeDebugButton.setBackgroundColor(color: UIColor(hexString: "#0097D4")!, forState: .normal)
        cotentView.addSubview(closeDebugButton)
        closeDebugButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(48)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-20)
        }
    }
}
