import UIKit
import AgoraRtcKit

protocol NetworkSignalViewDelegate: AnyObject {
    func networkSignalView(_ view: NetworkSignalView, didClickNetworkButton button: UIButton)
}

class NetworkSignalView: UIView {
    var networkStatue: NetworkStatus = .poor
    weak var delegate: NetworkSignalViewDelegate?
    lazy var signalButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.ag_named("ic_signal_bad"), for: .normal)
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
//            self.signalButton.setImage(status.signalImage, for: .normal)
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
