import UIKit
import AgoraRtcKit
import Common

enum NetworkStatus: String {
    case good = "Good"
    case poor = "Okay"
    case veryBad = "Poor"
    case unknown = ""
    
    init(agoraQuality: AgoraNetworkQuality) {
        switch agoraQuality {
        case .excellent, .good:
            self = .good
        case .poor:
            self = .poor
        case .bad, .vBad, .down:
            self = .veryBad
        default:
            self = .unknown
        }
    }
    
    var color: UIColor {
        switch self {
        case .good:
            return UIColor(hex: 0x36B37E)
        case .poor:
            return UIColor(hex: 0xFFAB00)
        case .veryBad, .unknown:
            return UIColor(hex: 0xFF414D)
        }
    }
    
    var signalImage: UIImage? {
        switch self {
        case .good:
            return UIImage.dh_named("ic_signal_good")
        case .poor:
            return UIImage.dh_named("ic_signal_medium")
        case .veryBad:
            return UIImage.dh_named("ic_signal_bad")
        case .unknown:
            return UIImage.dh_named("ic_signal_bad")
        }
    }
}

protocol NetworkSignalViewDelegate: AnyObject {
    func networkSignalView(_ view: NetworkSignalView, didClickNetworkButton button: UIButton)
}

class NetworkSignalView: UIView {
    var networkStatue: NetworkStatus = .poor
    weak var delegate: NetworkSignalViewDelegate?
    lazy var signalButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.dh_named("ic_signal_bad"), for: .normal)
        button.addTarget(self, action: #selector(networkButtonClicked), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Private Methods
    private func setupView() {
        addSubview(signalButton)
        signalButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    public func updateStatus(_ status: NetworkStatus) {
        networkStatue = status
//        AgentSettingManager.shared.updateAgentNetwork(status)
        UIView.transition(with: signalButton,
                         duration: 0.2,
                         options: .transitionCrossDissolve,
                         animations: {
            self.signalButton.setImage(status.signalImage, for: .normal)
        })
    }
    
    // MARK: - Override Methods
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }

    @objc private func networkButtonClicked() {
        delegate?.networkSignalView(self, didClickNetworkButton: signalButton)
    }
}


// MARK: - AgentSettingBar
class DigitalHumanSettingBar: UIView {
    
    let backButton = UIButton()
    let titleLabel = UILabel()
    let tipsButton = UIButton(type: .custom)
    let settingButton = UIButton(type: .custom)
    let networkSignalView = NetworkSignalView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewsAndConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    private func setupViewsAndConstraints() {
        backButton.setImage(UIImage.dh_named("ic_agora_back"), for: .normal)
        addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        titleLabel.text = ResourceManager.L10n.Join.title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.themColor(named: "ai_icontext2")
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
//        settingButton.setImage(UIImage.dh_named("ic_agent_setting"), for: .normal)
//        addSubview(settingButton)
//        settingButton.snp.makeConstraints { make in
//            make.right.equalToSuperview()
//            make.centerY.equalToSuperview()
//            make.width.height.equalTo(48)
//        }
        addSubview(networkSignalView)
        networkSignalView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        tipsButton.setImage(UIImage.dh_named("ic_agent_tips_icon"), for: .normal)
        addSubview(tipsButton)
        tipsButton.snp.remakeConstraints { make in
            make.right.equalTo(networkSignalView.snp.left)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
    }
     
    func updateNetworkStatus(_ status: NetworkStatus) {
        networkSignalView.updateStatus(status)
    }
}
