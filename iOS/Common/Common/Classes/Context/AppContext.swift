//
//  AppContext.swift
//  AgoraEntScenarios
//
//  Created by wushengtao on 2022/10/18.
//

import Foundation

@objc public enum AppArea: Int {
    case global = 0
    case mainland = 1
}

@objc public class AppContext: NSObject {
    @objc public static let shared: AppContext = .init()
    
    public let termsOfServiceUrl: String = "https://www.agora.io/en/terms-of-service/"
    
    private var _appId: String = ""
    private var _certificate: String = ""
    private var _baseServerUrl: String = ""
    private var _appArea: AppArea = .global
    private var _environments: [[String : String]] = []
    private var _graphId: String = ""
    
    override init() {
        super.init()
    }

    @objc public var appArea: AppArea {
        get {
            return _appArea
        }
        set {
            _appArea = newValue
        }
    }
    
    @objc public var appId: String {
        get {
            return _appId
        }
        set {
            _appId = newValue
        }
    }
    
    @objc public var certificate: String {
        get {
            return _certificate
        }
        set {
            _certificate = newValue
        }
    }
    
    @objc public var baseServerUrl: String {
        get {
            return _baseServerUrl
        }
        set {
            _baseServerUrl = newValue
        }
    }
    
    @objc public var environments: [[String : String]] {
        get {
            return _environments
        }
    }
    
    public func loadEnvironment() {
        if let bundlePath = Bundle.main.path(forResource: "Common", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath),
           let environmentsPath = bundle.path(forResource: "environments", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: environmentsPath)),
           let environments = try? JSONDecoder().decode([String: [[String: String]]].self, from: data) {
            if (AppContext.shared.appArea == .mainland) {
                _environments = environments["cn"] ?? []
            } else {
                _environments = environments["global"] ?? []
            }
            if (appId.isEmpty) {
                _appId = _environments.first?["appId"] ?? ""
                _certificate = _environments.first?["certificate"] ?? ""
                _baseServerUrl = _environments.first?["host"] ?? ""
            }
        }
    }
    
    @objc public var graphId: String {
        get {
            return _graphId
        }
        
        set {
            _graphId = newValue
        }
    }
}
