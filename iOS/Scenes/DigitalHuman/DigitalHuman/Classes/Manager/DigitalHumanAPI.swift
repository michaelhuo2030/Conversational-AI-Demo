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

class DigitalHumanAPI {
    
    static let shared = DigitalHumanAPI()
    
    private var agentId: String? = nil
    
    func startAgent(uid: UInt, agentUid: UInt, avatarUid: UInt, channelName: String, completion: @escaping ((AgentError?) -> Void)) {
        let url = AgentServiceUrl.startAgentPath("v1/digitalHuman/start").toHttpUrlSting()
        let voiceId = DHSceneManager.shared.currentVoiceType.voiceId
        let parameters: [String: Any] = [
            "app_id": AppContext.shared.appId,
            "channel_name": channelName,
            "agent_rtc_uid": agentUid,
            "remote_rtc_uid": uid,
            "avatar": [
//                "avatar_id": "",
                "rtc_uid": avatarUid
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
                completion(error)
                return
            }
            
            guard let data = result["data"] as? [String: Any], let agentId = data["agent_id"] as? String else {
                let error = AgentError.serverError(code: -1, message: "data error")
                completion(error)
                return
            }
            self.agentId = agentId
            completion(nil)
            
        } failure: { msg in
            let error = AgentError.serverError(code: -1, message: msg)
            completion(error)
        }
    }
    
    func stopAgent(channelName: String, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        _stopAgent(appid: AppContext.shared.appId, completion: completion)
    }
    
    func updateAgent(appId: String, voiceId: String, completion: @escaping((AgentError?) -> Void)) {
        _updateAgent(appId: appId, voiceId: voiceId, completion: completion)
    }
    
    private func _updateAgent(appId: String, voiceId: String, retryCount: Int = AgentServiceUrl.retryCount, completion: @escaping((AgentError?) -> Void)) {
        guard let agentId = agentId else {
            let error = AgentError.serverError(code: -1, message: "agentId is empty")
            completion(error)
            return
        }
        let url = AgentServiceUrl.updateAgentPath("v1/convoai/update").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appId,
            "agent_id": agentId,
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
                self._updateAgent(appId: appId, voiceId: voiceId, retryCount: count, completion: completion)
            }
        }
    }
    
    func _stopAgent(appid:String, retryCount: Int = AgentServiceUrl.retryCount, completion: @escaping ((AgentError?, [String : Any]?) -> Void)) {
        guard let agentId = agentId else {
            let error = AgentError.serverError(code: -1, message: "agentId is empty")
            completion(error, nil)
            return
        }
        let url = AgentServiceUrl.stopAgentPath("v1/digitalHuman/stop").toHttpUrlSting()
        let parameters: [String: Any] = [
            "app_id": appid,
            "agent_id": agentId
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
                self._stopAgent(appid: appid, retryCount: count, completion: completion)
            }
        }
    }
}

enum AgentServiceUrl {
    static let retryCount = 3
    static var host: String = AppContext.shared.baseServerUrl
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
