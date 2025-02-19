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
    func reduceStandardMessage(turnId: String, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool) {
        let messageObj = messageMapTable[turnId]
        if messageObj != nil {
            updateContent(content: message, turnId: turnId, isFinished: isFinished)
        } else {
            let isMine = owner == .me
            startNewMessage(timestamp: timestamp, isMine: isMine, turnId: turnId)
        }
    }
    
    private func startNewMessage(timestamp: Int64, isMine: Bool, turnId: String) {
        let message = Message(
            content: "",
            isMine: isMine,
            isFinal: false,
            timestamp: timestamp,
            turn_id: turnId)
        messageMapTable[turnId] = message
        messages.append(message)
        messages.sort { $0.timestamp < $1.timestamp }
        
        delegate?.startNewMessage()
    }
    
    private func updateContent(content: String, turnId: String, isFinished: Bool) {
        var message = messageMapTable[turnId]
        message?.content = content
        message?.isFinal = isFinished
        delegate?.messageUpdated()
    }
}
