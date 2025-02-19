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
        
    }
}
