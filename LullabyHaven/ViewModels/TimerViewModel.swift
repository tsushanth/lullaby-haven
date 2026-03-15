//
//  TimerViewModel.swift
//  LullabyHaven
//
//  ViewModel for sleep timer UI
//

import Foundation
import Observation

@MainActor
@Observable
final class TimerViewModel {
    private let timerService = SleepTimerService.shared

    var selectedDuration: TimerDuration = .thirtyMin
    var isFadeOutEnabled: Bool = true {
        didSet { timerService.timer.isFadeOutEnabled = isFadeOutEnabled }
    }

    var timerState: TimerState { timerService.timer.state }
    var timeRemainingFormatted: String { timerService.timer.timeRemainingFormatted }
    var progress: Double { timerService.timer.progress }
    var isRunning: Bool { timerService.isTimerActive }

    var durations: [TimerDuration] { TimerDuration.allCases }

    func startTimer(isPremium: Bool) {
        let duration = selectedDuration
        guard !duration.isPremium || isPremium else { return }
        timerService.startTimer(duration: duration)
    }

    func pauseTimer() { timerService.pauseTimer() }
    func resumeTimer() { timerService.resumeTimer() }
    func cancelTimer() { timerService.cancelTimer() }

    func toggleTimer(isPremium: Bool) {
        if isRunning {
            if timerState == .paused { resumeTimer() } else { pauseTimer() }
        } else {
            startTimer(isPremium: isPremium)
        }
    }

    var timerButtonTitle: String {
        switch timerState {
        case .idle:     return "Start Timer"
        case .running:  return "Pause"
        case .paused:   return "Resume"
        case .fadingOut: return "Fading..."
        case .finished: return "Start Timer"
        }
    }

    var timerStatusLabel: String {
        switch timerState {
        case .idle:      return "No timer set"
        case .running:   return "Timer running"
        case .paused:    return "Timer paused"
        case .fadingOut: return "Fading out..."
        case .finished:  return "Timer finished"
        }
    }
}
