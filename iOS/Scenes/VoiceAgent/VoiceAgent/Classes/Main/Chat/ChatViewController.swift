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

class ChatViewController: UIViewController {
    private var isDenoise = true
    private let messageParser = MessageParser()
    private let host = AppContext.shared.baseServerUrl
    private let uid = "\(RtcEnum.getUid())"
    private var channelName = ""
    private var token = ""
    private var agentUid = 0
    private var remoteAgentId = ""

    private lazy var rtcManager: RTCManager = {
        let manager = RTCManager(appId: AppContext.shared.appId, delegate: self)
        return manager
    }()
    
    private lazy var agentManager: AgentManager = {
        let manager = AgentManager(host: host)
        return manager
    }()
    
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

    private lazy var bottomBar: AgentControlToolbar = {
        let view = AgentControlToolbar()
        view.delegate = self
        return view
    }()
    
    private lazy var animateContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .purple
        return view
    }()
    
    private lazy var animateView: AnimateView = {
        let view = AnimateView(videoView: animateContentView)
        return view
    }()
    
    private lazy var loadingView: GradientBorderView = {
        let gradientBoundView = GradientBorderView()
        gradientBoundView.layer.cornerRadius = 20
        gradientBoundView.layer.masksToBounds = true
        let label = UILabel()
        label.text = ResourceManager.L10n.Join.agentConnecting
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        gradientBoundView.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalTo(gradientBoundView)
        }
        
        gradientBoundView.isHidden = true
        return gradientBoundView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.layerCornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var aiNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.text = ResourceManager.L10n.Conversation.agentName
        label.textAlignment = .center
        label.backgroundColor = UIColor(hex:0x000000, transparency: 0.25)
        return label
    }()
    
    private lazy var micStateImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.va_named("ic_agent_detail_mute"))
        return imageView
    }()
    
    private lazy var messageView: ChatView = {
        let view = ChatView()
        view.isHidden = true
        return view
    }()
        
    deinit {
        print("liveing view controller deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateToken()
        setupViews()
        setupConstraints()
        setupAgentPreference()
    }
    
    private func setupViews() {
        view.backgroundColor = PrimaryColors.c_121212
        
        [topBar, contentView, bottomBar, loadingView].forEach { view.addSubview($0) }
        
        contentView.addSubview(animateContentView)
        contentView.addSubview(aiNameLabel)
        contentView.addSubview(messageView)
        
        animateView.setupMediaPlayer(rtcManager.getRtcEntine())
    }
    
    private func setupConstraints() {
        topBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }
        
        contentView.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.top.equalTo(topBar.snp.bottom).offset(20)
            make.bottom.equalTo(bottomBar.snp.top).offset(-20)
        }
        
        animateContentView.snp.makeConstraints { make in
            make.height.equalTo(animateContentView.snp.width).multipliedBy(480.0/550.0)
            make.width.equalTo(contentView.snp.width).multipliedBy(0.9)
            make.centerX.equalTo(contentView)
            make.centerY.equalTo(contentView)
        }
        
        messageView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        loadingView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp.top).offset(-94)
            make.centerX.equalTo(view)
            make.width.equalTo(108)
            make.height.equalTo(40)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.bottom.equalTo(-40)
            make.left.right.equalTo(0)
            make.height.equalTo(76)
        }
    }
    
    private func setupAgentPreference() {
        AgentPreferenceManager.shared.updateUserId(uid)
    }
    
    private func start() {
        bottomBar.style = .controlButtons
        loadingView.isHidden = false
        if token.isEmpty {
            NetworkManager.shared.generateToken(
                channelName: "",
                uid: uid,
                types: [.rtc]
            ) { [weak self] token in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let token = token {
                        print("rtc token is : \(token)")
                        self.token = token
                        self.startAgent()
                    } else {
                        self.loadingView.isHidden = true
                        self.bottomBar.style = .startButton
                        SVProgressHUD.showInfo(withStatus: "generate token error")
                    }
                }
            }
        } else {
            startAgent()
        }
        
        joinChannel()
    }
    
    private func startRequestPing() {
        
    }
    
    private func generateToken() {
        PermissionManager.checkMicrophonePermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    SVProgressHUD.showInfo(withStatus: "Microphone usage refused")
                }
            }
        }
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: uid,
            types: [.rtc]
        ) { [weak self] token in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let token = token {
                    print("rtc token is : \(token)")
                    self.token = token
                }
            }
        }
    }
    
    private func startAgent() {
        addLog("begin start agent")
        channelName = "agora_\(RtcEnum.getChannel())"
        agentUid = AppContext.agentUid
        let aiVad = AgentPreferenceManager.shared.preference.aiVad
        let presetName = AgentPreferenceManager.shared.preference.preset?.name ?? ""
        let language = AgentPreferenceManager.shared.preference.language?.languageCode ?? ""
        agentManager.startAgent(appId: AppContext.shared.appId,
                                uid: uid,
                                agentUid: "\(agentUid)",
                                channelName: channelName,
                                aiVad: aiVad,
                                presetName: presetName,
                                language: language) { [weak self] error, remoteAgentId in
            guard let self = self else { return }

            guard let error = error else {
                if let remoteAgentId = remoteAgentId {
                    self.remoteAgentId = remoteAgentId
                }
                addLog("start agent success")
                return
            }

            bottomBar.style = .startButton
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Error.joinError)
            self.loadingView.isHidden = true
            addLog("start agent failed : \(error.message)")
        }
    }
    
    private func joinChannel() {
        let ret = rtcManager.joinChannel(token: token, channelName: channelName, uid: uid)
        if (ret == 0) {
            self.addLog("join rtc room success")
            self.setupMuteState(state: false)
            AgentPreferenceManager.shared.updateRoomState(.connected)
            AgentPreferenceManager.shared.updateRoomId(channelName)
        }else{
            SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.joinFailed + "\(ret)")
            loadingView.isHidden = true
            AgentPreferenceManager.shared.updateRoomState(.disconnected)
            self.addLog("join rtc room failed ret: \(ret)")
        }
    }
    
    private func leaveChannel() {
        AgentPreferenceManager.shared.updateRoomState(.unload)
        AgentPreferenceManager.shared.updateAgentState(.unload)
        AgentPreferenceManager.shared.updateRoomId("")
        rtcManager.leaveChannel()
        
    }
    
    private func destoryRtc() {
        leaveChannel()
        rtcManager.destroy()
    }
    
    private func stopAgent() {
        leaveChannel()
        guard let preset = AgentPreferenceManager.shared.preference.preset else {
            return
        }
        
        if remoteAgentId.isEmpty {
            return
        }
        
        agentManager.stopAgent(appId: AppContext.shared.appId, agentId: remoteAgentId, channelName: channelName, presetName: preset.name) { _, _ in }
    }
    
    private func setupMuteState(state: Bool) {
        rtcManager.muteVoice(state: state)
    }
    
    private func addLog(_ txt: String) {
        AgentLogger.info(txt)
    }
    
    private func handleTipsAction() {
        let settingVC = AgentInformationViewController()
        settingVC.modalPresentationStyle = .overFullScreen
        present(settingVC, animated: false)
    }
    
    func handleSettingAction() {
        let settingVC = AgentSettingViewController()
        settingVC.delegate = self
        settingVC.modalPresentationStyle = .overFullScreen
        present(settingVC, animated: false)
    }
    
    private func extractJsonData(from rawString: String) -> Data? {
        let components = rawString.components(separatedBy: "|")
        guard components.count >= 4 else { return nil }
        let base64String = components[3]
        return Data(base64Encoded: base64String)
    }
}

// MARK: - AgoraRtcEngineDelegate
extension ChatViewController: AgoraRtcEngineDelegate {
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
            AgentPreferenceManager.shared.updateAgentState(.disconnected)
            AgentPreferenceManager.shared.updateRoomState(.disconnected)
        } else if reason == .reasonRejoinSuccess {
            AgentPreferenceManager.shared.updateAgentState(.connected)
            AgentPreferenceManager.shared.updateRoomState(.connected)
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
        AgentPreferenceManager.shared.updateAgentState(.connected)
        loadingView.isHidden = true
        SVProgressHUD.showSuccess(withStatus: ResourceManager.L10n.Conversation.agentJoined)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        addLog("user didOfflineOfUid uid: \(uid)")
        if (uid == agentUid) {
            AgentPreferenceManager.shared.updateAgentState(.disconnected)
            stopAgent()
            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Conversation.agentLeave)
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, tokenPrivilegeWillExpire token: String) {
        self.token = ""
        addLog("tokenPrivilegeWillExpire")
        NetworkManager.shared.generateToken(
            channelName: "",
            uid: uid,
            types: [.rtc]
        ) { [weak self] token in
            self?.addLog("regenerate token is: \(token ?? "")")
            guard let self = self, let newToken = token else {
                return
            }
            self.addLog("will update token: \(newToken)")
            let rtcEnigne = self.rtcManager.getRtcEntine()
            rtcEnigne.renewToken(newToken)
            self.token = newToken
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        AgentPreferenceManager.shared.updateNetworkState(NetworkStatus(agoraQuality: txQuality))
    }
        
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        guard let rawString = String(data: data, encoding: .utf8) else {
            print("Failed to convert data to string")
            return
        }
        
//        print("raw string: \(rawString)")
        // Use message parser to process the message
        if let message = messageParser.parseMessage(rawString) {
            print("receive msg: \(message)")
            addLog("receive msg: \(message)")
            handleStreamMessage(message)
        }
    }
    
    private func handleStreamMessage(_ message: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let isFinal = message["is_final"] as? Bool ?? false
            let streamId = message["stream_id"] as? Int ?? 0
            let text = message["text"] as? String ?? ""
            let dataType = message["data_type"] as? String ?? ""
            
            // Ignore empty messages
            guard !text.isEmpty else { return }
            
            if dataType == "transcribe" {
                if streamId == 0 {
                    // AI response message
                    if !isFinal {
                        // Non-final message, update streaming content
                        if self.messageView.isLastMessageFromUser || self.messageView.isEmpty {
                            self.messageView.startNewStreamMessage()
                        }
                        self.messageView.updateStreamContent(text)
                    } else {
                        // Final message, update and complete
                        if self.messageView.isLastMessageFromUser || self.messageView.isEmpty {
                            self.messageView.startNewStreamMessage()
                        }
                        self.messageView.updateStreamContent(text)
                        self.messageView.completeStreamMessage()
                    }
                } else {
                    // User message
                    if isFinal {
                        self.messageView.addUserMessage(text)
                    }
                }
            }
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo], totalVolume: Int) {
        speakers.forEach { info in
            if (info.uid == agentUid) {
                var currentVolume: CGFloat = 0
                for volumeInfo in speakers {
                    if (volumeInfo.uid == 0) {
                    } else {
                        currentVolume = CGFloat(volumeInfo.volume)
//                        print("current volume is \(currentVolume)")
                        break
                    }
                }
                animateView.updateAgentState(.speaking, volume: Int(currentVolume))
//                videoView.updateWithVolume(Float(currentVolume))
            }
        }
    }
}
// MARK: - AgentSettingViewDelegate
extension ChatViewController: AgentSettingViewDelegate {
    func onClickNoiseCancellationChanged(isOn: Bool) {
        isDenoise = isOn
    }
    
    func onClickVoice() {
        SVProgressHUD.show()
    }
}

// MARK: - Actions
private extension ChatViewController {
    func stopPageAction() {
        stopAgent()
        self.navigationController?.popViewController(animated: true)
    }
    
    func handleEndCallAction() {
        addLog("begin stop agent")
        self.bottomBar.style = .startButton
        self.loadingView.isHidden = true
        stopAgent()
        updateAgentState(state: .disconnected)
    }
    
    private func updateAgentState(state: ConnectionStatus) {
        //TODO
//        self.agentManager.agentState = state
    }
    
    func handleCaptionsAction(state: Bool) {
        messageView.isHidden = !state
    }
}

extension ChatViewController: AgentControlToolbarDelegate {
    func hangUp() {
        handleEndCallAction()
    }
    
    func getStart() {
        start()
    }
    
    func mute(selectedState: Bool) {
        setupMuteState(state: selectedState)
    }
    
    func switchCaptions(selectedState: Bool) {
        handleCaptionsAction(state: selectedState)
    }
}

