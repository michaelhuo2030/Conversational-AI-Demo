//
//  Resource+VoiceAgent.swift
//  DigitalHuman
//
//  Created by qinhui on 2025/1/16.
//

import Foundation
import Common

extension ResourceManager {
    static func localizedString(_ key: String) -> String {
        return localizedString(key, bundleName: ConvoAIEntrance.kSceneName)
    }
    
    enum L10n {
        public enum Main {
            public static let getStart = ResourceManager.localizedString("main.get.start")
            public static let agreeTo = ResourceManager.localizedString("main.agree.to")
            public static let termsOfService = ResourceManager.localizedString("main.terms.vc.title")
            public static let termsService = ResourceManager.localizedString("main.terms.service")
        }

        public enum Scene {
            public static let aiCardDes = ResourceManager.localizedString("scene.ai.card.des")
            public static let v2vCardTitle = ResourceManager.localizedString("scene.v2v.card.title")
            public static let v2vCardDes = ResourceManager.localizedString("scene.v2v.card.des")
            public static let digCardTitle = ResourceManager.localizedString("scene.dig.card.title")
            public static let digCardDes = ResourceManager.localizedString("scene.dig.card.des")
        }

        public enum Login {
            public static let title = ResourceManager.localizedString("login.title")
            public static let description = ResourceManager.localizedString("login.description")
            public static let buttonTitle = ResourceManager.localizedString("login.start.button.title")
            public static let termsServicePrefix = ResourceManager.localizedString("login.terms.service.prefix")
            public static let termsServiceName = ResourceManager.localizedString("login.terms.service.name")
            public static let termsServiceAndWord = ResourceManager.localizedString("login.terms.service.and")
            public static let termsPrivacyName = ResourceManager.localizedString("login.privacy.policy.name")
            public static let termsServiceTips = ResourceManager.localizedString("login.terms.service.tips")
            public static let sessionExpired = ResourceManager.localizedString("login.session.expired")
            
            public static let logoutAlertTitle = ResourceManager.localizedString("logout.alert.title")
            public static let logoutAlertDescription = ResourceManager.localizedString("logout.alert.description")
            public static let logoutAlertConfirm = ResourceManager.localizedString("logout.alert.cancel.title")
            public static let logoutAlertCancel = ResourceManager.localizedString("logout.alert.confirm.title")

        }

        public enum Join {
            public static let title = ResourceManager.localizedString("join.start.title")
            public static let state = ResourceManager.localizedString("join.start.state")
            public static let tips = ResourceManager.localizedString("join.start.tips")
            public static let buttonTitle = ResourceManager.localizedString("join.start.button.title")
            public static let agentName = ResourceManager.localizedString("join.start.agent.name")
            public static let agentConnecting = ResourceManager.localizedString("conversation.agent.connecting")
            public static let joinTimeoutTips = ResourceManager.localizedString("join.timeout.tips")
        }

        public enum Conversation {
            public static let appHello = ResourceManager.localizedString("conversation.ai.hello")
            public static let appWelcomeTitle = ResourceManager.localizedString("conversation.ai.welcome.title")
            public static let appWelcomeDescription = ResourceManager.localizedString("conversation.ai.welcome.description")
            public static let appName = ResourceManager.localizedString("conversation.ai.app.name")
            public static let agentName = ResourceManager.localizedString("conversation.agent.name")
            public static let buttonEndCall = ResourceManager.localizedString("conversation.button.end.call")
            public static let agentLoading = ResourceManager.localizedString("conversation.agent.loading")
            public static let agentJoined = ResourceManager.localizedString("conversation.agent.joined")
            public static let joinFailed = ResourceManager.localizedString("conversation.join.failed")
            public static let agentLeave = ResourceManager.localizedString("conversation.agent.leave")
            public static let endCallLoading = ResourceManager.localizedString("conversation.end.call.loading")
            public static let endCallLeave = ResourceManager.localizedString("conversation.end.call.leave")
            public static let messageYou = ResourceManager.localizedString("conversation.message.you")
            public static let messageAgentName = ResourceManager.localizedString("conversation.message.agent.name")
            public static let clearMessageTitle = ResourceManager.localizedString("conversation.message.alert.title")
            public static let clearMessageContent = ResourceManager.localizedString("conversation.message.alert.content")
            public static let alertCancel = ResourceManager.localizedString("conversation.alert.cancel")
            public static let alertClear = ResourceManager.localizedString("conversation.alert.clear")
            public static let userSpeakToast = ResourceManager.localizedString("conversation.user.speak.toast")
            public static let agentInterrputed = ResourceManager.localizedString("conversation.agent.interrputed")
        }
        
        public enum Setting {
            public static let title = ResourceManager.localizedString("setting.title")
        }

        public enum Error {
            public static let networkError = ResourceManager.localizedString("error.network")
            public static let roomError = ResourceManager.localizedString("error.room.error")
            public static let joinError = ResourceManager.localizedString("error.join.error")
            public static let resouceLimit = ResourceManager.localizedString("error.join.error.resource.limit")
            public static let networkDisconnected = ResourceManager.localizedString("error.network.disconnect")
            public static let microphonePermissionTitle = ResourceManager.localizedString("error.microphone.permission.alert.title")
            public static let microphonePermissionDescription = ResourceManager.localizedString("error.microphone.permission.alert.description")
            public static let permissionCancel = ResourceManager.localizedString("error.permission.alert.cancel")
            public static let permissionConfirm = ResourceManager.localizedString("error.permission.alert.confirm")
        }

        public enum Settings {
            public static let title = ResourceManager.localizedString("settings.title")
            public static let tips = ResourceManager.localizedString("settings.connected.tips")
            public static let preset = ResourceManager.localizedString("settings.preset")
            public static let advanced = ResourceManager.localizedString("settings.advanced")
            public static let device = ResourceManager.localizedString("settings.device")
            public static let language = ResourceManager.localizedString("settings.language")
            public static let voice = ResourceManager.localizedString("settings.voice")
            public static let model = ResourceManager.localizedString("settings.model")
            public static let microphone = ResourceManager.localizedString("settings.microphone")
            public static let speaker = ResourceManager.localizedString("settings.speaker")
            public static let noiseCancellation = ResourceManager.localizedString("settings.noise.cancellation")
            public static let aiVadNormal = ResourceManager.localizedString("settings.noise.aiVad.nomal")
            public static let aiVadLight = ResourceManager.localizedString("settings.noise.aiVad.highlight")
            public static let bhvs = ResourceManager.localizedString("settings.noise.bhvs")
            public static let forceResponse = ResourceManager.localizedString("settings.noise.forceResponse")
            public static let agentConnected = ResourceManager.localizedString("settings.agent.connected")
            public static let agentDisconnected = ResourceManager.localizedString("settings.agent.disconnected")
        }
        
        public enum ChannelInfo {
            public static let title = ResourceManager.localizedString("channel.info.title")
            public static let subtitle = ResourceManager.localizedString("channel.info.subtitle")
            public static let networkInfoTitle = ResourceManager.localizedString("channel.network.info.title")
            public static let agentStatus = ResourceManager.localizedString("channel.info.agent.status")
            public static let agentId = ResourceManager.localizedString("channel.info.agent.id")
            public static let roomStatus = ResourceManager.localizedString("channel.info.room.status")
            public static let roomId = ResourceManager.localizedString("channel.info.room.id")
            public static let yourId = ResourceManager.localizedString("channel.info.your.id")
            public static let yourNetwork = ResourceManager.localizedString("channel.info.your.network")
            public static let connectedState = ResourceManager.localizedString("channel.connected.state")
            public static let disconnectedState = ResourceManager.localizedString("channel.disconnected.state")
            public static let copyToast = ResourceManager.localizedString("channel.info.copied")
            public static let networkGood = ResourceManager.localizedString("channel.network.good")
            public static let networkPoor = ResourceManager.localizedString("channel.network.poor")
            public static let networkFair = ResourceManager.localizedString("channel.network.fair")
            public static let moreInfo = ResourceManager.localizedString("channel.more.title")
            public static let feedback = ResourceManager.localizedString("channel.more.feedback")
            public static let feedbackLoading = ResourceManager.localizedString("channel.more.feedback.uploading")
            public static let feedbackSuccess = ResourceManager.localizedString("channel.more.feedback.success")
            public static let feedbackFailed = ResourceManager.localizedString("channel.more.feedback.failed")
            public static let logout = ResourceManager.localizedString("channel.more.logout")
            public static let timeLimitdAlertTitle = ResourceManager.localizedString("channel.time.limited.alert.title")
            public static let timeLimitdAlertDescription = ResourceManager.localizedString("channel.time.limited.alert.description")
            public static let timeLimitdAlertConfim = ResourceManager.localizedString("channel.time.limited.alert.confim")
        }
        
        public enum DevMode {
            public static let title = ResourceManager.localizedString("devmode.title")
            public static let graph = ResourceManager.localizedString("devmode.graph")
            public static let rtc = ResourceManager.localizedString("devmode.rtc")
            public static let host = ResourceManager.localizedString("devmode.host")
            public static let dump = ResourceManager.localizedString("devmode.dump")
            public static let copy = ResourceManager.localizedString("devmode.copy")
            public static let close = ResourceManager.localizedString("devmode.close")
            public static let server = ResourceManager.localizedString("devmode.server")
        }

        public enum Iot {
            public static let title = ResourceManager.localizedString("iot.info.title")
            public static let innerTitle = ResourceManager.localizedString("iot.info.inner.title")
            public static let device = ResourceManager.localizedString("iot.info.device")
            public static let submit = ResourceManager.localizedString("iot.common.submit")
            public static let cancel = ResourceManager.localizedString("iot.common.cancel")
            
            // Permissions
            public static let permissionTitle = ResourceManager.localizedString("iot.permission.title")
            public static let permissionDescription = ResourceManager.localizedString("iot.permission.description")
            public static let permissionGoButton = ResourceManager.localizedString("iot.permission.go_button")
            
            // Device Adding Process
            public static let deviceAddTitle = ResourceManager.localizedString("iot.device.add.title")
            public static let deviceAddProgress = ResourceManager.localizedString("iot.device.add.progress")
            public static let deviceAddSuccessTitle = ResourceManager.localizedString("iot.device.add.success.title")
            public static let deviceAddSuccessDescription = ResourceManager.localizedString("iot.device.add.success.description")
            
            // Device Scanning
            public static let deviceScanningTitle = ResourceManager.localizedString("iot.device.scanning.title")
            public static let deviceScanningDescription = ResourceManager.localizedString("iot.device.scanning.description")
            
            // Empty Device Page
            public static let deviceEmptyWelcome = ResourceManager.localizedString("iot.device.empty.welcome")
            public static let deviceEmptyDescription = ResourceManager.localizedString("iot.device.empty.description")
            public static let deviceEmptyAddButton = ResourceManager.localizedString("iot.device.empty.add_button")
            
            // Device Setup
            public static let deviceSetupInstruction = ResourceManager.localizedString("iot.device.setup.instruction")
            public static let deviceSetupInstructionSub = ResourceManager.localizedString("iot.device.setup.instruction.sub")
            public static let deviceSetupPermissionDescription = ResourceManager.localizedString("iot.device.setup.permission_description")
            public static let deviceSetupComplete = ResourceManager.localizedString("iot.device.setup.complete")
            
            // Device Setup Steps
            public static let deviceStep1Title = ResourceManager.localizedString("iot.device.step1.title")
            public static let deviceStep1Description = ResourceManager.localizedString("iot.device.step1.description")
            public static let deviceStep2Title = ResourceManager.localizedString("iot.device.step2.title")
            public static let deviceStep2Description = ResourceManager.localizedString("iot.device.step2.description")
            public static let deviceStep3Title = ResourceManager.localizedString("iot.device.step3.title")
            public static let deviceStep3Description = ResourceManager.localizedString("iot.device.step3.description")
            
            // Others
            public static let deviceDefaultPreset = ResourceManager.localizedString("iot.device.default_preset")
            
            // Permission Items
            public static let permissionItemLocation = ResourceManager.localizedString("iot.permission.item.location")
            public static let permissionItemBluetooth = ResourceManager.localizedString("iot.permission.item.bluetooth")
            public static let permissionItemWifi = ResourceManager.localizedString("iot.permission.item.wifi")
            public static let permissionBluetoothEnable = ResourceManager.localizedString("iot.permission.bluetooth.enable")
            public static let permissionBluetoothUnauthorized = ResourceManager.localizedString("iot.permission.bluetooth.unauthorized")
            public static let permissionLocationUnauthorized = ResourceManager.localizedString("iot.permission.location.unauthorized")
            public static let buttonNext = ResourceManager.localizedString("iot.permission.button.next")
            
            // Device Search Failed
            public static let deviceSearchFailedTitle = ResourceManager.localizedString("iot.device.search.failed.title")
            public static let deviceSearchFailedDescription = ResourceManager.localizedString("iot.device.search.failed.description")
            public static let deviceSearchFailedRetry = ResourceManager.localizedString("iot.device.search.failed.retry")
            public static let deviceSearchFailedTip = ResourceManager.localizedString("iot.device.search.failed.tip")
            
            // Error Alert
            public static let errorAlertTitle = ResourceManager.localizedString("iot.error.alert.title")
            public static let errorAlertSubtitle = ResourceManager.localizedString("iot.error.alert.subtitle")
            public static let errorCheckWifi = ResourceManager.localizedString("iot.error.check.wifi")
            public static let errorCheckPairingMode = ResourceManager.localizedString("iot.error.check.pairing")
            public static let errorCheckRouter = ResourceManager.localizedString("iot.error.check.router")
            
            // Device Settings
            public static let deviceSettingsTitle = ResourceManager.localizedString("iot.device.settings.title")
            public static let deviceSettingsPreset = ResourceManager.localizedString("iot.device.settings.preset")
            public static let deviceSettingsLanguage = ResourceManager.localizedString("iot.device.settings.language")
            public static let deviceSettingsLanguageTitle = ResourceManager.localizedString("iot.device.settings.language.title")
            public static let deviceSettingsLanguageSimplifiedChinese = ResourceManager.localizedString("iot.device.settings.language.simplified_chinese")
            public static let deviceSettingsLanguageEnglish = ResourceManager.localizedString("iot.device.settings.language.english")
            public static let deviceSettingsLanguageJapanese = ResourceManager.localizedString("iot.device.settings.language.japanese")
            public static let deviceSettingsAdvanced = ResourceManager.localizedString("iot.device.settings.advanced")
            public static let deviceSettingsInterrupt = ResourceManager.localizedString("iot.device.settings.interrupt")
            public static let deviceSettingsReconnect = ResourceManager.localizedString("iot.device.settings.reconnect")
            public static let deviceSettingsDelete = ResourceManager.localizedString("iot.device.settings.delete")
            public static let deviceSettingsDeleteTitle = ResourceManager.localizedString("iot.device.settings.delete.title")
            public static let deviceSettingsDeleteDescription = ResourceManager.localizedString("iot.device.settings.delete.description")
            public static let deviceSettingsDeleteConfirm = ResourceManager.localizedString("iot.device.settings.delete.confirm")
            public static let deviceSettingsSaveTitle = ResourceManager.localizedString("iot.device.settings.save.title")
            public static let deviceSettingsSaveDescription = ResourceManager.localizedString("iot.device.settings.save.description")
            public static let deviceSettingsSaveConfirm = ResourceManager.localizedString("iot.device.settings.save.confirm")
            public static let deviceSettingsSaveDiscard = ResourceManager.localizedString("iot.device.settings.save.discard")
            public static let deviceRename = ResourceManager.localizedString("iot.device.rename.title")
            public static let deviceRenameSucceed = ResourceManager.localizedString("iot.device.rename.success")
            
            // WiFi Settings
            public static let wifiSettingsTitle = ResourceManager.localizedString("iot.wifi.settings.title")
            public static let wifiSettingsSubtitle = ResourceManager.localizedString("iot.wifi.settings.subtitle")
            public static let wifiSettingsTip = ResourceManager.localizedString("iot.wifi.settings.tip")
            public static let wifiSettingsError = ResourceManager.localizedString("iot.wifi.settings.error")
            public static let wifiSettingsPasswordPlaceholder = ResourceManager.localizedString("iot.wifi.settings.password.placeholder")
            public static let wifiSettingsSwitch = ResourceManager.localizedString("iot.wifi.settings.switch")
            public static let wifiSettingsNext = ResourceManager.localizedString("iot.wifi.settings.next")
            
            // Device Search
            public static let deviceSearchTitle = ResourceManager.localizedString("iot.device.search.title")
            public static let deviceSearchNoResult = ResourceManager.localizedString("iot.device.search.no_result")
            public static let deviceSearchScanning = ResourceManager.localizedString("iot.device.search.scanning")
            public static let deviceSearchRetry = ResourceManager.localizedString("iot.device.search.retry")
            public static let deviceSearchTip = ResourceManager.localizedString("iot.device.search.tip")
            public static let deviceSearchConnect = ResourceManager.localizedString("iot.device.search.connect")
            
            // Device Search Status
            public static let deviceSearchStatusReady = ResourceManager.localizedString("iot.device.search.status.ready")
            public static let deviceSearchStatusConnected = ResourceManager.localizedString("iot.device.search.status.connected")
            public static let deviceSearchStatusConfiguring = ResourceManager.localizedString("iot.device.search.status.configuring")
            public static let deviceSearchStatusCompleted = ResourceManager.localizedString("iot.device.search.status.completed")
        }
    }
}


