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
    func agentTimeLimited()
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
    private var useDuration = 0
    private let pingTimeInterval = 10.0

    private func initDurationLimitTimer() {
        if let manager = AppContext.preferenceManager(), let preset = manager.preference.preset {
            let limitDuration = preset.callTimeLimitSecond
            useDuration = 0
            usageDurationLimitTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] timer in
                guard let self = self else {
                    return
                }
                
                if self.useDuration >= limitDuration {
                    self.delegate?.agentTimeLimited()
                    self.deinitDurationLimitTimer()
                }
                self.useDuration += 1
            })
        }
    }
    
    private func deinitDurationLimitTimer() {
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
