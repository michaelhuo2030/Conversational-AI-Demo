//
//  CovSubRenderController.swift
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
    var start_ms: Int64 = 0
    var words: [WordObj] = []
    var bufferState: SubtitleStatus = .inprogress
}

private struct WordObj {
    let text: String
    let start_ms: Int64
    var status: SubtitleStatus = .inprogress
}

enum MessageOwner {
    case agent
    case me
}

enum RenderMode {
    case idle
    case words
    case text
}

enum SubtitleStatus: Int {
    case inprogress = 0
    case end = 1
    case interrupt = 2
}

struct SubtitleMessage {
    let turnId: Int
    let isMe: Bool
    let text: String
    var status: SubtitleStatus
}

private typealias TurnState = SubtitleStatus

protocol ICovMessageListView: AnyObject {
    func messageFlush(turnId: Int, message: String, owner: MessageOwner, timestamp: Int64, isFinished: Bool, isInterrupted: Bool)
    
    func onUpdateStreamContent(subtitle: SubtitleMessage)
}

protocol CovSubRenderControllerProtocol {
    func start()
    func updateAudioTimestamp(timestamp: Int64)
    func inputStreamMessageData(data: Data)
    func stop()
}

// MARK: - CovSubRenderController
class CovSubRenderController: NSObject {
    
    enum MessageType: String {
        case assistant = "assistant.transcription"
        case user = "user.transcription"
        case interrupt = "message.interrupt"
        case unknown = "unknown"
        case string = "string"
    }
    
    private var timer: Timer?
    private var audioTimestamp: Int64 = 0
    private var messageParser = MessageParser()
    
    weak var delegate: ICovMessageListView?
    private var messageQueue: [TurnObj] = []
    private var renderMode: RenderMode = .idle
    
    private var lastMessage: SubtitleMessage? = nil
    private var lastFinishMessage: SubtitleMessage? = nil
    
    private func addLog(_ txt: String) {
        VoiceAgentLogger.info(txt)
    }
    
    private let queue = DispatchQueue(label: "com.voiceagent.messagequeue", attributes: .concurrent)
    
    private func handleMessage(_ message: TranscriptionMessage) {
        let renderMode = getMessageMode(message)
        if renderMode == .words {
            handleWordsMessage(message)
        } else if renderMode == .text {
            handleTextMessage(message)
        }
    }
    
    private func getMessageMode(_ message: TranscriptionMessage) -> RenderMode {
        let messageType = MessageType(rawValue: message.object ?? "string") ?? .unknown
        if renderMode == .idle {
            if messageType == .interrupt || messageType == .unknown {
                return .idle
            }
            if let words = message.words, !words.isEmpty {
                renderMode = .words
            } else {
                renderMode = .text
                timer?.invalidate()
                timer = nil
            }
        }
        return renderMode
    }
    
    private func handleTextMessage(_ message: TranscriptionMessage) {
        guard let text = message.text, !text.isEmpty else {
            return
        }
        let isFinal = message.is_final ?? false
        if message.stream_id == 0 {
            self.delegate?.messageFlush(turnId: -1,
                                        message: text,
                                        owner: .agent,
                                        timestamp: message.start_ms ?? 0,
                                        isFinished: isFinal,
                                        isInterrupted: false)
            print("🌍[CovSubRenderController] send agent text: \(text), final: \(isFinal)")
        } else {
            self.delegate?.messageFlush(turnId: -1,
                                        message: text,
                                        owner: .me,
                                        timestamp: message.start_ms ?? 0,
                                        isFinished: isFinal,
                                        isInterrupted: false)
            print("🙋🏻‍♀️[CovSubRenderController] send user text: \(text), final: \(isFinal)")
        }
    }
    
    private func handleWordsMessage(_ message: TranscriptionMessage) {
        if message.object == MessageType.user.rawValue {
            let text = message.text ?? ""
            let subtitleMessage = SubtitleMessage(turnId: message.turn_id ?? 0,
                                                  isMe: true,
                                                  text: text,
                                                  status: (message.final == true) ? .end : .inprogress)
            self.delegate?.onUpdateStreamContent(subtitle: subtitleMessage)
            return
        }
        
        queue.async(flags: .barrier) {
            // handle new agent message
            if message.object == MessageType.assistant.rawValue {
                if let lastFinishId = self.lastFinishMessage?.turnId,
                   lastFinishId >= (message.turn_id ?? 0) {
                    return
                }
                if let queueLastTurnId = self.messageQueue.last?.turnId,
                   queueLastTurnId > (message.turn_id ?? 0) {
                    return
                }
                guard let turnStatus = TurnState(rawValue: message.turn_status ?? 0) else {
                    return
                }
                print("🌍[CovSubRenderController] message turn_id: \(message.turn_id ?? 0), status: \(turnStatus)")
                let curBuffer: TurnObj = self.messageQueue.first { $0.turnId == message.turn_id } ?? {
                    let newTurn = TurnObj()
                    newTurn.turnId = message.turn_id ?? 0
                    self.messageQueue.append(newTurn)
                    print("🌍[CovSubRenderController] add new turn")
                    return newTurn
                }()
                // if this message time is later than current buffer time, update buffer
                if let msgMS = message.start_ms,
                   msgMS > curBuffer.start_ms
                {
                    curBuffer.start_ms = message.start_ms ?? 0
                    curBuffer.text = message.text ?? ""
                    print("🌍[CovSubRenderController] update turn")
                }
                // update buffer
                if let words = message.words, !words.isEmpty
                {
                    print("🌍[CovSubRenderController] update words: \(words.map { $0.word ?? "" }.joined())")
                    let bufferWords = curBuffer.words
                    let uniqueWords = words.filter { newWord in
                        return !bufferWords.contains { firstWord in firstWord.start_ms == newWord.start_ms}
                    }
                    // if diffrent ms words received, add new words to buffer
                    if !uniqueWords.isEmpty
                    {
                        // if the last message is final sign, reset it
                        if var lastWord = bufferWords.last, (lastWord.status == .end)
                        {
                            lastWord.status = .inprogress
                            curBuffer.words.removeLast()
                            curBuffer.words.append(lastWord)
                        }
                        // add new words to buffer and resort
                        let addWords = uniqueWords.compactMap { word -> WordObj? in
                            guard let wordText = word.word, let startTime = word.start_ms else {
                                return nil
                            }
                            return WordObj(text: wordText,
                                           start_ms: startTime)
                        }
                        curBuffer.words.append(contentsOf: addWords)
                        // sort words by timestamp
                        curBuffer.words.sort { $0.start_ms < $1.start_ms }
                    }
                }
                // if the message state is end, sign last word finished
                if turnStatus == .end, var lastWord = curBuffer.words.last, lastWord.status != .end {
                    lastWord.status = .end
                    // sign last word
                    curBuffer.words.removeLast()
                    curBuffer.words.append(lastWord)
                }
            } else if (message.object == MessageType.interrupt.rawValue) {// handle interrupt
                if let interruptTime = message.start_ms,
                   let buffer: TurnObj = self.messageQueue.first(where: { $0.turnId == message.turn_id })
                {
                    print("🚧[CovSubRenderController] interrupt: \(buffer.turnId) after \(buffer.words.first(where: {$0.start_ms > interruptTime})?.text ?? "")")
                    for index in buffer.words.indices {
                        if buffer.words[index].start_ms > interruptTime {
                            buffer.words[index].status = .interrupt
                        }
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
            var interrupte = false
            for (index, buffer) in self.messageQueue.enumerated().reversed() {
                if interrupte {
                    self.messageQueue.remove(at: index)
                    continue
                }
                // if last turn is interrupte by this buffer
                if var lastMessage = lastMessage,
                   lastMessage.status == .inprogress,
                   buffer.turnId > lastMessage.turnId  {
                    // interrupte last turn
                    lastMessage.status = .interrupt
                    self.delegate?.onUpdateStreamContent(subtitle: lastMessage)
                    interrupte = true
                }
                // get turn sub range
                let inprogressSub = buffer.words.firstIndex(where: { $0.start_ms > audioTimestamp} )
                let interruptSub = buffer.words.firstIndex(where: { $0.status == .interrupt} )
                let endSub = buffer.words.firstIndex(where: { $0.status == .end} )
                let minIndex = [inprogressSub, interruptSub, endSub].compactMap { $0 }.min()
                guard let minRange = minIndex else {
                    return
                }
                let currentWords = Array(buffer.words[0..<minRange])
                // send turn with state
                var subtitleMessage: SubtitleMessage
                if minRange == interruptSub {
                    subtitleMessage = SubtitleMessage(turnId: buffer.turnId,
                                                      isMe: false,
                                                      text: currentWords.map { $0.text }.joined(),
                                                      status: .interrupt)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    lastFinishMessage = subtitleMessage
                } else if minRange == endSub {
                    subtitleMessage = SubtitleMessage(turnId: buffer.turnId,
                                                      isMe: false,
                                                      text: buffer.text,
                                                      status: .end)
                    // remove finished turn
                    self.messageQueue.remove(at: index)
                    lastFinishMessage = subtitleMessage
                } else {
                    subtitleMessage = SubtitleMessage(turnId: buffer.turnId,
                                                      isMe: false,
                                                      text: currentWords.map { $0.text }.joined(),
                                                      status: .inprogress)
                }
                print("📊 [CovSubRenderController] message flush state: \(subtitleMessage.status)")
//                print("📊 [CovSubRenderController] turn: \(buffer.turnId) range \(buffer.words.count) Subrange: \(minRange) words: \(currentWords.map { $0.text }.joined())")
                if !subtitleMessage.text.isEmpty {
                    lastMessage = subtitleMessage
                    self.delegate?.onUpdateStreamContent(subtitle: subtitleMessage)
                }
            }
        }
    }
}

extension CovSubRenderController: CovSubRenderControllerProtocol {
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
        print("✅[CovSubRenderController] json: \(string)")
        do {
            let transcription = try JSONDecoder().decode(TranscriptionMessage.self, from: jsonData)
            handleMessage(transcription)
        } catch {
            print("⚠️[CovSubRenderController] Failed to parse JSON content \(string) error: \(error.localizedDescription)")
            return
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        renderMode = .idle
        lastMessage = nil
        lastFinishMessage = nil
        audioTimestamp = 0
        messageQueue.removeAll()
    }
}


