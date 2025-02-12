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
    private let avatarUid: UInt = 998
    private var channelName = ""
    
    private var isFrontCamera = false
    
    private var engine: AgoraRtcEngineKit!
    
    private var networkStatus: Int? = nil
    
    var isAgentStarted = false {
        didSet {
            if oldValue != isAgentStarted {
                if (isAgentStarted) {
                    DHSceneManager.shared.updateRoomStatus(.connected)
                } else {
                    DHSceneManager.shared.updateRoomStatus(.disconnected)
                }
                DHSceneManager.shared.agentStarted = isAgentStarted
                updateViewState()
            }
        }
    }
    
    private var selectTable: AgentSettingInfoView? = nil
    private var selectTableMask = UIButton(type: .custom)
    
    private var topBar: DigitalHumanSettingBar!
    
    // centerContentView: [notJoinedView, agentVideoView, pipContentView]
    private var centerView: UIView!
    
    // notJoinedView: [agentImageView, statusLabel]
    private var notJoinedView: UIView!
    private var notJoinedImageView: UIImageView!
    private var notJoinedLabel: UILabel!
    // agentContentView: [aiNameView, agentVideoView]
    private var agentContentView: UIView!
    private var agentVideoView: UIView!
    // aiNameView: [aiNameLabel, aiNameImage]
    private var aiNameView: UIView!
    private var aiNameLabel: UILabel!
    private var aiNameImage: UIImageView!
    
    // pipContentView: [userVideoView]
    private var miniView: AgentDraggableView!
    // userContentView: [userAvatarLabel, userVideoView, userNameView]
    private var userContentView: UIView!
    private var userVideoView: UIView!
    private var userAvatarLabel: UILabel!
    // userNameView: [userNameLabel, micStateImageView]
    private var userNameView: UIView!
    private var userNameLabel: UILabel!
    private var micStateImageView: UIImageView!
    
    private var joinCallButton: UIButton!
    // callingBottomView: [closeButton, muteButton, videoButton]
    private var callingBottomView: UIView!
    private var endCallButton: UIButton!
    private var micButton: UIButton!
    private var cameraButton: UIButton!
    
    private var stopInitiative = false
        
    deinit {
        DHSceneManager.shared.resetData()
        engine.stopPreview()
        engine.leaveChannel()
        DigitalHumanAPI.shared.stopAgent(channelName: channelName) { err, res in
            if err != nil {
                print("Failed to stop agent")
            } else {
                print("Agent stopped successfully")
            }
        }
        AgoraRtcEngineKit.destroy()
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
    
    private func createRtcEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = AppContext.shared.appId
        config.channelProfile = .liveBroadcasting
        config.audioScenario = .default
        engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}");
        engine.setParameters("{\"che.audio.sf.enabled\":true}");
        DHSceneManager.shared.updateDenoise(isOn: false)
        engine.enableAudioVolumeIndication(100, smooth: 10, reportVad: false)
        engine.setClientRole(.broadcaster)
        
        // setup local canvas
        let localCanvas = AgoraRtcVideoCanvas()
        localCanvas.mirrorMode = .disabled
        localCanvas.setupMode = .add
        localCanvas.renderMode = .hidden
        localCanvas.view = userVideoView
        localCanvas.uid = localUid
        engine.setupLocalVideo(localCanvas)
        
        // setup remote canvas
        let remoteCanvas = AgoraRtcVideoCanvas()
        remoteCanvas.mirrorMode = .disabled
        remoteCanvas.setupMode = .add
        remoteCanvas.renderMode = .hidden
        remoteCanvas.view = agentVideoView
        remoteCanvas.uid = avatarUid
        engine.setupRemoteVideo(remoteCanvas)
        
        DHSceneManager.shared.rtcEngine = engine
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
        engine.setParameters("{\"che.audio.aec.split_srate_for_48k\":16000}")
        engine.setParameters("{\"che.audio.sf.enabled\":false}")
        DHSceneManager.shared.updateDenoise(isOn: true)
        engine.enableVideo()
        engine.adjustRecordingSignalVolume(100)
        let ret = engine.joinChannel(byToken: rtcToken, channelId: channelName, uid: localUid, mediaOptions: options)
        if (ret == 0) {
            self.addLog("join rtc room success")
            self.selectTable?.updateStatus()
        }else{
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.joinFailed + "\(ret)")
            self.addLog("join rtc room failed ret: \(ret)")
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
            topBar.updateNetworkStatus(NetworkStatus(agoraQuality: .excellent))
            notJoinedView.isHidden = true
            userContentView.isHidden = false
            agentContentView.isHidden = false
            miniView.isHidden = false
            joinCallButton.isHidden = true
            callingBottomView.isHidden = false
            if cameraButton.isSelected {
                userVideoView.isHidden = true
            } else {
                userVideoView.isHidden = false
            }
        } else {
            topBar.updateNetworkStatus(NetworkStatus(agoraQuality: .bad))
            notJoinedView.isHidden = false
            userContentView.isHidden = true
            agentContentView.isHidden = true
            miniView.isHidden = true
            joinCallButton.isHidden = false
            callingBottomView.isHidden = true
            userVideoView.isHidden = true
            
            if (micButton.isSelected) {
                micButton.isSelected = false
                updateMicState()
            }
            if (cameraButton.isSelected) {
                cameraButton.isSelected = false
                updateCameraState()
            }
            // reset video view
            userContentView.removeFromSuperview()
            miniView.addSubview(userContentView)
            userContentView.frame = miniView.bounds
            userContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            agentContentView.removeFromSuperview()
            centerView.addSubview(agentContentView)
            agentContentView.frame = centerView.bounds
            agentContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            centerView.bringSubviewToFront(miniView)
        }
    }
}

// MARK: - Actions
private extension DigitalHumanViewController {
    @objc private func onClickStartAgent() {
        DHSceneManager.shared.channelName = channelName
        DHSceneManager.shared.uid = localUid
        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
        addLog("begin start agent")
        DigitalHumanAPI.shared.startAgent(uid: localUid, agentUid: agentUid, avatarUid: avatarUid, channelName: channelName) { [weak self] err in
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
            addLog("start agent success")
        }
    }
    
    @objc func onClickBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onClickEndCall() {
        engine.stopPreview()
        engine.muteLocalVideoStream(true)
        engine.leaveChannel()
        userVideoView.isHidden = true

        SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.endCallLoading)
        addLog("begin stop agent")
        DigitalHumanAPI.shared.stopAgent(channelName: channelName) { [weak self] err, res in
            guard let self = self else { return }
            isAgentStarted = false
            SVProgressHUD.dismiss()
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.endCallLeave)
            addLog("stop agent success")
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
            engine.stopPreview()
            engine.muteLocalVideoStream(true)
            userVideoView.isHidden = true
        } else {
            engine.startPreview()
            engine.muteLocalVideoStream(false)
            userVideoView.isHidden = false
        }
        updateCameraState()
    }

    @objc private func onMiniViewTapped(_ tap: UIGestureRecognizer) {
        let agentContentView_s = agentContentView.superview
        let userContentView_s = userContentView.superview
        agentContentView.removeFromSuperview()
        userContentView.removeFromSuperview()
        if let superView = agentContentView_s {
            superView.addSubview(userContentView)
            userContentView.frame = superView.bounds
            userContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        if let superView = userContentView_s {
            superView.addSubview(agentContentView)
            agentContentView.frame = superView.bounds
            agentContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        centerView.bringSubviewToFront(miniView)
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
        if (uid == avatarUid) {
            isAgentStarted = true
            SVProgressHUD.dismiss()
            SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Conversation.agentJoined)
        }
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("user didOfflineOfUid uid: \(uid)")
        if (uid == agentUid) {
            isAgentStarted = false
            self.selectTable?.updateStatus()
            SVProgressHUD.show(withStatus: ResourceManager.L10n.Conversation.agentLoading)
            addLog("begin restart agent")
            
            DigitalHumanAPI.shared.startAgent(uid: localUid, agentUid: agentUid, avatarUid: avatarUid, channelName: channelName) { [weak self] err in
                guard let self = self else { return }
                SVProgressHUD.dismiss()
                if let error = err {
                    SVProgressHUD.showInfo(withStatus: error.message)
                    engine.leaveChannel()
                    isAgentStarted = false
                    addLog("restart agent failed : \(error.message)")
                    return
                }
                isAgentStarted = true
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
        
        centerView = UIView()
        centerView.backgroundColor = UIColor(hex:0x222222)
        centerView.layerCornerRadius = 16
        centerView.clipsToBounds = true
        view.addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-120)
        }
        
        notJoinedView = UIView()
        centerView.addSubview(notJoinedView)
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
            label.textColor = UIColor.themColor(named: "ai_icontext4")
            notJoinedView.addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalTo(notJoinedImageView.snp.bottom).offset(20)
                make.centerX.equalToSuperview()
            }
            return label
        }()
        
        agentContentView = UIView()
        centerView.addSubview(agentContentView)
        agentContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        agentVideoView = UIView()
        agentContentView.addSubview(agentVideoView)
        agentVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        miniView = AgentDraggableView()
        miniView.backgroundColor = UIColor(hex:0x333333)
        miniView.layerCornerRadius = 8
        miniView.clipsToBounds = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onMiniViewTapped(_:)))
        miniView.addGestureRecognizer(tapGesture)
        miniView.isUserInteractionEnabled = true
        centerView.addSubview(miniView)
        miniView.snp.makeConstraints { make in
            make.width.equalTo(192)
            make.height.equalTo(100)
            make.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        userContentView = UIView()
        miniView.addSubview(userContentView)
        userContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        userAvatarLabel = UILabel()
        userAvatarLabel.textColor = UIColor(hex:0x222222)
        userAvatarLabel.backgroundColor = UIColor(hex:0xBDCFDB)
        userAvatarLabel.text = "Y"
        userAvatarLabel.textAlignment = .center
        userAvatarLabel.layerCornerRadius = 30
        userAvatarLabel.clipsToBounds = true
        userContentView.addSubview(userAvatarLabel)
        userAvatarLabel.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.center.equalTo(userContentView)
        }
        
        userVideoView = UIView()
        userContentView.addSubview(userVideoView)
        userVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        userNameView = UIView()
        userNameView.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        userNameView.layerCornerRadius = 4
        userNameView.clipsToBounds = true
        userContentView.addSubview(userNameView)
        userNameView.snp.makeConstraints { make in
            make.width.equalTo(66)
            make.height.equalTo(32)
            make.left.equalTo(userContentView).offset(8)
            make.bottom.equalTo(userContentView).offset(-8)
        }
        
        micStateImageView = UIImageView(image: UIImage.dh_named("ic_agent_detail_mute"))
        userNameView.addSubview(micStateImageView)
        micStateImageView.snp.makeConstraints { make in
            make.left.equalTo(userNameView).offset(6)
            make.width.height.equalTo(20)
            make.centerY.equalTo(userNameView)
        }

        userNameLabel = UILabel()
        userNameLabel.textColor = .white
        userNameLabel.text = "You"
        userNameLabel.font = UIFont.systemFont(ofSize: 12)
        userNameView.addSubview(userNameLabel)
        userNameLabel.snp.makeConstraints { make in
            make.left.equalTo(micStateImageView.snp.right).offset(2)
            make.centerY.equalTo(userNameView)
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
        aiNameLabel.font = UIFont.systemFont(ofSize: 14)
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
        micButton.setBackgroundImage(UIImage(color: UIColor(named: "#00c2ff")!, size: CGSize(width: 1, height: 1)), for: .normal)
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
        
        endCallButton = UIButton(type: .custom)
        endCallButton.setTitle(ResourceManager.L10n.Conversation.buttonEndCall, for: .normal)
        endCallButton.addTarget(self, action: #selector(onClickEndCall), for: .touchUpInside)
        endCallButton.titleLabel?.textAlignment = .center
        endCallButton.layerCornerRadius = 36
        endCallButton.clipsToBounds = true
        endCallButton.setImage(UIImage.dh_named("ic_agent_detail_phone"), for: .normal)
        if let color = UIColor(hex: 0xFF414D) {
            endCallButton.setBackgroundImage(UIImage(color: color, size: CGSize(width: 1, height: 1)), for: .normal)
        }
        let closeButtonImageSpacing: CGFloat = 5
        endCallButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -closeButtonImageSpacing/2, bottom: 0, right: closeButtonImageSpacing/2)
        endCallButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: closeButtonImageSpacing/2, bottom: 0, right: -closeButtonImageSpacing/2)
        callingBottomView.addSubview(endCallButton)
        endCallButton.snp.makeConstraints { make in
            make.left.equalTo(cameraButton.snp.right).offset(16)
            make.right.equalTo(-20)
            make.width.height.equalTo(72)
            make.centerY.equalToSuperview()
        }
        
        joinCallButton = UIButton(type: .custom)
        joinCallButton.setTitle(ResourceManager.L10n.Join.buttonTitle, for: .normal)
        joinCallButton.titleLabel?.font = .systemFont(ofSize: 18)
        joinCallButton.setTitleColor(UIColor.themColor(named: "ai_icontext1"), for: .normal)
        joinCallButton.backgroundColor = UIColor(named: "#0097d4")
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
        
        selectTableMask.addTarget(self, action: #selector(onClickHideTable(_ :)), for: .touchUpInside)
        selectTableMask.isHidden = true
        view.addSubview(selectTableMask)
        selectTableMask.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }
    }
}
