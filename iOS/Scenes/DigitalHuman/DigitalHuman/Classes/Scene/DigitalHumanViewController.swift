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
    
    private var rtcToken: String? = nil
    private var localUid: UInt = 0
    private let agentUid = 999
    private var channelName = ""
    private var isDenoise = false
    
    private var rtcEngine: AgoraRtcEngineKit!
    
    private var isLocalAudioMuted = false
    private var networkStatus: Int? = nil
    
    var isAgentStarted = false {
        didSet {
            if oldValue != isAgentStarted {
                updateViewState()
            }
        }
    }
    
    private var selectTable: AgentSettingInfoView? = nil
    private var selectTableMask = UIButton(type: .custom)
    
    private var topBar: AgentSettingBar!
    // contentView: [notJoinedView, videoContentView]
    private var contentView: UIView!
    // notJoinedView: [agentImageView, statusLabel]
    private var notJoinedView: UIView!
    private var notJoinedImageView: UIImageView!
    private var notJoinedLabel: UILabel!
    
    // videoContentView: [agentImageView, statusLabel, aiNameLabel, mineContentView, mineAvatarLabel, mineNameView, mineNameLabel, micStateImageView]
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
    private var apiService: AgentAPIService!
    
    var onMineContentViewClicked: (() -> Void)?
    
    deinit {
        print("DigitalHumanViewController deinit")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        channelName = "agora_\(Int.random(in: 1..<10000000))"
        localUid = UInt.random(in: 1000..<10000000)
        createRtcEngine()
        
        setupViews()
        updateMuteState()
        updateVideoState()
        updateViewState()
        
        getToken { _ in }
        setupAgentCoordinator()
    }
    
    private func setupAgentCoordinator() {
        AgentSettingManager.shared.updateRoomId(channelName)
        apiService = AgentAPIService(host: AppContext.shared.baseServerUrl)
    }
    
    private func createRtcEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = AppContext.shared.appId
        config.channelProfile = .liveBroadcasting
        config.audioScenario = .default
        rtcEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        rtcEngine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}");
        rtcEngine.setParameters("{\"che.audio.sf.enabled\":true}");
        AgoraManager.shared.updateDenoise(isOn: false)
        rtcEngine.enableAudioVolumeIndication(100, smooth: 10, reportVad: false)
    }

    private func getToken(complete: @escaping (Bool) -> Void) {
        NetworkManager.shared.generateToken(
            channelName: channelName,
            uid: "\(localUid)",
            types: [.rtc]
        ) { [weak self] token in
            self?.addLog("regenerate token is: \(token ?? "")")
            guard let self = self else {
                return
            }
            if let token = token {
                print("getToken success \(token)")
                self.rtcToken = token
                complete(true)
            } else {
                print("getToken error")
                complete(false)
            }
        }
    }
    
    private func restartAgent() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
        addLog("begin restart agent")
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        topBar.backButton.isEnabled = false
        topBar.backButton.alpha = 0.5
        
        apiService.startAgent(uid: Int(localUid), agentUid: agentUid, channelName: channelName) { [weak self] err, agentId in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            
            guard let error = err else {
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
        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        let ret = rtcEngine.joinChannel(byToken: rtcToken, channelId: channelName, uid: localUid, mediaOptions: options)
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
    
    @objc func onClickHideTable(_ sender: UIButton) {
        selectTable?.removeFromSuperview()
        selectTable = nil
        selectTableMask.isHidden = true
    }
    
    func updateViewState() {
        if isAgentStarted {
            notJoinedView.isHidden = true
            videoContentView.isHidden = false
            joinCallButton.isHidden = true
            callingBottomView.isHidden = false
        } else {
            notJoinedView.isHidden = false
            videoContentView.isHidden = true
            joinCallButton.isHidden = false
            callingBottomView.isHidden = true
        }
    }
}

// MARK: - Actions
private extension DigitalHumanViewController {
    @objc private func onClickStartAgent() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
        addLog("begin start agent")
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        topBar.backButton.isEnabled = false
        topBar.backButton.alpha = 0.5
        
        apiService.startAgent(uid: Int(localUid), agentUid: agentUid, channelName: channelName) { [weak self] err, agentId in
            guard let self = self else { return }
            if let error = err {
                SVProgressHUD.dismiss()
                SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.joinError)
                addLog("start agent failed : \(error.message)")
                self.dismiss(animated: false)
                return
            }
            if self.rtcToken == nil {
                self.getToken { [weak self] isTokenOK in
                    if isTokenOK {
                        self?.joinChannel()
                    } else {
                        SVProgressHUD.dismiss()
                        self?.addLog("Token error")
                        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.joinError)
                    }
                }
            } else {
                self.joinChannel()
            }
            self.closeButton.isEnabled = true
            self.closeButton.alpha = 1.0
            self.topBar.backButton.isEnabled = true
            self.topBar.backButton.alpha = 1.0
            addLog("start agent success")
            isAgentStarted = true
        }
    }
    
    func stopPageAction() {
        apiService.stopAgent(channelName: channelName) { err, res in
        }
        stopInitiative = false
        self.leaveChannel()
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickEndCall() {
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.endCallLoading)
        addLog("begin stop agent")
        stopInitiative = true
        self.topBar.backButton.isEnabled = false
        self.topBar.backButton.alpha = 0.5
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        apiService.stopAgent(channelName: channelName) { [weak self] err, res in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            self.closeButton.isEnabled = true
            self.closeButton.alpha = 1.0
            self.topBar.backButton.isEnabled = true
            self.topBar.backButton.alpha = 1.0
            if let error = err {
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                addLog("stop agent failed: \(error.localizedDescription)")
                stopInitiative = false
                
                return
            }
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.endCallLeave)
            self.leaveChannel()
            addLog("stop agent success")
            isAgentStarted = false
            return
        }
    }
    
    @objc func onClickAudio(_ sender: UIButton) {
        sender.isSelected.toggle()
        rtcEngine.adjustRecordingSignalVolume(sender.isSelected ? 0 : 100)
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
        self.rtcToken = nil
        addLog("tokenPrivilegeWillExpire")
        getToken { isOK in
            if isOK, let token = self.rtcToken {
                self.rtcEngine.renewToken(token)
            } else {
                self.onClickEndCall()
            }
        }
        
        
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: "\(localUid)",
            types: [.rtc]
        ) { [weak self] token in
            self?.addLog("regenerate token is: \(token ?? "")")
            guard let self = self, let token = token else {
                return
            }
            self.addLog("will update token: \(token)")
            
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
        AgoraManager.shared.updateDenoise(isOn: isOn)
    }
    
    func onClickVoice() {
        let voiceId = AgentSettingManager.shared.currentVoiceType.voiceId
        SVProgressHUD.show()
        apiService.updateAgent(appId: AppContext.shared.appId, voiceId: voiceId) { error in
            SVProgressHUD.dismiss()
            guard let error = error else {
                return
            }
            
            SVProgressHUD.showError(withStatus: error.message)
            self.dismiss(animated: false)
        }
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
            make.bottom.equalToSuperview().offset(-120)
        }
        
        // Create videoContentView and add it to contentView
        videoContentView = UIView()
        contentView.addSubview(videoContentView)
        videoContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Add notJoinedView and its subviews to videoContentView
        notJoinedView = UIView()
        contentView.addSubview(notJoinedView)
        notJoinedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        notJoinedImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.image = UIImage.dh_named("ic_agent_circle")
            notJoinedView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(254)
            }
            return imageView
        }()
        
        notJoinedLabel = {
            let label = UILabel()
            label.text = ResourceManager.L10n.Join.state
            label.font = .monospacedSystemFont(ofSize: 20, weight: .regular)
            label.textColor = PrimaryColors.c_b3b3b3
            notJoinedView.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalTo(notJoinedImageView.snp.bottom).offset(20)
                make.centerX.equalToSuperview()
            }
            return label
        }()
        
        callingBottomView = UIView()
        view.addSubview(callingBottomView)
        callingBottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(72)
        }
        
        audioButton = UIButton(type: .custom)
        audioButton.addTarget(self, action: #selector(onClickAudio(_ :)), for: .touchUpInside)
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
        closeButton.addTarget(self, action: #selector(onClickEndCall), for: .touchUpInside)
        closeButton.titleLabel?.textAlignment = .center
        closeButton.layerCornerRadius = 36
        closeButton.clipsToBounds = true
        closeButton.setImage(UIImage.dh_named("ic_agent_detail_phone"), for: .normal)
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        if let color = UIColor(hex: 0xFF414D) {
            closeButton.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        let closeButtonImageSpacing: CGFloat = 5
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -closeButtonImageSpacing/2, bottom: 0, right: closeButtonImageSpacing/2)
        closeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: closeButtonImageSpacing/2, bottom: 0, right: -closeButtonImageSpacing/2)
        callingBottomView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(videoButton.snp.right).offset(16)
            make.right.equalTo(-20)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        joinCallButton = UIButton(type: .custom)
        joinCallButton.setTitle(ResourceManager.L10n.Join.buttonTitle, for: .normal)
        joinCallButton.titleLabel?.font = .systemFont(ofSize: 18)
        joinCallButton.setTitleColor(PrimaryColors.c_ffffff, for: .normal)
        joinCallButton.backgroundColor = PrimaryColors.c_0097d4
        joinCallButton.layer.cornerRadius = 32
        joinCallButton.addTarget(self, action: #selector(onClickStartAgent), for: .touchUpInside)
        joinCallButton.setImage(UIImage.dh_named("ic_agent_join_button_icon"), for: .normal)
        let joinCallButtonImageSpacing: CGFloat = 5
        joinCallButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -joinCallButtonImageSpacing/2, bottom: 0, right: joinCallButtonImageSpacing/2)
        joinCallButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: joinCallButtonImageSpacing/2, bottom: 0, right: -joinCallButtonImageSpacing/2)
        view.addSubview(joinCallButton)
        joinCallButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.height.equalTo(72)
        }
        
        mineContentView = UIView()
        mineContentView.backgroundColor = UIColor(hex:0x333333)
        mineContentView.layerCornerRadius = 8
        mineContentView.clipsToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePipViewTapped(_:)))
        mineContentView.addGestureRecognizer(tapGesture)
        mineContentView.isUserInteractionEnabled = true
        contentView.addSubview(mineContentView)
        mineContentView.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(100)
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
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
        videoContentView.addSubview(aiNameLabel)
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
        mainView.addSubview(pipView)

        mainView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-120)
        }
        
        pipView.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(100)
            make.top.equalTo(16)
            make.right.equalTo(-16)
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

// MARK: - AgentSettingBar
class AgentSettingBar: UIView, NetworkSignalViewDelegate {
    // MARK: - Callbacks
    var onBackButtonTapped: (() -> Void)?
    var onTipsButtonTapped: (() -> Void)?
    var onSettingButtonTapped: (() -> Void)?
    var onNetworkStatusChanged: (() -> Void)?
    
    private let signalBarCount = 5
    private var signalBars: [UIView] = []
    
    lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.dh_named("ic_agora_back"), for: .normal)
        button.addTarget(self, action: #selector(backEvent), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.title
        label.font = .systemFont(ofSize: 16)
        label.textColor = PrimaryColors.c_b3b3b3
        return label
    }()
    
    private let tipsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.dh_named("ic_agent_tips_icon"), for: .normal)
        return button
    }()
    
    private lazy var settingButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.dh_named("ic_agent_setting"), for: .normal)
        button.addTarget(self, action: #selector(settingButtonClicked), for: .touchUpInside)
        return button
    }()
    
    let networkSignalView: NetworkSignalView = {
        let view = NetworkSignalView()
        return view
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        tipsButton.addTarget(self, action: #selector(tipsButtonClicked), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    private func setupViews() {
        networkSignalView.delegate = self
        [backButton, titleLabel, networkSignalView, tipsButton, settingButton].forEach { addSubview($0) }
    }
    
    private func setupConstraints() {
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        
        settingButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        networkSignalView.snp.makeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
        
        tipsButton.snp.remakeConstraints { make in
            make.right.equalTo(networkSignalView.snp.left)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        
        
    }
    
    // MARK: - Actions
    @objc func backEvent() {
        onBackButtonTapped?()
    }
    
    @objc private func tipsButtonClicked() {
        onTipsButtonTapped?()
    }
    
    @objc private func settingButtonClicked() {
        onSettingButtonTapped?()
    }
    
    func updateNetworkStatus(_ status: NetworkStatus) {
        networkSignalView.updateStatus(status)
    }
    
    func networkSignalView(_ view: NetworkSignalView, didClickNetworkButton button: UIButton) {
        onNetworkStatusChanged?()
    }
}
