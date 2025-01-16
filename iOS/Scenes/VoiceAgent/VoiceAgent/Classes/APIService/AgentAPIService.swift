//
//  AgentService.swift
//  Agent
//
//  Created by qinhui on 2024/10/15.
//

import Foundation
import Common

enum AgentError: Error {
    case serverError(code: Int, message: String)
    case unknownError(message: String)

    var code: Int {
        switch self {
        case .serverError(let code, _):
            return code
        case .unknownError:
            return -100
        }
    }

    var message: String {
        switch self {
        case .serverError(_, let message), .unknownError(let message):
            return message
        }
    }
}

/// Protocol that defines the core functionality for agent operations
/// Provides methods to start and stop AI agents in a channel
protocol AgentAPI {
    /// Starts an AI agent in the specified channel
    /// - Parameters:
    ///   - uid: The unique identifier for the user
    ///   - agentUid: The unique identifier for the agent
    ///   - channelName: The name of the channel where the agent will join
    ///   - completion: Callback with optional error and response data
    func startAgent(uid: Int, agentUid: Int, channelName: String, completion: @escaping ((AgentError?, String?) -> Void))
    
    /// Stops an AI agent in the specified channel
    /// - Parameters:
    ///   - agentUid: The unique identifier for the agent
    ///   - channelName: The name of the channel where the agent will leave
    ///   - completion: Callback with optional error and response data
    func stopAgent(agentUid: String, channelName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void))
    
    /// Update the agent's settings
    /// - Parameters:
    ///   - agentUid: The unique identifier for the agent
    ///   - appId: The unique identifier for the app
    ///   - voiceId: The unique identifier for the voice
    ///   - completion: Callback with optional error
    func updateAgent(agentUid: String, appId: String, voiceId: String, completion: @escaping((AgentError?) -> Void))
}

class AgentAPIService: AgentAPI {
    init(host: String) {
        AgentServiceUrl.host = host
    }
    
    func startAgent(uid: Int, agentUid: Int, channelName: String, completion: @escaping ((AgentError?, String?) -> Void)) {
        _startAgent(appid: AppContext.shared.appId, channelName: channelName, agentRtcUid: agentUid, remote_rtc_uid: uid, completion: completion)
    }
    
    func stopAgent(agentUid: String, channelName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        _stopAgent(appid: AppContext.shared.appId, agentUid: agentUid, completion: completion)
    }
    
    func updateAgent(agentUid: String, appId: String, voiceId: String, completion: @escaping((AgentError?) -> Void)) {
        _updateAgent(agentUid: agentUid, appId: appId, voiceId: voiceId, completion: completion)
    }
    
    private func _updateAgent(agentUid: String, appId: String, voiceId: String, retryCount: Int = AgentServiceUrl.retryCount, completion: @escaping((AgentError?) -> Void)) {
        let url = AgentServiceUrl.updateAgentPath("v1/convoai/update").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "agent_id": agentUid,
            "voice_id": voiceId
        ]
        
        AgentLogger.info("request update api parameters is: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error)
                return
            }
            completion(nil)
        } failure: { msg in
            let count = retryCount - 1
            if count == 0 {
                let error = AgentError.serverError(code: -1, message: msg)
                completion(error)
            } else {
                self._updateAgent(agentUid: agentUid, appId: appId, voiceId: voiceId, retryCount: count, completion: completion)
            }
        }
    }
    
    private func _startAgent(appid: String, channelName: String, agentRtcUid: Int, remote_rtc_uid: Int, greeting: String = "Hi, how can I assist you today?", retryCount: Int = AgentServiceUrl.retryCount, completion: @escaping ((AgentError?, String?) -> Void)) {
        let url = AgentServiceUrl.startAgentPath("v1/convoai/start").toHttpUrlSting()
        let voiceId = AgentSettingManager.shared.currentVoiceType.voiceId
        let parameters: [String: Any] = [
            "app_id": appid,
            "channel_name": channelName,
            "agent_rtc_uid": agentRtcUid,
            "remote_rtc_uid": remote_rtc_uid,
            "custom_llm": [
                "prompt": AgentSettingManager.shared.currentPresetType.prompt
            ],
            "tts": [
                "voice_id": voiceId
            ]
        ]
        
        AgentLogger.info("request start api parameters is: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, nil)
                return
            }
            
            guard let data = result["data"] as? [String: Any], let agentId = data["agent_id"] as? String else {
                let error = AgentError.serverError(code: -1, message: "data error")
                completion(error, nil)
                return
            }
            
            completion(nil, agentId)
            
        } failure: { msg in
            let count = retryCount - 1
            if count == 0 {
                let error = AgentError.serverError(code: -1, message: msg)
                completion(error, nil)
            } else {
                self._startAgent(appid: appid, channelName: channelName, agentRtcUid: agentRtcUid, remote_rtc_uid: remote_rtc_uid, retryCount: count, completion: completion)
            }
        }
    }
    
    func _stopAgent(appid:String, agentUid: String, retryCount: Int = AgentServiceUrl.retryCount, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("v1/convoai/stop").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appid,
            "agent_id": agentUid
        ]
        AgentLogger.info("request stop api parameters is: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, nil)
            } else {
                completion(nil, result)
            }
        } failure: { msg in
            let count = retryCount - 1
            if count == 0 {
                let error = AgentError.serverError(code: -1, message: msg)
                completion(error, nil)
            } else {
                self._stopAgent(appid: appid, agentUid: agentUid, retryCount: count, completion: completion)
            }
        }
    }
}

enum AgentServiceUrl {
    static let retryCount = 3
    static var host: String = ""
    var baseUrl: String {
        return AgentServiceUrl.host + "/"
    }
    
    case startAgentPath(String)
    case updateAgentPath(String)
    case stopAgentPath(String)
    
    public func toHttpUrlSting() -> String {
        switch self {
        case .startAgentPath(let path):
            return baseUrl + path
        case .stopAgentPath(let path):
            return baseUrl + path
        case .updateAgentPath(let path):
            return baseUrl + path
        }
    }
}
