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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        copyResource()
        
        SVProgressHUD.setMaximumDismissTimeInterval(2)
        SVProgressHUD.setBackgroundColor(UIColor.themColor(named: "ai_fill1").withAlphaComponent(0.8))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setImageViewSize(CGSize.zero)
        SVProgressHUD.setOffsetFromCenter(UIOffset(horizontal: 0, vertical: 180)) 

        #if MainLand
        AppContext.shared.appArea = .mainland
        #else
        AppContext.shared.appArea = .overseas
        #endif

        AppContext.shared.appId = KeyCenter.AppId
        AppContext.shared.certificate = KeyCenter.Certificate ?? ""
        AppContext.shared.baseServerUrl = KeyCenter.BaseHostUrl
        AppContext.shared.termsOfServiceUrl = KeyCenter.TermsOfService
        AppContext.shared.environments = KeyCenter.environments
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
                AgentLogger.info("[Resource] Failed to create directory: \(error)")
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
                AgentLogger.info("[Resource] Successfully unzipped common_resource to: \(destinationPath)")
            } else {
                AgentLogger.info("[Resource] Failed to unzip file")
            }
        } catch {
            AgentLogger.info("[Resource] Error during unzip: \(error)")
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

