//
//  AUINetworkModel.swift
//  AUIKit
//
//  Created by wushengtao on 2023/3/13.
//

import Foundation

public enum AUINetworkMethod: Int {
    case get = 0
    case post
    
    func getAfMethod() -> String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}

@objcMembers
open class AUINetworkModel: NSObject {
    public var uniqueId: String = UUID().uuidString
    public var host: String = AppContext.shared.baseServerUrl
    public var interfaceName: String?
    public var method: AUINetworkMethod = .post
    
    open func requestParameters() -> [String: Any]? {
        return nil
    }
    
    open func getHeaders() -> [String: String] {
        return ["Content-Type": "application/json"]
    }
    
    public func getParameters() -> [String: Any]? {
        return self.requestParameters()
    }
    
    public func getHttpBody() -> Data? {
        guard let parameters = self.requestParameters() else {
            return nil
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            return jsonData
        } catch {
            print("Failed to serialize HTTP body: \(error)")
            return nil
        }
    }
    
    public func request(completion: ((Error?, Any?)->())?) {
        AUINetworking.shared.request(model: self, completion: completion)
    }
    
    open func parse(data: Data?) throws -> Any?  {
        guard let data = data,
              let dic = try? JSONSerialization.jsonObject(with: data) else {
            throw AUICommonError.networkParseFail.toNSError()
        }
        
        if let dic = (dic as? [String: Any]), let code = dic["code"] as? Int, code != 0 {
            let message = dic["message"] as? String ?? ""
            if code == 401 {
                self.tokenExpired()
            }
            throw AUICommonError.httpError(code, message).toNSError()
        }
        
        return dic
    }
    
    open func tokenExpired() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .TokenExpired, object: nil)
        }
    }
    
    public func createBasicAuth(key: String, password: String) -> String {
        let loginString = String(format: "%@:%@", key, password)
        guard let loginData = loginString.data(using: String.Encoding.utf8) else {
            return ""
        }
        let base64LoginString = loginData.base64EncodedString()
        return base64LoginString
    }
}


@objcMembers
open class AUIUploadNetworkModel: AUINetworkModel {
    
    public lazy var  boundary: String = {
        UUID().uuidString
    }()
    
    public override func getHeaders() -> [String: String] {
        var headers = super.getHeaders()
        let contentType = "multipart/form-data; boundary=\(boundary)"
        headers["Content-Type"] = contentType
        headers["Authorization"] = "Bearer \(UserCenter.user?.token ?? "")"
        return headers
    }
    
    open func multipartData() -> Data {
        var data = Data()
        return data
    }
    
    public func upload(progress:((Float) -> Void)? = nil ,completion: ((Error?, Any?)->())?) {
        AUINetworking.shared.upload(model: self, progress: progress, completion: completion)
    }
}
