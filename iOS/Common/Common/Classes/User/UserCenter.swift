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
    
    private init() {}
    
    public class var user: LoginModel? {
        return shared.getUserFromDefaults()
    }
    
    private func getUserFromDefaults() -> LoginModel? {
        guard let jsonString = UserDefaults.standard.string(forKey: UserCenter.kLocalLoginKey),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        return try? JSONDecoder().decode(LoginModel.self, from: data)
    }
    
    public func isLogin() -> Bool {
        return getUserFromDefaults() != nil
    }
    
    public func storeUserInfo(_ user: LoginModel) {
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
        UserDefaults.standard.removeObject(forKey: UserCenter.kLocalLoginKey)
        UserDefaults.standard.synchronize()
    }
}
