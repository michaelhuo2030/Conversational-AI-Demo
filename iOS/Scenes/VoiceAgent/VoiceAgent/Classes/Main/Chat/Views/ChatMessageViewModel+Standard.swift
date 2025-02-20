//
//  ChatMessageViewModel+Standard.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/19.
//

import Foundation

protocol MessageStandard {
    func reduceStandardMessage(turnId: String, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool)
}

extension ChatMessageViewModel: MessageStandard {
    private func generateMessageKey(turnId: String, isMine: Bool) -> String {
        let key = isMine ? "agent_\(turnId)" : "mine_\(turnId)"
        return key
    }
    
    func reduceStandardMessage(turnId: String, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool) {
        let isMine = owner == .me
        let key = generateMessageKey(turnId: turnId, isMine: isMine)
        let messageObj = messageMapTable[key]

        if messageObj != nil {
            updateContent(content: message, turnId: turnId, isFinished: isFinished, isMine: isMine)
        } else {
            startNewMessage(content: message, timestamp: timestamp, isMine: isMine, turnId: turnId)
        }
    }
    
    private func startNewMessage(content: String, timestamp: Int64, isMine: Bool, turnId: String) {
        let message = Message()
        message.content = content
        message.isMine = isMine
        message.isFinal = false
        message.turn_id = turnId
        
        let key = generateMessageKey(turnId: turnId, isMine: isMine)
        messageMapTable[key] = message
        messages.append(message)
//        messages.sort { $0.timestamp < $1.timestamp }
        
        delegate?.startNewMessage()
    }
    
    private func updateContent(content: String, turnId: String, isFinished: Bool, isMine: Bool) {
        let key = generateMessageKey(turnId: turnId, isMine: isMine)
        let message = messageMapTable[key]
        message?.content = content
        message?.isFinal = isFinished
        message?.turn_id = key
        
        delegate?.messageUpdated()
    }
}
