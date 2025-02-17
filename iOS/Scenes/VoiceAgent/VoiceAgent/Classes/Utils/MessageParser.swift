import Foundation

class MessageParser {
    private var messageBuffer: [String: [String]] = [:]
    private var lastAccessTime: [String: Date] = [:]
    private let maxMessageAge: TimeInterval = 5 * 60 // 5 minutes

    func parseMessage(_ rawMessage: String) -> [String: Any]? {
        cleanExpiredMessages()
        
        let components = rawMessage.split(separator: "|")
        guard components.count == 4 else {
            print("Invalid message format")
            return nil
        }
        
        let messageId = String(components[0])
        guard let partIndex = Int(components[1]),
              let totalParts = Int(components[2]),
              let base64Content = String(components[3]).base64Decoded else {
            print("Failed to parse message components")
            return nil
        }
        
        if partIndex < 1 || partIndex > totalParts {
            print("partIndex out of range")
            return nil
        }
        
        lastAccessTime[messageId] = Date()
        
        if messageBuffer[messageId] == nil {
            messageBuffer[messageId] = Array(repeating: "", count: totalParts)
        }
        
        messageBuffer[messageId]?[partIndex - 1] = base64Content
        
        if let parts = messageBuffer[messageId], parts.contains("") == false {
            let fullContent = parts.joined()
            messageBuffer.removeValue(forKey: messageId)
            lastAccessTime.removeValue(forKey: messageId)
            return parseJsonContent(fullContent)
        }
        
        return nil
    }
    
    private func cleanExpiredMessages() {
        let currentTime = Date()
        var keysToRemove: [String] = []
        for (messageId, accessTime) in lastAccessTime {
            if currentTime.timeIntervalSince(accessTime) > maxMessageAge {
                keysToRemove.append(messageId)
            }
        }
        for key in keysToRemove {
            messageBuffer.removeValue(forKey: key)
            lastAccessTime.removeValue(forKey: key)
        }
    }
    
    private func parseJsonContent(_ content: String) -> [String: Any]? {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("Failed to parse JSON content: \(content)")
            return nil
        }
        return json
    }
}

extension String {
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
