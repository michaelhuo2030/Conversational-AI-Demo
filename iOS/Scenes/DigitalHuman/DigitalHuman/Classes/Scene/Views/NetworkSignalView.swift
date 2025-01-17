import UIKit
import AgoraRtcKit

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
