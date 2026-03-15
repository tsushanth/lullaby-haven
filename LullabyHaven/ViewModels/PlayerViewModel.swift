//
//  PlayerViewModel.swift
//  LullabyHaven
//
//  ViewModel coordinating audio playback, timer, and session tracking
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class PlayerViewModel {
    // MARK: - Dependencies
    private let audio = AudioPlayerService.shared
    private let library = SoundLibrary.shared
    private let timerService = SleepTimerService.shared
    private var modelContext: ModelContext?

    // MARK: - Playback State (mirrors audio service)
    var isPlaying: Bool { audio.playbackState == .playing || audio.playbackState == .fadingOut }
    var isFadingOut: Bool { audio.playbackState == .fadingOut }
    var activeTracks: [ActiveTrack] { audio.activeTracks }
    var masterVolume: Float {
        get { audio.masterVolume }
        set { audio.setMasterVolume(newValue) }
    }

    // MARK: - Current Sound
    var currentSound: SoundDTO?
    var isMixMode: Bool = false

    // MARK: - Session
    private var currentSession: SleepSession?

    // MARK: - Init
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Play Single Sound
    func play(sound: SoundDTO) {
        currentSound = sound
        isMixMode = false
        audio.play(sound: sound)
        startSession(soundIDs: [sound.id])
    }

    // MARK: - Mix Controls (premium)
    func addToMix(sound: SoundDTO) {
        isMixMode = true
        audio.addToMix(sound: sound, volume: 0.7)

        var ids = activeTracks.map { $0.id }
        if !ids.contains(sound.id) { ids.append(sound.id) }
        if currentSession == nil { startSession(soundIDs: ids) }
    }

    func removeFromMix(soundID: String) {
        audio.removeFromMix(soundID: soundID)
        if activeTracks.isEmpty { stopPlayback() }
    }

    func setTrackVolume(soundID: String, volume: Float) {
        audio.setTrackVolume(soundID: soundID, volume: volume)
    }

    // MARK: - Playback Control
    func pausePlayback() {
        audio.pause()
    }

    func resumePlayback() {
        audio.resume()
    }

    func stopPlayback() {
        audio.stopAll()
        endSession()
        currentSound = nil
        isMixMode = false
    }

    func togglePlayback() {
        if isPlaying { pausePlayback() } else { resumePlayback() }
    }

    // MARK: - Timer
    var timerState: TimerState { timerService.timer.state }
    var timerRemaining: String { timerService.timer.timeRemainingFormatted }
    var timerProgress: Double { timerService.timer.progress }
    var isTimerActive: Bool { timerService.isTimerActive }

    func startTimer(duration: TimerDuration) {
        timerService.startTimer(duration: duration)
    }

    func cancelTimer() {
        timerService.cancelTimer()
    }

    // MARK: - Session Tracking
    private func startSession(soundIDs: [String]) {
        guard let ctx = modelContext else { return }
        let session = SleepSession(soundIDs: soundIDs, timerDurationMinutes: timerService.selectedDuration.minutes)
        ctx.insert(session)
        currentSession = session
    }

    private func endSession() {
        guard let session = currentSession, let ctx = modelContext else { return }
        session.end()
        try? ctx.save()
        currentSession = nil
    }

    // MARK: - Favorite Toggle
    func toggleFavorite(soundID: String, favorites: [FavoriteSound]) -> Bool {
        guard let ctx = modelContext else { return false }
        if let existing = favorites.first(where: { $0.soundID == soundID }) {
            ctx.delete(existing)
            try? ctx.save()
            return false
        } else {
            let fav = FavoriteSound(soundID: soundID, sortOrder: favorites.count)
            ctx.insert(fav)
            try? ctx.save()
            return true
        }
    }

    func isFavorite(soundID: String, favorites: [FavoriteSound]) -> Bool {
        favorites.contains { $0.soundID == soundID }
    }
}
