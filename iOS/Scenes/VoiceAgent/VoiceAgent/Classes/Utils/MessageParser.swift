import Foundation

struct TranscriptionMessage: Codable {
    let is_final: Bool
    let data_type: String
    let stream_id: Int
    let text: String
    let message_id: String
    let quiet: Bool
    let object: String
    let turn_id: Int
    let turn_seq_id: Int
    let turn_status: Int
    let language: String?
    let user_id: String?
    let words: [Word]?
}

struct Word: Codable {
    let duration_ms: Int
    let stable: Bool
    let start_ms: Int
    let word: String
}

class MessageParser {
    
    private var messageBuffer: [String: [String]] = [:]
    private var lastAccessTime: [String: Date] = [:]
    private let maxMessageAge: TimeInterval = 5 * 60 // 5 minutes
    
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
    
    func parse(_ data: Data) -> TranscriptionMessage? {
        guard let rawMessage = String(data: data, encoding: .utf8) else {
            print("Failed to parse data to string")
            return nil
        }
        cleanExpiredMessages()
        let components = rawMessage.split(separator: "|")
        guard components.count == 4 else {
            print("[MessageParser] Invalid message format")
            return nil
        }
        
        let messageId = String(components[0])
        guard let partIndex = Int(components[1]),
              let totalParts = Int(components[2]),
              let base64Content = String(components[3]).base64Decoded else {
            print("[MessageParser] Failed to parse message components")
            return nil
        }
        
        if partIndex < 1 || partIndex > totalParts {
            print("[MessageParser] partIndex out of range")
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
            // parse full content to model
            guard let jsonData = fullContent.data(using: .utf8) else {
                print("[MessageParser] Failed to parse fullContent to data")
                return nil
            }
            do {
                let transcription = try JSONDecoder().decode(TranscriptionMessage.self, from: jsonData)
                return transcription
            } catch {
                print("[MessageParser] Failed to parse JSON content: \(fullContent), error: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }
}

extension String {
    fileprivate var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
