//
//  ChatMessageViewModel+Independent.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/19.
//

import Foundation

protocol MessageIndependent {
    func reduceIndependentMessage(message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool)
}

extension ChatMessageViewModel: MessageIndependent {
    func reduceIndependentMessage(message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool) {
        if owner == .agent {
            // AI response message
            if isLastMessageFromUser() || isEmpty() || lastMessgeIsFinal() {
                startNewMessage(timestamp: timestamp, isUser: false)
            }
            
            updateContent(content: message)
            if isFinished {
                messageCompleted()
            }
        } else {
            // User message
            if !isLastMessageFromUser() || isEmpty() || lastMessgeIsFinal() {
                startNewMessage(timestamp: timestamp, isUser: true)
            }
            
            updateContent(content: message)
            if isFinished {
                messageCompleted()
            }
        }
    }
    
    private func isEmpty() -> Bool {
        return messages.isEmpty
    }
    
    private func isLastMessageFromUser() -> Bool {
        return messages.last?.isUser == true
    }
    
    private func lastMessgeIsFinal() -> Bool {
        return messages.last?.isFinal == true
    }
    
    private func startNewMessage(timestamp: Int64, isUser: Bool) {
        currentStreamMessage = ""
        messages.append(Message(content: "",
                              isUser: isUser,
                              isFinal: false,
                              timestamp: timestamp))
        messages.sort { $0.timestamp < $1.timestamp }
        
        delegate?.startNewMessage()
    }
    
    private func updateContent(content: String) {
        currentStreamMessage = content
        if var lastMessage = messages.last, !lastMessage.isFinal {
            lastMessage.content = currentStreamMessage
            messages[messages.count - 1] = lastMessage
            
            delegate?.messageUpdated()
        }
    }
    
    private func messageCompleted() {
        if var lastMessage = messages.last, !lastMessage.isFinal {
            lastMessage.isFinal = true
            lastMessage.content = currentStreamMessage
            messages[messages.count - 1] = lastMessage
            
            delegate?.messageFinished()
        }
        currentStreamMessage = ""
    }
}
