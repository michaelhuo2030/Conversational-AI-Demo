//
//  VLFeedbackViewController.swift
//  AgoraEntScenarios
//
//  Created by zhaoyongqiang on 2023/10/18.
//

import UIKit
import Zip

struct UploadLogError: Error {
    let code: Int
    let message: String
}

public class LogUploadPresenter {
    
    let kURLPathUploadImage = "/api-login/upload"
    let kURLPathUploadLog = "/api-login/upload/log"
    let kURLPathFeedback = "/api-login/feedback/upload"
    
    private var isUpLoadLog = false
    private var logUrl: String?
    private var images = [UIImage]()
    private var imageUrls: [String]?
    private var feedbackString: String = ""
    
    func zipFiles(fileURLs: [URL], destinationURL: URL, completion: @escaping (URL?, Error?) -> Void) {
        // 创建一个唯一的临时文件夹路径
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        do {
            // 创建临时文件夹
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // 将文件复制到临时文件夹中
            for fileURL in fileURLs {
                let destinationFileURL = tempDirectory.appendingPathComponent(fileURL.lastPathComponent)
                try FileManager.default.copyItem(at: fileURL, to: destinationFileURL)
            }
            
            // 创建 zip 文件的路径
            try? FileManager.default.removeItem(at: destinationURL)
            
            // 使用 Zip 库进行压缩
            try Zip.zipFiles(paths: [tempDirectory], zipFilePath: destinationURL, password: nil, progress: nil)
            
            // 压缩成功，回调完成闭包，并传递 zip 文件的 URL
            completion(destinationURL, nil)
        } catch {
            // 异常处理，回调错误闭包
            completion(nil, error)
        }
    }
    
    private func onClickSubmitButton() {
        let group = DispatchGroup()
        
        group.enter()
        if isUpLoadLog {
            uploadLogHandler(completion: { url, error in
                self.logUrl = url
                group.leave()
            })
        } else {
            group.leave()
        }
        group.notify(queue: .main) {
            self.submitFeedbackData(imageUrls: self.imageUrls, logUrl: self.logUrl) { errot, result in
                
            }
        }
    }
    
    private func submitFeedbackData(imageUrls: [String]?, logUrl: String?, completion: @escaping ((UploadLogError?, [String : Any]?) -> Void)) {
        var images: [String: String] = [:]
        imageUrls?.enumerated().forEach({
            images["\($0.offset + 1)"] = $0.element
        })
        
        let url = AppContext.shared.baseServerUrl + kURLPathFeedback
        let parameters = ["screenshotURLs": images,
                      "tags": [],
                      "description": feedbackString,
                      "logURL": logUrl ?? ""] as [String : Any]
        NetworkManager.shared.postRequest(urlString: url, params: parameters) { result in
            if let code = result["code"] as? Int, code != 0 {
                let msg = result["msg"] as? String ?? "Unknown error"
                let error = UploadLogError(code: code, message: msg)
                completion(error, nil)
            } else {
                completion(nil, result)
            }
        } failure: { msg in
            let error = UploadLogError(code: -1, message: msg)
            completion(error, nil)
        }
    }
    
    private func uploadLogHandler(completion: @escaping (String?, Error?) -> Void) {
        let paths = AgoraEntLog.allLogsUrls()
        let fileName = "/log_\(UUID().uuidString).zip"
        let tempFile = NSTemporaryDirectory() + fileName
        zipFiles(fileURLs: paths, destinationURL: URL(fileURLWithPath: tempFile)) { url, err in
            if let err = err {
                completion(nil, err)
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
                completion(logUrl, err)
            }
        }
    }
}
