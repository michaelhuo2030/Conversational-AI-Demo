import UIKit
import AgoraRtcKit

enum NetworkStatus {
    case good
    case poor
    case veryBad
    case unknown
    
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

class NetworkSignalView: UIView {
    private lazy var signalButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.dh_named("ic_signal_bad"), for: .normal)
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
}
