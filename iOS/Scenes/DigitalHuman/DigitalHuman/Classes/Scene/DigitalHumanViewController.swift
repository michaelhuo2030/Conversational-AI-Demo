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

class DigitalHumanViewController: UIViewController {
    
    private var host = ""
    private var rtcToken = ""
    private var uid = 0
    private var agentUid = 0
    private var channelName = ""
    private var isDenoise = false
    private var agentManager: AgentManager!
    private var agent_rtc_id = ""

    private var selectTable: AgentSettingInfoView? = nil
    private var selectTableMask = UIButton(type: .custom)

    private var topBar: AgentSettingBar!
    private var contentView: UIView!
    // notJoinedView: [agentImageView, statusLabel]
    private var notJoinedView: UIView!
    private var agentImageView: UIImageView!
    private var statusLabel: UILabel!
    // videoContentView: [agentImageView, statusLabel]
    private var videoContentView: UIView!
    private var aiNameLabel: UILabel!
    private var mineContentView: UIView!
    private var mineAvatarLabel: UILabel!
    private var mineNameView: UIView!
    private var mineNameLabel: UILabel!
    private var micStateImageView: UIImageView!
    
    private var joinCallButton: UIButton!
    // callingBottomView: [closeButton, muteButton, videoButton]
    private var callingBottomView: UIView!
    private var closeButton: UIButton!
    private var audioButton: UIButton!
    private var videoButton: UIButton!
    
    private var stopInitiative = false
    
    var onMineContentViewClicked: (() -> Void)?
    
    deinit {
        print("DigitalHumanViewController deinit")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupViews()
        
        updateMuteState()
        updateVideoState()
        
        setupAgentCoordinator()
    }
    
    private func setupAgentCoordinator() {
        AgentSettingManager.shared.updateRoomId(channelName)
        agentManager = AgentManager(appId: AppContext.shared.appId, channelName: channelName, token: rtcToken, host: host, delegate: self)
//        startAgent()
        
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
    
    private func updateMuteState() {
        let isMute = audioButton.isSelected
        let backgroundColor = isMute ? UIColor(hex: 0x333333) : UIColor(hex: 0x00C2FF)
        let image = isMute ? UIImage.dh_named("ic_agent_detail_mute") : UIImage.dh_named("ic_agent_detail_unmute")
        let smallImage = isMute ? UIImage.dh_named("ic_agent_detail_mute_small") : UIImage.dh_named("ic_agent_detail_unmute_small")
        
        audioButton.setBackgroundImage(UIImage(color: backgroundColor ?? .clear, size: CGSize(width: 1, height: 1)), for: .normal)
        audioButton.setImage(image, for: .normal)
        micStateImageView.image = smallImage
    }
    
    private func updateVideoState() {
        let isMute = videoButton.isSelected
        let backgroundColor = isMute ? UIColor(hex: 0x333333) : UIColor(hex: 0x00C2FF)
        let image = isMute ? UIImage.dh_named("ic_agent_detail_video_mute") : UIImage.dh_named("ic_agent_detail_video_unmute")
        videoButton.setBackgroundImage(UIImage(color: backgroundColor ?? .clear, size: CGSize(width: 1, height: 1)), for: .normal)
        videoButton.setImage(image, for: .normal)
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
extension DigitalHumanViewController: AgoraRtcEngineDelegate {
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        addLog("engine didOccurError: \(errorCode.rawValue)")
        SVProgressHUD.dismiss()
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        addLog("didLeaveChannelWith : \(stats)")
        print("didLeaveChannelWith")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
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
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        addLog("local user didJoinChannel uid: \(uid)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        addLog("remote user didJoinedOfUid uid: \(uid)")
        if (uid == agentUid) {
            SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Conversation.agentJoined)
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("user didOfflineOfUid uid: \(uid)")
        if (uid == agentUid && !stopInitiative) {
            AgentSettingManager.shared.updateAgentStatus(.disconnected)
            self.selectTable?.updateStatus()
            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Conversation.agentLeave)
            restartAgent()
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
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
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        topBar.updateNetworkStatus(NetworkStatus(agoraQuality: txQuality))
    }
        
    public func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        
    }
}
// MARK: - AgentSettingViewDelegate
extension DigitalHumanViewController: AgentSettingViewDelegate {
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

// MARK: - Actions
private extension DigitalHumanViewController {
    func stopPageAction() {
        agentManager.stopAgent(agentUid: self.agent_rtc_id) { err, res in
        }
        stopInitiative = false
        self.leaveChannel()
        self.navigationController?.popViewController(animated: true)
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
        sender.isSelected.toggle()
        let isMute = sender.isSelected
        agentManager.muteVoice(state: isMute)
        updateMuteState()
    }
    
    @objc func handleSettingAction() {
        let settingVc = AgentSettingViewController()
        settingVc.delegate = self
        let navigationVC = UINavigationController(rootViewController: settingVc)
        present(navigationVC, animated: true)
    }
    
    @objc func handleVideoAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        updateVideoState()
    }
}

// MARK: - Views
private extension DigitalHumanViewController {
    private func setupViews() {
        view.backgroundColor = UIColor(hex: 0x111111)
        
        topBar = AgentSettingBar()
        topBar.onTipsButtonTapped = { [weak self] in
            self?.handleTipsAction()
        }
        topBar.onSettingButtonTapped = { [weak self] in
            self?.handleSettingAction()
        }
        topBar.onBackButtonTapped = { [weak self] in
            self?.stopPageAction()
        }
        view.addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        contentView = UIView()
        contentView.backgroundColor = UIColor(hex:0x222222)
        contentView.layerCornerRadius = 16
        contentView.clipsToBounds = true
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-120) // 修改为相对父视图约束
        }
        
        // Add notJoinedView and its subviews
        notJoinedView = UIView()
        contentView.addSubview(notJoinedView)
        notJoinedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        agentImageView = UIImageView()
        agentImageView.image = UIImage.dh_named("ic_agent_detail_avatar")
        agentImageView.contentMode = .scaleAspectFit
        notJoinedView.addSubview(agentImageView)
        agentImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.width.height.equalTo(120)
        }
        
        statusLabel = UILabel()
        statusLabel.text = ResourceManager.L10n.Conversation.agentLoading
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        notJoinedView.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(agentImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        
        // 创建底部按钮容器视图
        let callingBottomView = UIView()
        view.addSubview(callingBottomView)
        callingBottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(72)
        }
        
        audioButton = UIButton(type: .custom)
        audioButton.addTarget(self, action: #selector(handleMuteAction(_ :)), for: .touchUpInside)
        audioButton.titleLabel?.textAlignment = .center
        audioButton.layerCornerRadius = 36
        audioButton.clipsToBounds = true
        audioButton.setBackgroundImage(UIImage(color: PrimaryColors.c_00c2ff, size: CGSize(width: 1, height: 1)), for: .normal)
        callingBottomView.addSubview(audioButton)
        audioButton.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        videoButton = UIButton(type: .custom)
        videoButton.addTarget(self, action: #selector(handleVideoAction(_ :)), for: .touchUpInside)
        videoButton.titleLabel?.textAlignment = .center
        videoButton.layerCornerRadius = 36
        videoButton.clipsToBounds = true
        videoButton.setImage(UIImage.dh_named("ic_msg_icon"), for: .normal)
        callingBottomView.addSubview(videoButton)
        videoButton.snp.makeConstraints { make in
            make.left.equalTo(audioButton.snp.right).offset(16)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        closeButton = UIButton(type: .custom)
        closeButton.setTitle(ResourceManager.L10n.Conversation.buttonEndCall, for: .normal)
        closeButton.addTarget(self, action: #selector(handleEndCallAction), for: .touchUpInside)
        closeButton.titleLabel?.textAlignment = .center
        closeButton.layerCornerRadius = 36
        closeButton.clipsToBounds = true
        closeButton.setImage(UIImage.dh_named("ic_agent_detail_phone"), for: .normal)
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        if let color = UIColor(hex: 0xFF414D) {
            closeButton.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        let spacing: CGFloat = 5
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
        closeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        callingBottomView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(videoButton.snp.right).offset(16)
            make.right.equalTo(-20)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        mineContentView = UIView()
        mineContentView.backgroundColor = UIColor(hex:0x333333)
        mineContentView.layerCornerRadius = 8
        mineContentView.clipsToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePipViewTapped(_:)))
        mineContentView.addGestureRecognizer(tapGesture)
        mineContentView.isUserInteractionEnabled = true
        view.addSubview(mineContentView)
        mineContentView.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(100)
            make.top.equalTo(contentView).offset(16)
            make.right.equalTo(contentView).offset(-16)
        }
        
        mineAvatarLabel = UILabel()
        mineAvatarLabel.textColor = UIColor(hex:0x222222)
        mineAvatarLabel.backgroundColor = UIColor(hex:0xBDCFDB)
        mineAvatarLabel.text = "Y"
        mineAvatarLabel.textAlignment = .center
        mineAvatarLabel.layerCornerRadius = 30
        mineAvatarLabel.clipsToBounds = true
        mineContentView.addSubview(mineAvatarLabel)
        mineAvatarLabel.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.center.equalTo(mineContentView)
        }

        mineNameView = UIView()
        mineNameView.backgroundColor = UIColor(hex: 0x1D1D1D)
        mineNameView.layerCornerRadius = 4
        mineNameView.clipsToBounds = true
        mineContentView.addSubview(mineNameView)
        mineNameView.snp.makeConstraints { make in
            make.width.equalTo(66)
            make.height.equalTo(32)
            make.left.equalTo(mineContentView).offset(8)
            make.bottom.equalTo(mineContentView).offset(-8)
        }
        
        micStateImageView = UIImageView(image: UIImage.dh_named("ic_agent_detail_mute"))
        mineNameView.addSubview(micStateImageView)
        micStateImageView.snp.makeConstraints { make in
            make.left.equalTo(mineNameView).offset(6)
            make.width.height.equalTo(20)
            make.centerY.equalTo(mineNameView)
        }

        mineNameLabel = UILabel()
        mineNameLabel.textColor = .white
        mineNameLabel.text = "You"
        mineNameView.addSubview(mineNameLabel)
        mineNameLabel.snp.makeConstraints { make in
            make.left.equalTo(micStateImageView.snp.right).offset(2)
            make.centerY.equalTo(mineNameView)
        }

        aiNameLabel = UILabel()
        aiNameLabel.textColor = .white
        aiNameLabel.text = ResourceManager.L10n.Conversation.agentName
        aiNameLabel.textAlignment = .center
        aiNameLabel.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        contentView.addSubview(aiNameLabel)
        aiNameLabel.snp.makeConstraints { make in
            make.width.equalTo(75)
            make.height.equalTo(32)
            make.left.equalTo(12)
            make.bottom.equalTo(-12)
        }
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
    
    private func switchVideoLayout(mainView: UIView, pipView: UIView) {
        mainView.snp.removeConstraints()
        pipView.snp.removeConstraints()
        
        mainView.removeFromSuperview()
        pipView.removeFromSuperview()
        
        view.addSubview(mainView)
        view.addSubview(pipView)

        mainView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-120)
        }
        
        pipView.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(100)
            make.top.equalTo(mainView).offset(16)
            make.right.equalTo(mainView).offset(-16)
        }
        
        view.layoutIfNeeded()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePipViewTapped(_:)))
        pipView.addGestureRecognizer(tapGesture)
        pipView.isUserInteractionEnabled = true
    }

    @objc private func handlePipViewTapped(_ tap: UIGestureRecognizer) {
        guard let tappedView = tap.view else { return }
        tappedView.removeGestureRecognizers()
        
        if tappedView == mineContentView {
            switchVideoLayout(mainView: mineContentView, pipView: contentView)
        } else {
            switchVideoLayout(mainView: contentView, pipView: mineContentView)
        }
    }
}
