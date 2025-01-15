//
//  ResourceManager.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/20.
//

import Foundation

public class ResourceManager {
    static let sceneName = "VoiceAgent"
    private static var bundle: Bundle? = {
        let mainBundle = Bundle(for: ResourceManager.self)
        
        if let resourceBundlePath = mainBundle.path(forResource: sceneName, ofType: "bundle") {
            if let resourceBundle = Bundle(path: resourceBundlePath) {
                return resourceBundle
            }
        }
        
        print("Warning: Falling back to main bundle")
        return mainBundle
    }()
    
    public static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
    
    public static func localizedString(_ key: String, comment: String = "") -> String {
        guard let bundle = bundle else {
            return key
        }
        var localeIdentifier = "en"
        if AppContext.shared.appArea == .mainland {
            localeIdentifier = "zh-Hans"
        }
        guard let bundlePath = bundle.path(forResource: localeIdentifier, ofType: "lproj"),
              let localizedBundle = Bundle(path: bundlePath)
        else {
            return key
        }
        let result = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
        return result
    }
}

public extension ResourceManager {
    enum L10n {
        public enum Main {
            public static let getStart = localizedString("main.get.start")
            public static let agreeTo = localizedString("main.agree.to")
            public static let termsOfService = localizedString("main.terms.vc.title")
            public static let termsService = localizedString("main.terms.service")
        }

        public enum Scene {
            public static let title = localizedString("scene.title")
            public static let aiCardTitle = localizedString("scene.ai.card.title")
            public static let aiCardDes = localizedString("scene.ai.card.des")
            public static let v2vCardTitle = localizedString("scene.v2v.card.title")
            public static let v2vCardDes = localizedString("scene.v2v.card.des")
            public static let digCardTitle = localizedString("scene.dig.card.title")
            public static let digCardDes = localizedString("scene.dig.card.des")
        }

        public enum Join {
            public static let title = localizedString("join.start.title")
            public static let state = localizedString("join.start.state")
            public static let buttonTitle = localizedString("join.start.button.title")
            public static let agentName = localizedString("join.start.agent.name")
        }

        public enum Conversation {
            public static let agentName = localizedString("conversation.agent.name")
            public static let buttonEndCall = localizedString("conversation.button.end.call")
            public static let agentLoading = localizedString("conversation.agent.loading")
            public static let agentJoined = localizedString("conversation.agent.joined")
            public static let joinFailed = localizedString("conversation.join.failed")
            public static let agentLeave = localizedString("conversation.agent.leave")
            public static let endCallLoading = localizedString("conversation.end.call.loading")
            public static let endCallLeave = localizedString("conversation.end.call.leave")
            public static let messageYou = localizedString("conversation.message.you")
            public static let messageAgentName = localizedString("conversation.message.agent.name")
            public static let clearMessageTitle = localizedString("conversation.message.alert.title")
            public static let clearMessageContent = localizedString("conversation.message.alert.content")
            public static let alertCancel = localizedString("conversation.alert.cancel")
            public static let alertClear = localizedString("conversation.alert.clear")
        }
        
        public enum Setting {
            public static let title = localizedString("setting.title")
        }

        public enum Error {
            public static let networkError = localizedString("error.network")
            public static let roomError = localizedString("error.room.error")
            public static let joinError = localizedString("error.join.error")
        }

        public enum Settings {
            public static let title = localizedString("settings.title")
            public static let preset = localizedString("settings.preset")
            public static let advanced = localizedString("settings.advanced")
            public static let device = localizedString("settings.device")
            public static let language = localizedString("settings.language")
            public static let voice = localizedString("settings.voice")
            public static let model = localizedString("settings.model")
            public static let microphone = localizedString("settings.microphone")
            public static let speaker = localizedString("settings.speaker")
            public static let noiseCancellation = localizedString("settings.noise.cancellation")
            public static let agentConnected = localizedString("settings.agent.connected")
            public static let agentDisconnected = localizedString("settings.agent.disconnected")
        }
        
        public enum ChannelInfo {
            public static let title = localizedString("channel.info.title")
            public static let agentStatus = localizedString("channel.info.agent.status")
            public static let roomStatus = localizedString("channel.info.room.status")
            public static let roomId = localizedString("channel.info.room.id")
            public static let yourId = localizedString("channel.info.your.id")
        }
    }
}
