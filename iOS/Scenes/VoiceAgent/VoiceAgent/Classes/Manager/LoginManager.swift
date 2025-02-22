//
//  LoginManager.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/22.
//

import Foundation
import Common

protocol LoginManagerDelegate: AnyObject {
    func loginManager(_ manager: LoginManager, userInfoDidChange userInfo: LoginModel?, loginState: Bool)
}

protocol LoginManagerProtocol {
    func addDelegate(_ delegate: LoginManagerDelegate)
    func removeDelegate(_ delegate: LoginManagerDelegate)
    func updateUserInfo(userInfo: LoginModel)
    func logout()
}

class LoginManager {
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    private func notifyDelegates(_ notification: (LoginManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? LoginManagerDelegate {
                notification(delegate)
            }
        }
    }
}

extension LoginManager: LoginManagerProtocol {
    func addDelegate(_ delegate: LoginManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: LoginManagerDelegate) {
        delegates.remove(delegate)
    }
    
    func updateUserInfo(userInfo: LoginModel) {
        UserCenter.shared.storeUserInfo(userInfo)
        let loginState = UserCenter.shared.isLogin()
        notifyDelegates { $0.loginManager(self, userInfoDidChange: userInfo, loginState: loginState)}
    }
    
    func logout() {
        UserCenter.shared.logout()
        let loginState = UserCenter.shared.isLogin()
        notifyDelegates { $0.loginManager(self, userInfoDidChange: nil, loginState: loginState)}
    }
}

