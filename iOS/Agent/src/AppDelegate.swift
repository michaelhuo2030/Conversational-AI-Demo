//
//  AppDelegate.swift
//  Agent
//
//  Created by Jonathan on 2024/9/29.
//

import UIKit
import Common
import SVProgressHUD
import VoiceAgent
import SSZipArchive

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    private func loadEnvironmentConfig() {
        guard let path = Bundle.main.path(forResource: "env", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return
        }
        
        AppContext.shared.appId = dict["app_id"] as? String ?? ""
        AppContext.shared.certificate = dict["app_cert"] as? String ?? ""
        AppContext.shared.basicAuthKey = dict["basic_auth_key"] as? String ?? ""
        AppContext.shared.basicAuthSecret = dict["basic_auth_secret"] as? String ?? ""
        AppContext.shared.llmUrl = dict["llm_url"] as? String ?? ""
        AppContext.shared.llmApiKey = dict["llm_api_key"] as? String ?? ""
        AppContext.shared.llmSystemMessages = dict["llm_system_messages"] as? String ?? ""
        AppContext.shared.llmModel = dict["llm_model"] as? String ?? ""
        AppContext.shared.ttsVendor = dict["tts_vendor"] as? String ?? ""
        AppContext.shared.ttsParams = dict["tts_params"] as? [String: Any] ?? [:]
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
#if MainLand
        AppContext.shared.appArea = .mainland
#else
        AppContext.shared.appArea = .global
#endif
        
        loadEnvironmentConfig()
        
        if AppContext.shared.appId.isEmpty {
            AppContext.shared.appId = KeyCenter.AppId
        }
        if AppContext.shared.certificate.isEmpty {
            AppContext.shared.certificate = KeyCenter.Certificate ?? ""
        }
        if AppContext.shared.baseServerUrl.isEmpty {
            AppContext.shared.baseServerUrl = KeyCenter.BaseHostUrl
        }
        
        if AppContext.shared.appId.isEmpty {
            AppContext.shared.loadInnerEnvironment()
        }
                
        copyResource()
        
        SVProgressHUD.setMaximumDismissTimeInterval(2)
        SVProgressHUD.setBackgroundColor(UIColor.themColor(named: "ai_fill1").withAlphaComponent(0.8))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setImageViewSize(CGSize.zero)
        
        return true
    }
    
    func copyResource() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        
        let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let destinationPath = (cachesPath as NSString).appendingPathComponent(bundleId)
        
        if !FileManager.default.fileExists(atPath: destinationPath) {
            do {
                try FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)
            } catch {
                VoiceAgentLogger.info("[Resource] Failed to create directory: \(error)")
                return
            }
        }
        
        guard let zipPath = Bundle.main.path(forResource: "common_resource", ofType: "zip") else {
            print("[Resource] common_resource.zip not found in bundle")
            return
        }
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationPath) {
                let contents = try fileManager.contentsOfDirectory(atPath: destinationPath)
                for file in contents {
                    let filePath = (destinationPath as NSString).appendingPathComponent(file)
                    try fileManager.removeItem(atPath: filePath)
                }
            }
            
            let success = SSZipArchive.unzipFile(atPath: zipPath, toDestination: destinationPath)
            
            if success {
                VoiceAgentLogger.info("[Resource] Successfully unzipped common_resource to: \(destinationPath)")
            } else {
                VoiceAgentLogger.info("[Resource] Failed to unzip file")
            }
        } catch {
            VoiceAgentLogger.info("[Resource] Error during unzip: \(error)")
        }
    }
    

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

