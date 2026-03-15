//
//  SleepTimerService.swift
//  LullabyHaven
//
//  Coordinates sleep timer with audio fade-out
//

import Foundation
import Observation

@MainActor
@Observable
final class SleepTimerService {
    // MARK: - State
    var timer = SleepTimer()
    var isTimerActive: Bool { timer.isRunning }
    var selectedDuration: TimerDuration = .thirtyMin

    // MARK: - Singleton
    static let shared = SleepTimerService()
    private init() {
        setupCallbacks()
    }

    // MARK: - Setup
    private func setupCallbacks() {
        timer.onFadeOutStarted = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleFadeOutStarted()
            }
        }
        timer.onTimerFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleTimerFinished()
            }
        }
    }

    // MARK: - Control
    func startTimer(duration: TimerDuration) {
        selectedDuration = duration
        timer.start(duration: duration)
        scheduleNotification(for: duration)
    }

    func pauseTimer() {
        timer.pause()
    }

    func resumeTimer() {
        timer.resume()
    }

    func cancelTimer() {
        timer.stop()
        NotificationManager.shared.cancelTimerNotification()
    }

    // MARK: - Callbacks
    private func handleFadeOutStarted() {
        guard timer.isFadeOutEnabled else { return }
        AudioPlayerService.shared.startFadeOut(over: timer.fadeOutDuration)
    }

    private func handleTimerFinished() {
        AudioPlayerService.shared.stopAll(immediate: true)
        NotificationManager.shared.cancelTimerNotification()
    }

    // MARK: - Notification
    private func scheduleNotification(for duration: TimerDuration) {
        let fireDate = Date().addingTimeInterval(duration.seconds)
        NotificationManager.shared.scheduleSleepTimerNotification(at: fireDate)
    }
}
