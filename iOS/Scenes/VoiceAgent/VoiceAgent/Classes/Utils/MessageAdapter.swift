//
//  MessageAdapter.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/18.
//

import Foundation

enum MessageOwner {
    case agent
    case user
}

protocol MessageAdapterDelegate: AnyObject {
    func messageFlush(message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool)
}

protocol MessageAdapterProtocol {
    func start()
    func updateAudioTimestamp(timestamp: Int64)
    func inputStreamMessageData(data: Data)
    func stop()
}

class MessageAdapter: NSObject {
    private var timer: Timer?
    private var audioTimestamp: Int64 = 0
    private var isFirstFrameCallback = true
    private var messageParser = MessageParser()
    
    weak var delegate: MessageAdapterDelegate?
    
    private func addLog(_ txt: String) {
        VoiceAgentLogger.info(txt)
    }
    
    private func handleMessage(_ message: TranscriptionMessage) {
//        message.stream_id
        
        var incrementalWords = false
        if isFirstFrameCallback, !message.words!.isEmpty{
            incrementalWords = true
            isFirstFrameCallback = false
        }
        
        if incrementalWords {
            //Message enqueued
        } else {
            let owner: MessageOwner = message.stream_id == 0 ? .agent : .user
            delegate?.messageFlush(message: message.text, timestamp: 0, owner: owner, isFinished: message.is_final)
        }
    }
    
    @objc func eventLoop() {
        //message dequeue
    }
}

extension MessageAdapter: MessageAdapterProtocol {
    func start() {
        timer?.invalidate()
        timer = nil
        
        timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(eventLoop), userInfo: nil, repeats: true)
    }
    
    func updateAudioTimestamp(timestamp: Int64) {
        audioTimestamp = timestamp
    }
    
    func inputStreamMessageData(data: Data) {
        guard let rawString = String(data: data, encoding: .utf8) else {
            addLog("Failed to convert data to string")
            return
        }
        if let message = messageParser.parse(data) {
            handleMessage(message)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        audioTimestamp = 0
        isFirstFrameCallback = true
    }
}


