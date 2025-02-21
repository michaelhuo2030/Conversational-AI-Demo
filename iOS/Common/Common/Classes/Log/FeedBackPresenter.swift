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

public typealias FeedbackCompletion = (FeedbackError?, [String : Any]?) -> Void

public class FeedBackPresenter {
    
    private let kURLPathUploadImage = "/api-login/upload"
    private let kURLPathUploadLog = "/api-login/upload/log"
    private let kURLPathFeedback = "/api-login/feedback/upload"
    
    private var images = [UIImage]()
    private var imageUrls: [String]?
    
    public init() {
    }
    
    public func feedback(isSendLog: Bool, title: String, feedback: String = "", completion: @escaping FeedbackCompletion) {
        var logUrl: String? = nil
        let group = DispatchGroup()
        if isSendLog {
            group.enter()
            zipAndSendLog(fileName: title, completion: { error, url in
                logUrl = url
                group.leave()
            })
        }
        group.notify(queue: .main) {
            guard logUrl != nil else {
                completion(FeedbackError(code: -1, message: "zip log error"), nil)
                return
            }
            self.submitFeedbackData(feedback: feedback, imageUrls: self.imageUrls, logUrl: logUrl) { errot, result in
                completion(errot, result)
            }
        }
    }
    
    private func zipFiles(fileURLs: [URL], destinationURL: URL, completion: @escaping (FeedbackError?, URL?) -> Void) {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AgentLogs")
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            for fileURL in fileURLs {
                let destinationFileURL = tempDirectory.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.copyItem(at: fileURL, to: destinationFileURL)
            }
            try? FileManager.default.removeItem(at: destinationURL)
            
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
    
    private func submitFeedbackData(feedback: String, imageUrls: [String]?, logUrl: String?, completion: @escaping FeedbackCompletion) {
        var images: [String: String] = [:]
        imageUrls?.enumerated().forEach({
            images["\($0.offset + 1)"] = $0.element
        })
        
        let url = AppContext.shared.baseServerUrl + kURLPathFeedback
        let parameters = ["screenshotURLs": images,
                          "tags": [],
                          "description": feedback,
                          "logURL": logUrl ?? ""] as [String : Any]
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = FeedbackError(code: code, message: msg)
                completion(error, nil)
            } else {
                completion(nil, result)
            }
        } failure: { msg in
            let error = FeedbackError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    private func zipAndSendLog(fileName: String, completion: @escaping (FeedbackError?, String?) -> Void) {
        var fileURLs = [URL]()
        fileURLs.append(contentsOf: AgoraEntLog.allLogsUrls())
        fileURLs.append(contentsOf: getAgoraFiles())
        let fileName = "/\(fileName).zip"
        let tempFile = NSTemporaryDirectory() + fileName
        zipFiles(fileURLs: fileURLs, destinationURL: URL(fileURLWithPath: tempFile)) { err, url in
            if let err = err {
                completion(err, nil)
                return
            }
            guard let url = url, let data = try? Data.init(contentsOf: url) else {
                return
            }
            let req = AUIUploadNetworkModel()
            req.interfaceName = self.kURLPathUploadLog
            req.fileData = data
            req.name = "file"
            req.mimeType = "application/zip"
            req.fileName = fileName
            req.upload { progress in
                
            } completion: { err, content in
                var logUrl: String? = nil
                if let content = content as? [String: Any], let data = content["data"] as? [String: Any], let url = data["url"] as? String {
                    logUrl = url
                }
                completion(FeedbackError(code: -1, message: "upload log error"), logUrl)
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
                ($0.lastPathComponent.hasPrefix("aec_farin")) ||
                ($0.lastPathComponent.hasPrefix("aec_linear")) ||
                ($0.lastPathComponent.hasPrefix("aec_nearin")) ||
                ($0.lastPathComponent.hasPrefix("af_ns")) ||
                ($0.lastPathComponent.hasPrefix("af_sfnlp"))
            }
            return agoraFiles
        } catch {
            return []
        }
    }
}
