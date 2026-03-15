//
//  SleepTimer.swift
//  LullabyHaven
//
//  Sleep timer configuration and state
//

import Foundation

// MARK: - Timer Duration
enum TimerDuration: Identifiable, CaseIterable {
    case fifteenMin
    case thirtyMin
    case sixtyMin
    case ninetyMin
    case twoHours
    case allNight          // 8 hours
    case custom(Int)       // minutes

    static var allCases: [TimerDuration] {
        [.fifteenMin, .thirtyMin, .sixtyMin, .ninetyMin, .twoHours, .allNight]
    }

    var id: String { displayName }

    var minutes: Int {
        switch self {
        case .fifteenMin:   return 15
        case .thirtyMin:    return 30
        case .sixtyMin:     return 60
        case .ninetyMin:    return 90
        case .twoHours:     return 120
        case .allNight:     return 480
        case .custom(let m): return m
        }
    }

    var seconds: TimeInterval {
        TimeInterval(minutes * 60)
    }

    var displayName: String {
        switch self {
        case .fifteenMin:   return "15 min"
        case .thirtyMin:    return "30 min"
        case .sixtyMin:     return "1 hour"
        case .ninetyMin:    return "1.5 hrs"
        case .twoHours:     return "2 hours"
        case .allNight:     return "All Night"
        case .custom(let m): return "\(m) min"
        }
    }

    var isPremium: Bool {
        switch self {
        case .allNight, .twoHours, .custom: return true
        default: return false
        }
    }

    var iconName: String {
        switch self {
        case .fifteenMin:   return "15.circle"
        case .thirtyMin:    return "30.circle"
        case .sixtyMin:     return "60.circle"
        case .ninetyMin:    return "90.circle"
        case .twoHours:     return "timer"
        case .allNight:     return "moon.stars.fill"
        case .custom:       return "timer"
        }
    }
}

// MARK: - Timer State
enum TimerState {
    case idle
    case running
    case paused
    case fadingOut
    case finished
}

// MARK: - Sleep Timer
@Observable
final class SleepTimer {
    var state: TimerState = .idle
    var selectedDuration: TimerDuration = .thirtyMin
    var remainingSeconds: TimeInterval = 0
    var fadeOutDuration: TimeInterval = 30    // seconds of fade-out before stopping
    var isFadeOutEnabled: Bool = true

    private var timer: Timer?
    private var startDate: Date?
    var onTimerFinished: (() -> Void)?
    var onFadeOutStarted: (() -> Void)?

    var isRunning: Bool { state == .running || state == .fadingOut }

    var progress: Double {
        guard selectedDuration.seconds > 0 else { return 0 }
        let elapsed = selectedDuration.seconds - remainingSeconds
        return elapsed / selectedDuration.seconds
    }

    var timeRemainingFormatted: String {
        let totalSeconds = Int(remainingSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    func start(duration: TimerDuration) {
        stop()
        selectedDuration = duration
        remainingSeconds = duration.seconds
        state = .running
        startDate = Date()
        scheduleTimer()
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        remainingSeconds = 0
        startDate = nil
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        guard state == .running || state == .fadingOut else { return }
        remainingSeconds -= 1

        // Start fade-out phase
        if isFadeOutEnabled && state == .running && remainingSeconds <= fadeOutDuration && remainingSeconds > 0 {
            state = .fadingOut
            onFadeOutStarted?()
        }

        if remainingSeconds <= 0 {
            finish()
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        state = .finished
        remainingSeconds = 0
        onTimerFinished?()
    }
}
