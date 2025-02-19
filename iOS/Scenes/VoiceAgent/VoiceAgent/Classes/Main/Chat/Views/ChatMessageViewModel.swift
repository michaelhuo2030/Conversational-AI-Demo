//
//  ChatMessageViewModel.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/19.
//

import Foundation

struct Message {
    var content: String
    let isUser: Bool
    var isFinal: Bool
    let timestamp: Int64
}

protocol ChatMessageViewModelDelegate: AnyObject {
    func startNewMessage()
    func messageUpdated()
    func messageFinished()
}

class ChatMessageViewModel: NSObject {
    var messages: [Message] = []
    weak var delegate: ChatMessageViewModelDelegate?
    var currentStreamMessage: String = ""
    
    func clearMessage() {
        messages.removeAll()
        currentStreamMessage = ""
    }
    
    func messageFlush(turnId:String, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool) {
        if turnId.isEmpty {
           reduceIndependentMessage(message: message, timestamp: timestamp, owner: owner, isFinished: isFinished)
        } else {
            reduceStandardMessage(turnId: turnId, message: message, timestamp: timestamp, owner: owner, isFinished: isFinished)
        }
    }
}




