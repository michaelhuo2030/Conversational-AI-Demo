//
//  AgentService.swift
//  Agent
//
//  Created by qinhui on 2024/10/15.
//

import Foundation
import Common

/// Protocol defining the API interface for managing AI agents
protocol AgentAPI {
    /// Starts an AI agent with the specified configuration
    /// - Parameters:
    ///   - appId: The unique identifier for the application
    ///   - uid: The user identifier
    ///   - agentUid: The AI agent's unique identifier
    ///   - channelName: The name of the channel for communication
    ///   - aiVad: Boolean flag for AI voice activity detection
    ///   - bhvs: Boolean flag for Background vocal suppression
    ///   - presetName: The name of the preset configuration
    ///   - language: The language setting for the agent
    ///   - completion: Callback with optional error, channel name and agent ID string, and server address
    func startAgent(appId:String,
                    uid: String,
                    agentUid: String,
                    channelName: String,
                    aiVad: Bool,
                    bhvs: Bool,
                    presetName: String,
                    language: String,
                    completion: @escaping ((AgentError?, String, String?, String?) -> Void))
    
    /// Stops a running AI agent
    /// - Parameters:
    ///   - appId: The unique identifier for the application
    ///   - agentId: The ID of the agent to stop
    ///   - channelName: The name of the channel
    ///   - presetName: The name of the preset configuration
    ///   - completion: Callback with optional error and response data
    func stopAgent(appId:String, agentId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void))
    
    /// Checks the connection status with the agent service
    /// - Parameters:
    ///   - appId: The unique identifier for the application
    ///   - channelName: The name of the channel
    ///   - presetName: The name of the preset configuration
    ///   - completion: Callback with optional error and response data
    func ping(appId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void))
    
    /// Retrieves the list of available agent presets
    /// - Parameter completion: Callback with optional error and array of agent presets
    func fetchAgentPresets(appId: String, completion: @escaping ((AgentError?, [AgentPreset]?) -> Void))
}

class AgentManager: AgentAPI {    
    init(host: String) {
        AgentServiceUrl.host = host
    }
    
    func fetchAgentPresets(appId: String, completion: @escaping ((AgentError?, [AgentPreset]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("v3/convoai/presetAgents").toHttpUrlSting()
        VoiceAgentLogger.info("request agent preset api: \(url)")
        let requesetBody: [String: Any] = [
            "app_id": appId
        ]
        NetworkManager.shared.getRequest(urlString: url, params: requesetBody) { result in
            VoiceAgentLogger.info("presets request response: \(result)")
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, nil)
                return
            }
            
            guard let data = result["data"] as? [[String: Any]] else {
                let error = AgentError.serverError(code: -1, message: "data error")
                completion(error, nil)
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                var presets = try JSONDecoder().decode([AgentPreset].self, from: jsonData)
                //Temporary requirement: Remove custom settings.
                presets.removeAll(where: { $0.presetType == "custom" })
                completion(nil, presets)
            } catch {
                let error = AgentError.serverError(code: -1, message: error.localizedDescription)
                completion(error, nil)
            }
        } failure: { msg in
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    func startAgent(appId:String,
                    uid: String,
                    agentUid: String,
                    channelName: String,
                    aiVad: Bool,
                    bhvs: Bool,
                    presetName: String,
                    language: String,
                    completion: @escaping ((AgentError?, String, String?, String?) -> Void)) {
        let url = AgentServiceUrl.startAgentPath("v3/convoai/start").toHttpUrlSting()
        let graphId = AppContext.shared.graphId
        var parameters:[String: Any] = [:]
        if graphId.isEmpty {
            parameters = [
                "app_id": appId,
                "preset_name": presetName,
                "channel_name": channelName,
                "agent_rtc_uid": agentUid,
                "remote_rtc_uid": uid,
                "advanced_features": [
                    "enable_aivad": aiVad,
                    "enable_bhvs": bhvs
                ],
                "asr": [
                    "language": language
                ]
            ]
        } else {
            parameters = [
                "app_id": appId,
                "preset_name": presetName,
                "channel_name": channelName,
                "agent_rtc_uid": agentUid,
                "remote_rtc_uid": uid,
                "graph_id": graphId,
                "advanced_features": [
                    "enable_aivad": aiVad,
                    "enable_bhvs": bhvs
                ],
                "asr": [
                    "language": language
                ]
            ]
        }
        
        VoiceAgentLogger.info("request start api: \(url) parameters: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            VoiceAgentLogger.info("start request response: \(result)")
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, channelName, nil, nil)
                return
            }
            
            guard let data = result["data"] as? [String: Any],
                  let agentId = data["agent_id"] as? String,
                  let server = data["agent_url"] as? String
            else {
                let error = AgentError.serverError(code: -1, message: "data error")
                completion(error, channelName, nil, nil)
                return
            }
            
            completion(nil, channelName, agentId, server)
            
        } failure: { msg in
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error,channelName, nil, nil)
        }
    }
    
    func stopAgent(appId:String, agentId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("v3/convoai/stop").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "agent_id": agentId,
            "preset_name": presetName,
            "channel_name": channelName
        ]
        VoiceAgentLogger.info("request stop api parameters is: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            VoiceAgentLogger.info("stop request response: \(result)")
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, nil)
            } else {
                completion(nil, result)
            }
        } failure: { msg in
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    func ping(appId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("v3/convoai/ping").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "channel_name": channelName,
            "preset_name": presetName
        ]
        VoiceAgentLogger.info("request ping api: \(url) parameters: \(parameters)")
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            VoiceAgentLogger.info("ping request response: \(result)")
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = AgentError.serverError(code: code, message: msg)
                completion(error, nil)
            } else {
                completion(nil, result)
            }
        } failure: { msg in
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
}

enum AgentServiceUrl {
    static let retryCount = 1
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

