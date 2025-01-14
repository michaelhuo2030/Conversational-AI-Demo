//
//  MessageParser.swift
//  VoiceAgent
//
//  Created by qinhui on 2024/12/25.
//

import Foundation

extension String {
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Message Parser
class MessageParser {
    private var messageBuffer: [String: [String]] = [:]
    
    func parseMessage(_ rawMessage: String) -> [String: Any]? {
        // Check message format: messageId|partIndex|totalParts|base64Content
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
        
        // If it's a single part message, parse directly
        if totalParts == 1 {
            return parseJsonContent(base64Content)
        }
        
        // Handle multi-part message
        if messageBuffer[messageId] == nil {
            messageBuffer[messageId] = Array(repeating: "", count: totalParts)
        }
        
        // Store current part
        messageBuffer[messageId]?[partIndex - 1] = base64Content
        
        // Check if all parts are received
        if let parts = messageBuffer[messageId],
           !parts.contains("") {
            // Combine all parts
            let fullContent = parts.joined()
            // Clean up buffer
            messageBuffer.removeValue(forKey: messageId)
            // Parse complete message
            return parseJsonContent(fullContent)
        }
        
        return nil
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
