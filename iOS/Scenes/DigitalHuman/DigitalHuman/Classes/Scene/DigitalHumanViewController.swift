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
    private let agentUid: UInt = 999
    private var channelName = ""
    
    private var isFrontCamera = false
    
    private var engine: AgoraRtcEngineKit!
    
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
    
    private var topBar: DigitalHumanSettingBar!
    // contentView: [notJoinedView, agentContentView]
    private var contentView: UIView!
    
    // agentContentView: [notJoinedView, agentVideoView, aiNameView]
    private var agentContentView: UIView!
    
    // notJoinedView: [agentImageView, statusLabel]
    private var notJoinedView: UIView!
    private var notJoinedImageView: UIImageView!
    private var notJoinedLabel: UILabel!
    // agentVideoView
    private var agentVideoView: UIView!
    // aiNameView: [aiNameLabel, aiNameImage]
    private var aiNameView: UIView!
    private var aiNameLabel: UILabel!
    private var aiNameImage: UIImageView!
    
    // mineContentView: [mineContentView, mineAvatarLabel, mineVideoView, mineNameView]
    private var mineContentView: UIView!
    private var mineAvatarLabel: UILabel!
    private var mineVideoView: UIView!
    // mineNameView: [mineNameLabel, micStateImageView]
    private var mineNameView: UIView!
    private var mineNameLabel: UILabel!
    private var micStateImageView: UIImageView!
    
    private var joinCallButton: UIButton!
    // callingBottomView: [closeButton, muteButton, videoButton]
    private var callingBottomView: UIView!
    private var closeButton: UIButton!
    private var micButton: UIButton!
    private var cameraButton: UIButton!
    
    private var stopInitiative = false
        
    deinit {
        engine.leaveChannel()
        DigitalHumanAPI.shared.stopAgent(channelName: channelName) { err, res in
            if err != nil {
                print("Failed to stop agent")
            } else {
                print("Agent stopped successfully")
            }
        }
        AgoraRtcEngineKit.destroy()
        AgoraManager.shared.resetData()
        SVProgressHUD.dismiss()
        print("DigitalHumanViewController deinit")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        channelName = "agora_\(Int.random(in: 1..<10000000))"
        localUid = UInt.random(in: 1000..<10000000)
        setupViews()
        
        createRtcEngine()
        updateMicState()
        updateCameraState()
        updateViewState()
        
        getToken { _ in }
        setupAgentCoordinator()
        
        PermissionManager.checkBothMediaPermissions { a, b in
            guard a, b else {
                self.navigationController?.popViewController()
                return
            }
            DispatchQueue.main.async {
                self.engine.enableVideo()
                self.engine.enableAudio()
            }
        }
    }
    
    private func setupAgentCoordinator() {
        AgentSettingManager.shared.updateRoomId(channelName)
    }
    
    private func createRtcEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = AppContext.shared.appId
        config.channelProfile = .liveBroadcasting
        config.audioScenario = .default
        engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}");
        engine.setParameters("{\"che.audio.sf.enabled\":true}");
        AgoraManager.shared.updateDenoise(isOn: false)
        engine.enableAudioVolumeIndication(100, smooth: 10, reportVad: false)
        engine.setClientRole(.broadcaster)
        
        // setup local canvas
        let localCanvas = AgoraRtcVideoCanvas()
        localCanvas.mirrorMode = .disabled
        localCanvas.setupMode = .add
        localCanvas.renderMode = .hidden
        localCanvas.view = mineVideoView
        localCanvas.uid = localUid
        engine.setupLocalVideo(localCanvas)
        
        // setup remote canvas
        let remoteCanvas = AgoraRtcVideoCanvas()
        remoteCanvas.mirrorMode = .disabled
        remoteCanvas.setupMode = .add
        remoteCanvas.renderMode = .hidden
        remoteCanvas.view = agentVideoView
        remoteCanvas.uid = agentUid
        engine.setupRemoteVideo(remoteCanvas)
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
    
    private func joinChannel() {
        let options = AgoraRtcChannelMediaOptions()
        options.clientRoleType = .broadcaster
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        let ret = engine.joinChannel(byToken: rtcToken, channelId: channelName, uid: localUid, mediaOptions: options)
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
    
    private func updateMicState() {
        let isMute = micButton.isSelected
        let backgroundColor = isMute ? UIColor(hex: 0x333333) : UIColor(hex: 0x00C2FF)
        let image = isMute ? UIImage.dh_named("ic_agent_detail_mute") : UIImage.dh_named("ic_agent_detail_unmute")
        let smallImage = isMute ? UIImage.dh_named("ic_agent_detail_mute_small") : UIImage.dh_named("ic_agent_detail_unmute_small")
        
        micButton.setBackgroundImage(UIImage(color: backgroundColor ?? .clear, size: CGSize(width: 1, height: 1)), for: .normal)
        micButton.setImage(image, for: .normal)
        micStateImageView.image = smallImage
    }
    
    private func updateCameraState() {
        let isMute = cameraButton.isSelected
        let backgroundColor = isMute ? UIColor(hex: 0x333333) : UIColor(hex: 0x00C2FF)
        let image = isMute ? UIImage.dh_named("ic_agent_detail_video_mute") : UIImage.dh_named("ic_agent_detail_video_unmute")
        cameraButton.setBackgroundImage(UIImage(color: backgroundColor ?? .clear, size: CGSize(width: 1, height: 1)), for: .normal)
        cameraButton.setImage(image, for: .normal)
    }
    
    private func addLog(_ txt: String) {
        AgentLogger.info(txt)
    }
    
    @objc private func onClickRoomInfo(_ sender: UIButton) {
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
            agentVideoView.isHidden = false
            mineContentView.isHidden = false
            joinCallButton.isHidden = true
            callingBottomView.isHidden = false
            aiNameView.isHidden = false
        } else {
            notJoinedView.isHidden = false
            agentVideoView.isHidden = true
            mineContentView.isHidden = true
            joinCallButton.isHidden = false
            callingBottomView.isHidden = true
            aiNameView.isHidden = true
        }
    }
    
    private func resetSceneState() {
        if (micButton.isSelected) {
            micButton.isSelected = false
            engine.adjustRecordingSignalVolume(100)
            updateMicState()
        }
        if (cameraButton.isSelected) {
            cameraButton.isSelected = false
            updateCameraState()
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
        
        DigitalHumanAPI.shared.startAgent(uid: Int(localUid), agentUid: agentUid, channelName: channelName) { [weak self] err in
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
        }
    }
    
    @objc func onClickBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickEndCall() {
        engine.leaveChannel()
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.endCallLoading)
        addLog("begin stop agent")
        self.topBar.backButton.isEnabled = false
        self.topBar.backButton.alpha = 0.5
        closeButton.isEnabled = false
        closeButton.alpha = 0.5
        DigitalHumanAPI.shared.stopAgent(channelName: channelName) { [weak self] err, res in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.endCallLeave)
            self.closeButton.isEnabled = true
            self.closeButton.alpha = 1.0
            self.topBar.backButton.isEnabled = true
            self.topBar.backButton.alpha = 1.0
            
            self.resetSceneState()
            isAgentStarted = false
            addLog("stop agent success")
            return
        }
    }
    
    @objc func onClickMic(_ sender: UIButton) {
        sender.isSelected.toggle()
        engine.adjustRecordingSignalVolume(sender.isSelected ? 0 : 100)
        updateMicState()
    }
    
    @objc func onClickSetting(_ sender: UIButton) {
        let settingVc = DigitalHumanSettingViewController()
        let navigationVC = UINavigationController(rootViewController: settingVc)
        present(navigationVC, animated: true)
    }
    
    @objc func onClickCamera(_ sender: UIButton) {
        sender.isSelected.toggle()
        if (sender.isSelected) {
            engine.disableVideo()
            mineVideoView.isHidden = true
        } else {
            engine.enableVideo()
            mineVideoView.isHidden = false
        }
        updateCameraState()
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
// MARK: - NetworkSignalViewDelegate
extension DigitalHumanViewController: NetworkSignalViewDelegate {
    func networkSignalView(_ view: NetworkSignalView, didClickNetworkButton button: UIButton) {
        selectTableMask.isHidden = false
        let v = AgentNetworkInfoView()
        self.view.addSubview(v)
        selectTable = v
        let button = topBar.networkSignalView
        v.snp.makeConstraints { make in
            make.right.equalTo(button.snp.right).offset(20)
            make.top.equalTo(button.snp.bottom)
            make.width.equalTo(304)
            make.height.equalTo(104)
        }
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
            onClickEndCall()
        } else if state == .disconnected {
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        addLog("local user didJoinChannel uid: \(uid)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        addLog("remote user didJoinedOfUid uid: \(uid)")
        if (uid == agentUid) {
            AgoraManager.shared.agentStarted = true
            isAgentStarted = true
            SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Conversation.agentJoined)
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("user didOfflineOfUid uid: \(uid)")
        if (uid == agentUid && !stopInitiative) {
            AgentSettingManager.shared.updateAgentStatus(.disconnected)
            self.selectTable?.updateStatus()
            SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
            addLog("begin restart agent")
            closeButton.isEnabled = false
            closeButton.alpha = 0.5
            topBar.backButton.isEnabled = false
            topBar.backButton.alpha = 0.5
            
            DigitalHumanAPI.shared.startAgent(uid: Int(localUid), agentUid: agentUid, channelName: channelName) { [weak self] err in
                guard let self = self else { return }
                SVProgressHUD.dismiss()
                self.closeButton.isEnabled = true
                self.closeButton.alpha = 1.0
                self.topBar.backButton.isEnabled = true
                self.topBar.backButton.alpha = 1.0
                if let error = err {
                    SVProgressHUD.showInfo(withStatus: error.message)
                    engine.leaveChannel()
                    isAgentStarted = false
                    AgoraManager.shared.agentStarted = false
                    self.resetSceneState()
                    addLog("restart agent failed : \(error.message)")
                    return
                }
                AgentSettingManager.shared.updateAgentStatus(.connected)
                self.selectTable?.updateStatus()
                addLog("restart agent success")
            }
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        self.rtcToken = nil
        addLog("tokenPrivilegeWillExpire")
        getToken { isOK in
            if isOK, let token = self.rtcToken {
                self.engine.renewToken(token)
            } else {
                self.onClickEndCall()
            }
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
// MARK: - Views
private extension DigitalHumanViewController {
    private func setupViews() {
        view.backgroundColor = UIColor(hex: 0x111111)
        
        topBar = DigitalHumanSettingBar()
        topBar.tipsButton.addTarget(self, action: #selector(onClickRoomInfo(_ :)), for: .touchUpInside)
        topBar.settingButton.addTarget(self, action: #selector(onClickSetting(_ :)), for: .touchUpInside)
        topBar.backButton.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        topBar.networkSignalView.delegate = self
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
        
        agentContentView = UIView()
        contentView.addSubview(agentContentView)
        agentContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        agentVideoView = UIView()
        agentContentView.addSubview(agentVideoView)
        agentVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        notJoinedView = UIView()
        agentContentView.addSubview(notJoinedView)
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
        
        micButton = UIButton(type: .custom)
        micButton.addTarget(self, action: #selector(onClickMic(_ :)), for: .touchUpInside)
        micButton.titleLabel?.textAlignment = .center
        micButton.layerCornerRadius = 36
        micButton.clipsToBounds = true
        micButton.setBackgroundImage(UIImage(color: PrimaryColors.c_00c2ff, size: CGSize(width: 1, height: 1)), for: .normal)
        callingBottomView.addSubview(micButton)
        micButton.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        cameraButton = UIButton(type: .custom)
        cameraButton.addTarget(self, action: #selector(onClickCamera(_ :)), for: .touchUpInside)
        cameraButton.titleLabel?.textAlignment = .center
        cameraButton.layerCornerRadius = 36
        cameraButton.clipsToBounds = true
        cameraButton.setImage(UIImage.dh_named("ic_msg_icon"), for: .normal)
        callingBottomView.addSubview(cameraButton)
        cameraButton.snp.makeConstraints { make in
            make.left.equalTo(micButton.snp.right).offset(16)
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
            make.left.equalTo(cameraButton.snp.right).offset(16)
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
        
        mineVideoView = UIView()
        mineContentView.addSubview(mineVideoView)
        mineVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

        aiNameView = UIView()
        aiNameView.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        aiNameView.layerCornerRadius = 4
        aiNameView.clipsToBounds = true
        agentContentView.addSubview(aiNameView)
        aiNameView.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(32)
            make.left.equalTo(12)
            make.bottom.equalTo(-12)
        }

        aiNameLabel = UILabel()
        aiNameLabel.textColor = .white
        aiNameLabel.text = ResourceManager.L10n.Conversation.agentName
        aiNameLabel.textAlignment = .left
        aiNameView.addSubview(aiNameLabel)
        aiNameLabel.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }

        aiNameImage = UIImageView(image: UIImage.dh_named("ic_agent_detail_ai_voice"))
        aiNameView.addSubview(aiNameImage)
        aiNameImage.snp.makeConstraints { make in
            make.right.equalTo(-12)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
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
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = PrimaryColors.c_b3b3b3
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        settingButton.setImage(UIImage.dh_named("ic_agent_setting"), for: .normal)
        addSubview(settingButton)
        settingButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }
        addSubview(networkSignalView)
        networkSignalView.snp.makeConstraints { make in
            make.right.equalTo(settingButton.snp.left)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
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
