//
//  AgentService.swift
//  Agent
//
//  Created by qinhui on 2024/10/15.
//

import Foundation
import Common

/// Protocol that defines the core functionality for agent operations
/// Provides methods to start and stop AI agents in a channel
protocol AgentAPI {
   
    func startAgent(appId:String, uid: String, agentUid: String, channelName: String, aiVad: Bool, presetName: String, language: String, completion: @escaping ((AgentError?, String?) -> Void))
    
    func stopAgent(appId:String, agentId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void))
    
    func ping(appId: String, channelName: String, presetName: String)
    
    func fetchAgentPresets(completion: @escaping ((AgentError?, [AgentPreset]?) -> Void))
}

class AgentManager: AgentAPI {    
    init(host: String) {
        AgentServiceUrl.host = host
    }
    
    func fetchAgentPresets(completion: @escaping ((AgentError?, [AgentPreset]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("convoai/presetAgents").toHttpUrlSting()
        NetworkManager.shared.getRequest(urlString: url) { result in
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
                let presets = try JSONDecoder().decode([AgentPreset].self, from: jsonData)
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
    
    func startAgent(appId:String, uid: String, agentUid: String, channelName: String, aiVad: Bool, presetName: String, language: String, completion: @escaping ((AgentError?, String?) -> Void)) {
        let url = AgentServiceUrl.startAgentPath("convoai/start").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "preset_name": presetName,
            "channel_name": channelName,
            "agent_rtc_uid": agentUid,
            "remote_rtc_uid": uid,
            "advanced_features": [
                "enable_aivad": aiVad
            ],
            "asr": [
                "language": language
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
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    func stopAgent(appId:String, agentId: String, channelName: String, presetName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        let url = AgentServiceUrl.stopAgentPath("convoai/stop").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "agent_id": agentId,
            "preset_name": presetName
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
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    func ping(appId: String, channelName: String, presetName: String) {
        
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

