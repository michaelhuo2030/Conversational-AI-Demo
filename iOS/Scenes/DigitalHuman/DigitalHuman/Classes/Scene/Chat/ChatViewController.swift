//
//  ViewController.swift
//  Agent
//  
//  Created by HeZhengQing on 2024/9/29.
//

import UIKit
import SnapKit
import AgoraRtcKit
import SVProgressHUD
import SwifterSwift
import Common

class LivingViewController: UIViewController {
    // MARK: - Properties
    private var showMineContent: Bool = true {
        didSet {
            mineContentView.isHidden = !showMineContent
        }
    }
    
    static func showAgent(host: String,
                          token: String,
                          uid: Int,
                          agentUid: Int,
                          channel: String,
                          showMineContent: Bool = true,
                          vc: UIViewController) {
        let livingVC = LivingViewController()
        livingVC.host = host
        livingVC.rtcToken = token
        livingVC.uid = uid
        livingVC.agentUid = agentUid
        livingVC.channelName = channel
        livingVC.showMineContent = showMineContent
        livingVC.modalPresentationStyle = .fullScreen
        livingVC.fromVC = vc
        vc.present(livingVC, animated: false)
    }
    
    private var fromVC: UIViewController? = nil
    private var host = ""
    private var rtcToken = ""
    private var uid = 0
    private var agentUid = 0
    private var channelName = ""
    private var isMute = false
    private var isDenoise = false
    private var agentManager: AgentManager!
    private var agent_rtc_id = ""

    private var selectTable: AgentSettingInfoView? = nil
    private var selectTableMask = UIButton(type: .custom)
    private let messageParser = MessageParser()

    private lazy var topBar: AgentSettingBar = {
        let view = AgentSettingBar()
        view.onTipsButtonTapped = { [weak self] in
            self?.handleTipsAction()
        }
        view.onSettingButtonTapped = { [weak self] in
            self?.handleSettingAction()
        }
        view.onBackButtonTapped = { [weak self] in
            self?.stopPageAction()
        }
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex:0x222222)
        view.layerCornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var waveView: AgoraWaveGroupView = {
        let view = AgoraWaveGroupView(frame: CGRect(x: 0, y: 0, width: 200, height: 200), count: 4, padding: 10)
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(ResourceManager.L10n.Conversation.buttonEndCall, for: .normal)
        button.addTarget(self, action: #selector(handleEndCallAction), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.layerCornerRadius = 36
        button.clipsToBounds = true
        button.setImage(UIImage.va_named("ic_agent_detail_phone"), for: .normal)
        button.isEnabled = false
        button.alpha = 0.5
        
        if let color = UIColor(hex: 0xFF414D) {
            button.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        
        let spacing: CGFloat = 5
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        
        return button
    }()
    
    private lazy var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(handleMuteAction(_ :)), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.layerCornerRadius = 36
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(color: PrimaryColors.c_00c2ff, size: CGSize(width: 1, height: 1)), for: .normal)
        return button
    }()
    
    private lazy var msgButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(handleMsgAction(_ :)), for: .touchUpInside)
        button.titleLabel?.textAlignment = .center
        button.layerCornerRadius = 36
        button.clipsToBounds = true
        button.setImage(UIImage.va_named("ic_msg_icon"), for: .normal)
        button.setBackgroundColor(color: PrimaryColors.c_00c2ff, forState: .normal)
        button.setBackgroundColor(color: PrimaryColors.c_0097d4, forState: .selected)
        if let color = UIColor(hex: 0x333333) {
            button.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        return button
    }()
    
    private lazy var aiNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = ResourceManager.L10n.Conversation.agentName
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        return label
    }()
    
    private lazy var mineContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex:0x333333)
        view.layerCornerRadius = 8
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var mineAvatarLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hex:0x222222)
        label.backgroundColor = UIColor(hex:0xBDCFDB)
        label.text = "Y"
        label.textAlignment = .center
        label.layerCornerRadius = 30
        label.clipsToBounds = true
        return label
    }()
    
    private lazy var mineNameView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x1D1D1D)
        view.layerCornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var mineNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = "You"
        return label
    }()
    
    private lazy var micStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.va_named("ic_agent_detail_mute"))
        return imageView
    }()
    
    private var stopInitiative = false
    
    deinit {
        print("liveing view controller deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAgentCoordinator()
        setupViews()
        setupConstraints()
        
        mineContentView.isHidden = !showMineContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let centerX = contentView.bounds.width / 2
        let centerY = contentView.bounds.height / 2
        
        waveView.center = CGPoint(x: centerX, y: centerY)
    }
    
    private func setupAgentCoordinator() {
        AgentSettingManager.shared.updateRoomId(channelName)
        agentManager = AgentManager(appId: AppContext.shared.appId, channelName: channelName, token: rtcToken, host: host, delegate: self)
        startAgent()
        setupMuteState()
    }
    
    private func setupViews() {
        view.backgroundColor = UIColor(hex: 0x111111)
        
        [topBar, contentView, closeButton, muteButton, 
         msgButton, mineContentView].forEach { view.addSubview($0) }
        
        contentView.addSubview(waveView)
        contentView.addSubview(aiNameLabel)
        
        mineContentView.addSubview(mineAvatarLabel)
        mineContentView.addSubview(mineNameView)
        mineNameView.addSubview(mineNameLabel)
        mineNameView.addSubview(micStateImageView)
        
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
    }
    
    private func setupConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        contentView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalTo(closeButton.snp.top).offset(-20)
        }
        muteButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.left.equalTo(20)
            make.width.height.equalTo(72)
        }
        msgButton.snp.makeConstraints { make in
            make.centerY.equalTo(muteButton)
            make.left.equalTo(muteButton.snp.right).offset(16)
            make.width.height.equalTo(72)
        }
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(msgButton.snp.right).offset(16)
            make.right.equalTo(-20)
            make.height.equalTo(72)
            make.centerY.equalTo(muteButton)
        }
        aiNameLabel.snp.makeConstraints { make in
            make.width.equalTo(75)
            make.height.equalTo(32)
            make.left.equalTo(12)
            make.bottom.equalTo(-12)
        }
        mineContentView.snp.makeConstraints { make in
            make.width.equalTo(215)
            make.height.equalTo(100)
            make.top.equalTo(contentView).offset(16)
            make.right.equalTo(contentView).offset(-16)
        }
        mineAvatarLabel.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.center.equalTo(mineContentView)
        }
        mineNameView.snp.makeConstraints { make in
            make.width.equalTo(66)
            make.height.equalTo(32)
            make.left.equalTo(mineContentView).offset(8)
            make.bottom.equalTo(mineContentView).offset(-8)
        }
        micStateImageView.snp.makeConstraints { make in
            make.left.equalTo(mineNameView).offset(6)
            make.width.height.equalTo(20)
            make.centerY.equalTo(mineNameView)
        }
        mineNameLabel.snp.makeConstraints { make in
            make.left.equalTo(micStateImageView.snp.right).offset(2)
            make.centerY.equalTo(mineNameView)
        }
        
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    private func startAgent() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
        addLog("begin start agent")
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        topBar.backButton.isEnabled = false
        topBar.backButton.alpha = 0.5
        
        agentManager.startAgent(uid: uid, agentUid: agentUid) { [weak self] err, agentId in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            
            guard let error = err else {
                self.agent_rtc_id = agentId ?? ""
                self.setupDenoise()
                self.joinChannel()
                addLog("start agent success")
                
                self.closeButton.isEnabled = true
                self.closeButton.alpha = 1.0
                self.topBar.backButton.isEnabled = true
                self.topBar.backButton.alpha = 1.0
                return
            }
            
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.joinError)
            addLog("start agent failed : \(error.message)")
            self.dismiss(animated: false)
        }
    }
    
    private func restartAgent() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
        addLog("begin restart agent")
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        topBar.backButton.isEnabled = false
        topBar.backButton.alpha = 0.5
        
        agentManager.startAgent(uid: uid, agentUid: agentUid) { [weak self] err, agentId in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            
            guard let error = err else {
                self.agent_rtc_id = agentId ?? ""
                self.setupDenoise()
                AgentSettingManager.shared.updateAgentStatus(.connected)
                self.selectTable?.updateStatus()
                addLog("restart agent success")
                
                self.closeButton.isEnabled = true
                self.closeButton.alpha = 1.0
                self.topBar.backButton.isEnabled = true
                self.topBar.backButton.alpha = 1.0
                return
            }
            
            SVProgressHUD.showInfo(withStatus: error.message)
            addLog("restart agent failed : \(error.message)")
            self.dismiss(animated: false)
            return
        }
    }
    
    private func joinChannel() {
        AgentSettingManager.shared.updateAgentStatus(.connected)
        let ret = agentManager.joinChannel()
        if (ret == 0) {
            self.addLog("join rtc room success")
            AgentSettingManager.shared.updateRoomStatus(.connected)
            self.selectTable?.updateStatus()
        }else{
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.joinFailed + "\(ret)")
            self.addLog("join rtc room failed ret: \(ret)")
            AgentSettingManager.shared.updateRoomStatus(.disconnected)
            self.selectTable?.updateStatus()
        }
    }
    
    private func leaveChannel() {
        SVProgressHUD.dismiss()
        
        AgentSettingManager.shared.updateRoomStatus(.unload)
        AgentSettingManager.shared.updateAgentStatus(.unload)
        AgentSettingManager.shared.updateRoomId("")
        agentManager.destroy()
    }
    
    private func setupDenoise() {
        if isDenoise {
            addLog("isDenoise true")
            agentManager.openDenoise()
        } else {
            addLog("isDenoise false")
            agentManager.closeDenoise()
        }
    }
    
    private func setupMuteState() {
        agentManager.muteVoice(state: isMute)
        updateMuteButtonAppearance()
    }
    
    private func updateMuteButtonAppearance() {
        let backgroundColor = isMute ? UIColor(hex: 0x333333) : UIColor(hex: 0x00C2FF)
        let image = isMute ? UIImage.va_named("ic_agent_detail_mute") : UIImage.va_named("ic_agent_detail_unmute")
        let smallImage = isMute ? UIImage.va_named("ic_agent_detail_mute_small") : UIImage.va_named("ic_agent_detail_unmute_small")
        
        muteButton.setBackgroundImage(UIImage(color: backgroundColor ?? .clear, size: CGSize(width: 1, height: 1)), for: .normal)
        muteButton.setImage(image, for: .normal)
        micStateImageView.image = smallImage
    }
    
    private func addLog(_ txt: String) {
        AgentLogger.info(txt)
    }
    
    private func handleTipsAction() {
        print("Tips button tapped")
        selectTableMask.isHidden = false
        let v = AgentSettingInfoView()
        self.view.addSubview(v)
        selectTable = v
        let button = topBar.networkSignalView
        v.snp.makeConstraints { make in
            make.right.equalTo(button.snp.right).offset(20)
            make.top.equalTo(button.snp.bottom)
            make.width.equalTo(320)
            make.height.equalTo(290)
        }
    }
    
    private func extractJsonData(from rawString: String) -> Data? {
        let components = rawString.components(separatedBy: "|")
        guard components.count >= 4 else { return nil }
        let base64String = components[3]
        return Data(base64Encoded: base64String)
    }
    
    @objc func onClickHideTable(_ sender: UIButton) {
        selectTable?.removeFromSuperview()
        selectTable = nil
        selectTableMask.isHidden = true
    }
}

// MARK: - AgoraRtcEngineDelegate
extension LivingViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        addLog("engine didOccurError: \(errorCode.rawValue)")
        SVProgressHUD.dismiss()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        addLog("didLeaveChannelWith : \(stats)")
        print("didLeaveChannelWith")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        addLog("connectionChangedTo: \(state), reason: \(reason)")
        if reason == .reasonInterrupted {
            AgentSettingManager.shared.updateAgentStatus(.disconnected)
            AgentSettingManager.shared.updateRoomStatus(.disconnected)
        } else if reason == .reasonRejoinSuccess {
            AgentSettingManager.shared.updateAgentStatus(.connected)
            AgentSettingManager.shared.updateRoomStatus(.connected)
        }
        
        if state == .failed {
            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.roomError)
            self.leaveChannel()
            self.dismiss(animated: false)
        } else if state == .disconnected {
//            SVProgressHUD.showError(withStatus: <#T##String?#>)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        addLog("local user didJoinChannel uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        addLog("remote user didJoinedOfUid uid: \(uid)")
        if (uid == agentUid) {
            SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Conversation.agentJoined)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("user didOfflineOfUid uid: \(uid)")
        if (uid == agentUid && !stopInitiative) {
            AgentSettingManager.shared.updateAgentStatus(.disconnected)
            self.selectTable?.updateStatus()
            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Conversation.agentLeave)
            restartAgent()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        self.rtcToken = ""
        addLog("tokenPrivilegeWillExpire")
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: "\(uid)",
            types: [.rtc]
        ) { [weak self] token in
            self?.addLog("regenerate token is: \(token ?? "")")
            guard let self = self, let token = token else {
                return
            }
            self.addLog("will update token: \(token)")
            let rtcEnigne = self.agentManager.getRtcEntine()
            rtcEnigne.renewToken(token)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        topBar.updateNetworkStatus(NetworkStatus(agoraQuality: txQuality))
    }
        
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        guard let rawString = String(data: data, encoding: .utf8) else {
            print("Failed to convert data to string")
            return
        }
        
        print("raw string: \(rawString)")
        // Use message parser to process the message
        if let message = messageParser.parseMessage(rawString) {
            print("receive msg: \(message)")
            handleStreamMessage(message)
        }
    }
    
    private func handleStreamMessage(_ message: [String: Any]) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        speakers.forEach { info in
            if (info.uid == agentUid) {
                var currentVolume: CGFloat = 0
                let minValue = (self.waveView.getWaveWidth()) * 1.2
                let maxValue = minValue * 2
                for volumeInfo in speakers {
                    if (volumeInfo.uid == 0) {
                    } else {
                        currentVolume = CGFloat(volumeInfo.volume) / 256
                        break
                    }
                }
                
                let heights = [
                    mapValueToRange1(value1: currentVolume, x: minValue, y: maxValue),
                    mapValueToRange2(value1: currentVolume, x: minValue, y: maxValue),
                    mapValueToRange3(value1: currentVolume, x: minValue, y: maxValue),
                    mapValueToRange4(value1: currentVolume, x: minValue, y: maxValue),
                ]
                self.waveView.updateAnimation(duration: 0.2, heights: heights)
            }
        }
    }
}
// MARK: - AgentSettingViewDelegate
extension LivingViewController: AgentSettingViewDelegate {
    func onClickNoiseCancellationChanged(isOn: Bool) {
        isDenoise = isOn
        setupDenoise()
    }
    
    func onClickVoice() {
        let voiceId = AgentSettingManager.shared.currentVoiceType.voiceId
        SVProgressHUD.show()
        agentManager.updateAgent(agentUid: self.agent_rtc_id, appId: AppContext.shared.appId, voiceId: voiceId) { error in
            SVProgressHUD.dismiss()
            guard let error = error else {
                return
            }
            
            SVProgressHUD.showError(withStatus: error.message)
            self.dismiss(animated: false)
        }
    }
}

// MARK: - Wave
extension LivingViewController {
    func randomMultiplier() -> CGFloat {
        return CGFloat.random(in: 0.5...1.5) // Generate a random number between 0.5 and 1.5
    }

    func mapValueToRange1(value1: CGFloat, x: CGFloat, y: CGFloat) -> CGFloat {
        if value1 == 0 {
            return x // Return x instead of 0
        }
        let scaledValue1 = min(max(value1, 0.0), 1.0)
        let mappedValue = x + (scaledValue1 * (y - x) * 0.5) // Scale down the range
        return max(min(mappedValue * randomMultiplier(), y), x) // Ensure the returned value is within [x, y]
    }

    func mapValueToRange2(value1: CGFloat, x: CGFloat, y: CGFloat) -> CGFloat {
        if value1 == 0 {
            return x // Return x instead of 0
        }
        let scaledValue1 = min(max(value1, 0.0), 1.0)
        let mappedValue = x + (scaledValue1 * (y - x) * 0.75) // Scale down the range differently
        return max(min(mappedValue * randomMultiplier(), y), x) // Ensure the returned value is within [x, y]
    }

    func mapValueToRange3(value1: CGFloat, x: CGFloat, y: CGFloat) -> CGFloat {
        if value1 == 0 {
            return x // Return x instead of 0
        }
        let scaledValue1 = min(max(value1, 0.0), 1.0)
        let mappedValue = x + (scaledValue1 * (y - x) * 0.5) // Same scaling as mapValueToRange1
        return max(min(mappedValue * randomMultiplier(), y), x) // Ensure the returned value is within [x, y]
    }

    func mapValueToRange4(value1: CGFloat, x: CGFloat, y: CGFloat) -> CGFloat {
        if value1 == 0 {
            return x // Return x instead of 0
        }
        let scaledValue1 = min(max(value1, 0.0), 1.0)
        let mappedValue = x + (scaledValue1 * (y - x) * 0.75) // Same scaling as mapValueToRange2
        return max(min(mappedValue * randomMultiplier(), y), x) // Ensure the returned value is within [x, y]
    }
}

// MARK: - Actions
private extension LivingViewController {
    func stopPageAction() {
        agentManager.stopAgent(agentUid: self.agent_rtc_id) { err, res in
        }
        stopInitiative = false
        self.leaveChannel()
        self.dismiss(animated: false)
        self.fromVC?.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleEndCallAction() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.endCallLoading)
        addLog("begin stop agent")
        stopInitiative = true
        self.topBar.backButton.isEnabled = false
        self.topBar.backButton.alpha = 0.5
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        agentManager.stopAgent(agentUid: self.agent_rtc_id) { [weak self] err, res in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            self.closeButton.isEnabled = true
            self.closeButton.alpha = 1.0
            self.topBar.backButton.isEnabled = true
            self.topBar.backButton.alpha = 1.0
            
            guard let error = err else {
                SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.endCallLeave)
                self.leaveChannel()
                addLog("stop agent success")
                self.dismiss(animated: false)
                return
            }
            
            SVProgressHUD.showInfo(withStatus: error.localizedDescription)
            addLog("stop agent failed: \(error.localizedDescription)")
            stopInitiative = false
            
            self.dismiss(animated: false)
            return
        }
    }
    
    @objc func handleMuteAction(_ sender: UIButton) {
        isMute = !isMute
        setupMuteState()
    }
    
    @objc func handleSettingAction() {
        let settingVc = AgentSettingViewController()
        settingVc.delegate = self
        let navigationVC = UINavigationController(rootViewController: settingVc)
        present(navigationVC, animated: true)
    }
    
    @objc func handleMsgAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        
    }
}

