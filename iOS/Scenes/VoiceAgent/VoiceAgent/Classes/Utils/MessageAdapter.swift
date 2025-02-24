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
    let is_final: Bool?
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

private class TurnObj {
    var turnId = 0
    var text: String = ""
    var words: [WordObj] = []
    var status: TurnStatus = .inprogress
}

private struct WordObj {
    var isFinished: Bool = false
    var text: String = ""
    var start_ns: Int64 = 0
}

enum MessageOwner {
    case agent
    case me
}

enum MessageMode {
    case idle
    case words
    case text
}

private enum TurnStatus: Int {
    case inprogress = 0
    case interrupted
    case end
}

protocol MessageAdapterDelegate: AnyObject {
    func messageFlush(turnId: Int, message: String, owner: MessageOwner, isFinished: Bool, isInterrupted: Bool)
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
    private var messageParser = MessageParser()
    
    weak var delegate: MessageAdapterDelegate?
    private var messageQueue: [TurnObj] = []
    private var messageMode: MessageMode = .idle
    
    private var lastFinishTurn: TurnObj? = nil
    
    private func addLog(_ txt: String) {
        VoiceAgentLogger.info(txt)
    }
    
    private let queue = DispatchQueue(label: "com.voiceagent.messagequeue", attributes: .concurrent)
    
    private func handleMessage(_ message: TranscriptionMessage) {
        if messageMode == .idle {
            if let words = message.words, words.isEmpty == false {
                messageMode = .text
                timer?.invalidate()
                timer = nil
            } else {
                messageMode = .words
            }
        }
        if messageMode == .words {
            handleWordsMessage(message)
        } else {
            handleTextMessage(message)
        }
    }
    
    private func handleTextMessage(_ message: TranscriptionMessage) {
        guard let text = message.text,
              let isFinal = message.is_final
        else {
            return
        }
        if message.stream_id == 0 {
            self.delegate?.messageFlush(turnId: -1,
                                        message: text,
                                        owner: .agent,
                                        isFinished: isFinal,
                                        isInterrupted: false)
            print("🌍[MessageAdapter] send agent text: \(text), final: \(isFinal)")
        } else {
            let text = message.text ?? ""
            self.delegate?.messageFlush(turnId: -1,
                                        message: text,
                                        owner: .me,
                                        isFinished: isFinal,
                                        isInterrupted: false)
            print("🙋🏻‍♀️[MessageAdapter] send user text: \(text), final: \(isFinal)")
        }
    }
    
    private func handleWordsMessage(_ message: TranscriptionMessage) {
        if message.object == MessageType.user.rawValue {
            let text = message.text ?? ""
            self.delegate?.messageFlush(turnId: message.turn_id ?? 0,
                                        message: text,
                                        owner: .me,
                                        isFinished: (message.final == true),
                                        isInterrupted: false)
//            print("🙋🏻‍♀️[MessageAdapter] send user text: \(text), final: \(message.final == true)")
        } else {
            queue.async(flags: .barrier) {
                if let queueLastTurnId = self.messageQueue.last?.turnId,
                   queueLastTurnId > (message.turn_id ?? 0) {
                    return
                }
                if let lastFinishTurnId = self.lastFinishTurn?.turnId,
                   lastFinishTurnId > (message.turn_id ?? 0) {
                    return
                }
                guard let status = TurnStatus(rawValue: message.turn_status ?? 0) else {
                    return
                }
                guard let status = TurnStatus(rawValue: message.turn_status ?? 0) else {
                    return
                }
                var temp: TurnObj?
                for buffer in self.messageQueue {
                    if buffer.turnId == message.turn_id {
                        temp = buffer
                        break
                    }
                }
                if temp == nil {
                    let newTurn = TurnObj()
                    newTurn.turnId = message.turn_id ?? 0
                    self.messageQueue.append(newTurn)
                    temp = newTurn
                }
                // update buffer
                let isMessageFinished = (message.turn_status != TurnStatus.inprogress.rawValue)
                temp?.text = message.text ?? ""
                temp?.status = status
                if let words = message.words, !words.isEmpty {
                    let wordBufferList = words.compactMap { word -> WordObj? in
                        guard let wordText = word.word, let startTime = word.start_ms else {
                            return nil
                        }
                        return WordObj(isFinished: false,
                                       text: wordText,
                                       start_ns: startTime)
                    }
                    // if the message state is end, sign last word finished
                    temp?.words.append(contentsOf: wordBufferList)
                    // sort words by timestamp
                    temp?.words.sort { $0.start_ns < $1.start_ns }
                    if isMessageFinished, var lastWord = temp?.words.last {
                        lastWord.isFinished = isMessageFinished
                    }
                }
            }
        }
    }
    
    @objc func eventLoop() {
        queue.sync {
            guard self.messageQueue.isEmpty == false else {
                return
            }
            //message dequeue
            var isSended = false
            for (index, buffer) in self.messageQueue.enumerated().reversed() {
                if isSended {
                    // message intterupted by before message
//                    self.delegate?.messageFlush(turnId: buffer.turnId, message: "", owner: .agent, isFinished: true, isInterrupted: true)
                    self.messageQueue.remove(at: index)
                    continue
                }
                let currentWords = buffer.words.filter { $0.start_ns < audioTimestamp }
                let isFinished = currentWords.last?.isFinished ?? false
                var text: String
                if isFinished {
                    text = buffer.text
                    self.messageQueue.remove(at: index)
                    lastFinishTurn = buffer
                    print("🌍[MessageAdapter] send current words: \(text)")
                } else {
                    text = currentWords.map { $0.text }.joined()
//                    print("🌍[MessageAdapter] unfinish words: \(text)")
                }
                if !text.isEmpty {
                    isSended = true
                    self.delegate?.messageFlush(turnId: buffer.turnId, message: text, owner: .agent, isFinished: isFinished, isInterrupted: false)
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
        
        if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let jsonDataPretty = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let jsonString = String(data: jsonDataPretty, encoding: .utf8) {
            print("✅[MessageAdapter] json: \(jsonString)")
        } else {
            print("❌[MessageAdapter] 无法解析 JSON 数据")
        }
        
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
        messageMode = .idle
        audioTimestamp = 0
        messageQueue.removeAll()
    }
}


