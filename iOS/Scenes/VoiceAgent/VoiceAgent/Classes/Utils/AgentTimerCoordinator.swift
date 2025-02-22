//
//  AgentTimerCoordinator.swift
//  VoiceAgent
//
//  Created by qinhui on 2025/2/21.
//

import Foundation
import Common

protocol AgentTimerCoordinatorDelegate: AnyObject {
    func agentStartPing()
    func agentNotJoinedWithinTheScheduledTime()
    func agentUseLimitedTimerStarted(duration: Int)
    func agentUseLimitedTimerUpdated(duration: Int)
    func agentUseLimitedTimerEnd()
}

protocol AgentTimerCoordinatorProtocol {
    func startPingTimer()
    func stopPingTimer()
    
    func startJoinChannelTimer()
    func stopJoinChannelTimer()
    
    func startUsageDurationLimitTimer()
    func stopUsageDurationLimitTimer()
    
    func stopAllTimer()
}

class AgentTimerCoordinator: NSObject {
    weak var delegate: AgentTimerCoordinatorDelegate?
    private var pingTimer: Timer?
    private var joinChannelTimer: Timer?
    private var usageDurationLimitTimer: Timer?
    private var useDuration = 600
    private let pingTimeInterval = 10.0

    private func initDurationLimitTimer() {
        if let manager = AppContext.preferenceManager(), let preset = manager.preference.preset {
            useDuration = preset.callTimeLimitSecond
            usageDurationLimitTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    return
                }
                
                if self.useDuration <= 0 {
                    self.deinitDurationLimitTimer()
                }
                
                self.delegate?.agentUseLimitedTimerUpdated(duration: self.useDuration)
                self.useDuration -= 1
            })
        }
        
        self.delegate?.agentUseLimitedTimerStarted(duration: useDuration)
    }
    
    private func deinitDurationLimitTimer() {
        self.delegate?.agentUseLimitedTimerEnd()

        useDuration = 0
        usageDurationLimitTimer?.invalidate()
        usageDurationLimitTimer = nil
    }
    
    private func initPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingTimeInterval, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            self.delegate?.agentStartPing()
        })
    }
    
    private func deinitPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func initJoinChannelTimer() {
        joinChannelTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            self.delegate?.agentNotJoinedWithinTheScheduledTime()
        })
    }
    
    private func deinitJoinChannelTimer() {
        joinChannelTimer?.invalidate()
        joinChannelTimer = nil
    }
}

extension AgentTimerCoordinator: AgentTimerCoordinatorProtocol {
    func startPingTimer() {
        initPingTimer()
    }
    
    func stopPingTimer() {
        deinitPingTimer()
    }
    
    func startJoinChannelTimer() {
        initJoinChannelTimer()
    }
    
    func stopJoinChannelTimer() {
        deinitJoinChannelTimer()
    }
    
    func startUsageDurationLimitTimer() {
        initDurationLimitTimer()
    }
    
    func stopUsageDurationLimitTimer() {
        deinitDurationLimitTimer()
    }
    
    func stopAllTimer() {
        deinitPingTimer()
        deinitJoinChannelTimer()
        deinitDurationLimitTimer()
    }
}
