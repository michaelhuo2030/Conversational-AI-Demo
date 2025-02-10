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
    private let uid = "\(RtcEnum.getUid())"
    private let pingTimeInterval = 10.0
    private var pingTimer: Timer?
    private var channelName = ""
    private var token = ""
    private var agentUid = 0
    private var remoteAgentId = ""

    private lazy var rtcManager: RTCManager = {
        let manager = RTCManager(appId: AppContext.shared.appId, delegate: self)
        addLog("rtc sdk version: \(AgoraRtcEngineKit.getSdkVersion())")
        return manager
    }()
    
    private lazy var agentManager: AgentManager = {
        let manager = AgentManager(host: AppContext.shared.baseServerUrl)
        return manager
    }()
    
    private lazy var topBar: AgentSettingBar = {
        let view = AgentSettingBar()
        view.onTipsButtonTapped = { [weak self] in
            self?.clickTheInformationButton()
        }
        view.onSettingButtonTapped = { [weak self] in
            self?.clickTheSettingButton()
        }
        view.onBackButtonTapped = { [weak self] in
            self?.clickTheBackButton()
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
        return view
    }()
    
    private lazy var animateView: AnimateView = {
        let view = AnimateView(videoView: animateContentView)
        return view
    }()
    
    private lazy var toastView: ToastView = {
        let view = ToastView()
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1.0
        view.layer.isHidden = true
        return view
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
        AgentPreferenceManager.shared.resetData()
        print("liveing view controller deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preloadData()
        setupViews()
        setupConstraints()
    }
    
    private func preloadData() {
        AgentPreferenceManager.shared.updateUserId(uid)
        Task {
            do {
                try await fetchPresetsIfNeeded()
                try await fetchTokenIfNeeded()
            } catch {
                addLog("preloadData error: \(error)")
            }
        }
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        [topBar, contentView, bottomBar, toastView].forEach { view.addSubview($0) }
        
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
        
        toastView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp.top).offset(-94)
            make.centerX.equalTo(view)
            make.height.equalTo(40)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.bottom.equalTo(-40)
            make.left.right.equalTo(0)
            make.height.equalTo(76)
        }
    }
    
    @MainActor
    private func prepareToStartAgent() async {
        startLoading()
        
        do {
            try await fetchPresetsIfNeeded()
            try await fetchTokenIfNeeded()
            startAgentRequest()
            joinChannel()
        } catch {
            handleStartError(error: error)
        }
    }
    
    private func showNetworkErrorToast() {
        toastView.showToast(text: ResourceManager.L10n.Error.networkDisconnected)
    }
    
    private func dismissNetworkErrorToast() {
        toastView.dismiss()
    }
    
    private func startLoading() {
        bottomBar.style = .controlButtons
        
        toastView.showLoading()
    }
    
    private func stopLoading() {
        bottomBar.style = .startButton
        toastView.dismiss()
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
            stopLoading()
            stopAgent()
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
        addLog("begin stop agent")
        pingTimer?.invalidate()
        pingTimer = nil
        leaveChannel()
        stopAgentRequest()
    }
    
    private func setupMuteState(state: Bool) {
        rtcManager.muteVoice(state: state)
    }
    
    private func addLog(_ txt: String) {
        AgentLogger.info(txt)
    }
    
    private func extractJsonData(from rawString: String) -> Data? {
        let components = rawString.components(separatedBy: "|")
        guard components.count >= 4 else { return nil }
        let base64String = components[3]
        return Data(base64Encoded: base64String)
    }
}

// MARK: - Agent Request
extension ChatViewController {
    private func fetchPresetsIfNeeded() async throws {
        guard AgentPreferenceManager.shared.allPresets() == nil else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            agentManager.fetchAgentPresets { error, result in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result else {
                    continuation.resume(throwing: NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "result is empty"]))
                    return
                }
                
                AgentPreferenceManager.shared.setPresets(presets: result)
                continuation.resume()
            }
        }
    }
    
    private func fetchTokenIfNeeded() async throws {
        guard token.isEmpty else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            NetworkManager.shared.generateToken(
                channelName: "",
                uid: uid,
                types: [.rtc]
            ) { [weak self] token in
                guard let self = self else { return }
                
                if let token = token {
                    print("rtc token is : \(token)")
                    self.token = token
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "generate token error"]))
                }
            }
        }
    }
    
    private func handleStartError(error: Error) {
        stopLoading()
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }
    
    private func startAgentRequest() {
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
                prepareToPing()
                return
            }

            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.joinError)
            self.stopLoading()
            addLog("start agent failed : \(error.message)")
        }
    }
    
    private func startPingRequest() {
        let presetName = AgentPreferenceManager.shared.preference.preset?.name ?? ""
        agentManager.ping(appId: AppContext.shared.appId, channelName: channelName, presetName: presetName) { [weak self] err, res in
            guard let self = self else { return }
            guard let error = err else {
                self.addLog("ping request")
                return
            }
            
            self.addLog("ping error : \(error.message)")
        }
    }
    
    private func prepareToPing() {
        addLog("prepare to ping")
        self.pingTimer?.invalidate()
        self.pingTimer = Timer.scheduledTimer(withTimeInterval: pingTimeInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if AgentPreferenceManager.shared.information.agentState != .connected && AgentPreferenceManager.shared.information.rtcRoomState != .disconnected {
                self.stopLoading()
                self.stopAgent()
            } else {
                self.startPingRequest()
            }
        }
    }
    
    private func stopAgentRequest() {
        guard let preset = AgentPreferenceManager.shared.preference.preset else {
            return
        }
        
        if remoteAgentId.isEmpty {
            return
        }
        agentManager.stopAgent(appId: AppContext.shared.appId, agentId: remoteAgentId, channelName: channelName, presetName: preset.name) { _, _ in }
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
            showNetworkErrorToast()
            //
        } else if reason == .reasonRejoinSuccess {
            AgentPreferenceManager.shared.updateAgentState(.connected)
            AgentPreferenceManager.shared.updateRoomState(.connected)
            dismissNetworkErrorToast()
        }
        
        if state == .failed {
            SVProgressHUD.showError(withStatus: ResourceManager.L10n.Error.roomError)
            stopAgent()
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        addLog("local user didJoinChannel uid: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        toastView.dismiss()
        addLog("remote user didJoinedOfUid uid: \(uid)")
        AgentPreferenceManager.shared.updateAgentState(.connected)
        SVProgressHUD.showInfo(withStatus: ResourceManager.L10n.Conversation.agentJoined)
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
                        break
                    }
                }
                animateView.updateAgentState(.speaking, volume: Int(currentVolume))
            }
        }
    }
}

// MARK: - Actions
private extension ChatViewController {
    private func clickTheBackButton() {
        addLog("clickTheBackButton")
        stopAgent()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func clickTheInformationButton() {
        let settingVC = AgentInformationViewController()
        settingVC.modalPresentationStyle = .overFullScreen
        present(settingVC, animated: false)
    }
    
    private func clickTheSettingButton() {
        let settingVC = AgentSettingViewController()
        settingVC.modalPresentationStyle = .overFullScreen
        settingVC.agentManager = agentManager
        present(settingVC, animated: false)
    }
    
    private func clickTheCloseButton() {
        addLog("clickTheCloseButton")
        stopLoading()
        stopAgent()
    }
    
    private func clickTheStartButton() async {
        addLog("clickTheStartButton")
        await prepareToStartAgent()
    }
    
    private func clickCaptionsButton(state: Bool) {
        messageView.isHidden = !state
    }
    
    private func clickMuteButton(state: Bool) {
        setupMuteState(state: state)
    }
}

// MARK: - AgentControlToolbarDelegate
extension ChatViewController: AgentControlToolbarDelegate {
    func hangUp() {
        clickTheCloseButton()
    }
    
    func getStart() async {
        await clickTheStartButton()
    }
    
    func mute(selectedState: Bool) {
        clickMuteButton(state: selectedState)
    }
    
    func switchCaptions(selectedState: Bool) {
        clickCaptionsButton(state: selectedState)
    }
}

