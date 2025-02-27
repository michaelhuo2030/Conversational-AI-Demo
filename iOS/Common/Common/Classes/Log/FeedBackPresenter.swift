//
//  VLFeedbackViewController.swift
//  AgoraEntScenarios
//
//  Created by zhaoyongqiang on 2023/10/18.
//

import UIKit
import SSZipArchive

public struct FeedbackError: Error {
    public var code: Int
    public var message: String
}

public typealias FeedbackCompletion = (FeedbackError?, String?) -> Void

public class FeedBackPresenter {
    
    private let kURLPathUploadLog = "/v1/convoai/upload/log"
    
    public init() {
    }
    
    public func feedback(isSendLog: Bool, channel: String, agentId: String?, feedback: String = "", completion: @escaping FeedbackCompletion) {
        var fileName = channel
        if let agentId = agentId {
            let processedAgentId = agentId.split(separator: ":").first.map(String.init) ?? ""
            fileName = "\(processedAgentId)_\(channel)"
        }
        var fileURLs = [URL]()
        fileURLs.append(contentsOf: AgoraEntLog.allLogsUrls())
        fileURLs.append(contentsOf: getAgoraFiles())
        let tempFile = NSTemporaryDirectory() + "/\(fileName).zip"
        zipFiles(fileURLs: fileURLs, destinationURL: URL(fileURLWithPath: tempFile)) { err, url in
            if let err = err {
                completion(err, nil)
                return
            }
            guard let url = url, let data = try? Data.init(contentsOf: url) else {
                return
            }
            let req = FeedbackNetworkModel()
            req.fileName = fileName
            req.interfaceName = self.kURLPathUploadLog
            req.fileData = data
            req.appId = AppContext.shared.appId
            req.channelName = channel
            req.agentId = agentId ?? ""
            req.upload { progress in
                print("upload log progress: \(progress)")
            } completion: { err, content in
                if let content = content as? [String: Any], let code = content["code"] as? Int, code == 0 {
                    completion(nil, "upload log success")
                } else {
                    completion(FeedbackError(code: -1, message: "upload log error"), nil)
                }
            }
        }
    }
    
    private func zipFiles(fileURLs: [URL], destinationURL: URL, completion: @escaping (FeedbackError?, URL?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AgentLogs")
            // delete exist files
            try? FileManager.default.removeItem(at: tempDirectory)
            do {
                try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
                
                for fileURL in fileURLs {
                    let destinationFileURL = tempDirectory.appendingPathComponent(fileURL.lastPathComponent)
                    try FileManager.default.copyItem(at: fileURL, to: destinationFileURL)
                }
                try? FileManager.default.removeItem(at: destinationURL)
                
                let success = SSZipArchive.createZipFile(atPath: destinationURL.path,
                                                         withContentsOfDirectory: tempDirectory.path)
                DispatchQueue.main.async {
                    if success {
                        completion(nil, destinationURL)
                    } else {
                        completion(FeedbackError(code: -1, message: "zip log error"), nil)
                    }
                }
            } catch let err {
                DispatchQueue.main.async {
                    completion(FeedbackError(code: -1, message: err.localizedDescription), nil)
                }
            }
        }
    }
    
    private func getAgoraFiles() -> [URL] {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let agoraFiles = files.filter {
                ($0.lastPathComponent.hasPrefix("agora")) ||
                ($0.lastPathComponent.contains("predump"))
            }
            return agoraFiles
        } catch {
            return []
        }
    }
}

class FeedbackNetworkModel: AUIUploadNetworkModel {
    public var appId: String?
    public var channelName: String?
    public var fileName: String?
    public var agentId: String?
    public var payload: [String: Any] = [String: Any]()
    public var fileData: Data?
    
    public override func multipartData() -> Data {
        var data = Data()
        guard let appId = appId, let channelName = channelName, let agentId = agentId, let fileData = fileData, let fileName = fileName else {
            return data
        }
        let contentDict: [String: Any] = [
            "appId": appId,
            "channelName": channelName,
            "agentId": agentId,
            "payload": payload
        ]
        print("upload log with \(contentDict)" )
        guard let contentData = try? JSONSerialization.data(withJSONObject: contentDict) else {
            return data
        }
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
        data.append(contentData)
        data.append("\r\n".data(using: .utf8)!)
        // add part of file
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName).zip\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        
        // add end sign
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}
