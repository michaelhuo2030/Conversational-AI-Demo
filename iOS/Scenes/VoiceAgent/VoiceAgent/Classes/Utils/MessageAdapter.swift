//
//  MessageAdapter.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/18.
//

import Foundation

private struct TranscriptionMessage: Codable {
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
    let duration_ms: Int
}

private struct Word: Codable {
    let duration_ms: Int
    let stable: Bool
    let start_ms: Int
    let word: String
}

enum MessageOwner {
    case agent
    case me
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
    private var messageQueue: [TranscriptionMessage] = []
    
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
        
        let owner: MessageOwner = message.stream_id == 0 ? .agent : .me
        if incrementalWords {
            //Message enqueued
            //messageQueue.append(message)
        } else {
            delegate?.messageFlush(message: message.text, timestamp: 0, owner: owner, isFinished: message.turn_status == 1)
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
        guard let jsonData = messageParser.parseToJsonData(data) else {
            return
        }
        do {
            let transcription = try JSONDecoder().decode(TranscriptionMessage.self, from: jsonData)
            handleMessage(transcription)
        } catch {
            let string = String(data: jsonData, encoding: .utf8) ?? ""
            print("[MessageAdapter] Failed to parse JSON content \(string) \n error: \(error.localizedDescription)")
            return
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        audioTimestamp = 0
        isFirstFrameCallback = true
    }
}


