//
//  UserCenter.swift
//  Common-Common
//
//  Created by qinhui on 2025/2/21.
//

import Foundation

public class LoginModel: Codable {
    public var token: String = ""
    public var uid: String = ""
    
    public init() {
        self.token = ""
        self.uid = ""
    }
}

public class UserCenter {
    private static let kLocalLoginKey = "kLocalLoginKey"
    
    public static let shared = UserCenter()
    public static var center: UserCenter { return shared }
    
    private var loginModel: LoginModel?
    
    private init() {}
    
    public class var user: LoginModel? {
        return UserCenter.shared.loginModel
    }
    
    public func isLogin() -> Bool {
        if loginModel == nil {
            if let jsonString = UserDefaults.standard.string(forKey: UserCenter.kLocalLoginKey),
               let data = jsonString.data(using: .utf8) {
                loginModel = try? JSONDecoder().decode(LoginModel.self, from: data)
            }
        }
        return loginModel != nil
    }
    
    public func storeUserInfo(_ user: LoginModel) {
        loginModel = user
        if let data = try? JSONEncoder().encode(user),
           let jsonString = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: UserCenter.kLocalLoginKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func logout() {
        cleanUserInfo()
    }
    
    private func cleanUserInfo() {
        loginModel = nil
        UserDefaults.standard.removeObject(forKey: UserCenter.kLocalLoginKey)
    }
    
}
