//
//  MessageAdapter.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/18.
//

import Foundation

private struct TranscriptionMessage: Codable {
    let data_type: String?
    let stream_id: Int?
    let text: String?
    let message_id: String?
    let quiet: Bool?
    let final: Bool?
    let object: String?
    let turn_id: Int?
    let turn_seq_id: Int?
    let turn_status: Int?
    let language: String?
    let user_id: String?
    let words: [Word]?
    let duration_ms: Int64?
    let start_ms: Int64?
    let latency_ms: Int?
    let send_ts: Int?
    let module: String?
    let metric_name: String?
}

private struct Word: Codable {
    let duration_ms: Int?
    let stable: Bool?
    let start_ms: Int64?
    let word: String?
}

private class MessageBuffer {
    var turnId = 0
    var text: String = ""
    var timestamp: Int64 = 0
    var words: [WordBuffer] = []
}

private struct WordBuffer {
    var isFinished: Bool = false
    var text: String = ""
    var timestamp: Int64 = 0
}

enum MessageOwner {
    case agent
    case me
}

private enum TurnStatus: Int {
    case inprogress = 0
    case interrupted
    case end
}

protocol MessageAdapterDelegate: AnyObject {
    func messageFlush(turnId: Int, message: String, timestamp: Int64, owner: MessageOwner, isFinished: Bool)
}

protocol MessageAdapterProtocol {
    func start()
    func updateAudioTimestamp(timestamp: Int64)
    func inputStreamMessageData(data: Data)
    func stop()
}

class MessageAdapter: NSObject {
    
    enum MessageType: String {
        case assistant = "assistant.transcription"
        case user = "user.transcription"
    }
    
    private var timer: Timer?
    private var audioTimestamp: Int64 = 0
    private var isFirstFrameCallback = true
    private var messageParser = MessageParser()
    
    weak var delegate: MessageAdapterDelegate?
    private var messageQueue: [MessageBuffer] = []
    
    private func addLog(_ txt: String) {
        VoiceAgentLogger.info(txt)
    }
    
    private let queue = DispatchQueue(label: "com.voiceagent.messagequeue", attributes: .concurrent)
    
    private func handleMessage(_ message: TranscriptionMessage) {
        if message.object == MessageType.user.rawValue {
            let text = message.text ?? ""
            self.delegate?.messageFlush(turnId: message.turn_id ?? 0,
                                        message: text,
                                        timestamp: message.start_ms ?? 0,
                                        owner: .me,
                                        isFinished: (message.final == true))
//            print("🙋🏻‍♀️[MessageAdapter] send user text: \(text), final: \(message.final == true)")
        } else {
            queue.async(flags: .barrier) {
                var temp: MessageBuffer?
                for buffer in self.messageQueue {
                    if buffer.turnId == message.turn_id {
                        temp = buffer
                        break
                    }
                }
                if temp == nil {
                    temp = MessageBuffer()
                    temp?.turnId = message.turn_id ?? 0
                    // insert buffer by turn id
                    if let turnId = message.turn_id {
                        var insertIndex = 0
                        for (index, buffer) in self.messageQueue.enumerated() {
                            if buffer.turnId < turnId {
                                insertIndex = index + 1
                            } else {
                                break
                            }
                        }
                        self.messageQueue.insert(temp!, at: insertIndex)
                    } else {
                        self.messageQueue.append(temp!)
                    }
                }
                // update buffer
                let isLastOne = (message.turn_status != TurnStatus.inprogress.rawValue)
                temp?.text = message.text ?? ""
                temp?.timestamp = message.start_ms ?? 0
                if let words = message.words, !words.isEmpty {
                    let wordBufferList = words.compactMap { word -> WordBuffer? in
                        guard let wordText = word.word, let startTime = word.start_ms else {
                            return nil
                        }
                        return WordBuffer(isFinished: false,
                                          text: wordText,
                                          timestamp: startTime)
                    }
                    // if the message state is end, sign last word finished
                    if isLastOne,
                       var lastWord = wordBufferList.last {
                        lastWord.isFinished = isLastOne
                        var updatedList = wordBufferList
                        updatedList[updatedList.count - 1] = lastWord
                        temp?.words.append(contentsOf: updatedList)
                        // sort words by timestamp
                        temp?.words.sort { $0.timestamp < $1.timestamp }
                    } else {
                        temp?.words.append(contentsOf: wordBufferList)
                    }
                }
            }
        }
    }
    
    @objc func eventLoop() {
        queue.sync {
            //message dequeue
            for (index, buffer) in self.messageQueue.enumerated().reversed() {
                let currentWords = buffer.words.filter { $0.timestamp < audioTimestamp }
                let isFinished = currentWords.last?.isFinished ?? false
                let text = currentWords.map { $0.text }.joined()
                if !text.isEmpty {
//                    print("🌍[MessageAdapter] send current words: \(text) isFinished: \(isFinished)")
                    self.delegate?.messageFlush(turnId: buffer.turnId, message: text, timestamp: buffer.timestamp, owner: .agent, isFinished: isFinished)
                }
                if (isFinished) {
                    self.messageQueue.remove(at: index)
                }
                if index > 0, !text.isEmpty {
                    self.messageQueue.removeSubrange(0..<index)
                    break
                }
            }
        }
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
        let string = String(data: jsonData, encoding: .utf8) ?? ""
//        print("✅[MessageAdapter] json: \(string)")
        do {
            let transcription = try JSONDecoder().decode(TranscriptionMessage.self, from: jsonData)
            handleMessage(transcription)
        } catch {
//            print("⚠️[MessageAdapter] Failed to parse JSON content \(string) error: \(error.localizedDescription)")
            return
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        audioTimestamp = 0
        isFirstFrameCallback = true
        messageQueue.removeAll()
    }
}


