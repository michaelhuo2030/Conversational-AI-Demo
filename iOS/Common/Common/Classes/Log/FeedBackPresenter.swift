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
    
    private var images = [UIImage]()
    private var imageUrls: [String]?
    
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
            let req = AUIUploadNetworkModel()
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
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AgentLogs")
        do {
            // delete exist files
            try FileManager.default.removeItem(at: tempDirectory)
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            for fileURL in fileURLs {
                let destinationFileURL = tempDirectory.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.copyItem(at: fileURL, to: destinationFileURL)
            }
            try FileManager.default.removeItem(at: destinationURL)
            
            let success = SSZipArchive.createZipFile(atPath: destinationURL.path,
                                                     withContentsOfDirectory: tempDirectory.path)
            if success {
                completion(nil, destinationURL)
            } else {
                completion(FeedbackError(code: -1, message: "zip log error"), nil)
            }
        } catch {
            completion(FeedbackError(code: -1, message: "zip log error"), nil)
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
