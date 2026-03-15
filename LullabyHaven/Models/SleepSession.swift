//
//  SleepSession.swift
//  LullabyHaven
//
//  SwiftData model tracking baby sleep sessions for analytics (premium)
//

import Foundation
import SwiftData

@Model
final class SleepSession {
    @Attribute(.unique) var id: String
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Double
    var soundIDs: [String]      // sounds played during session
    var timerDurationMinutes: Int
    var notes: String
    var babyFellAsleepMinutes: Int?   // user-reported time to sleep

    init(soundIDs: [String], timerDurationMinutes: Int = 0) {
        self.id = UUID().uuidString
        self.startedAt = Date()
        self.endedAt = nil
        self.durationSeconds = 0
        self.soundIDs = soundIDs
        self.timerDurationMinutes = timerDurationMinutes
        self.notes = ""
        self.babyFellAsleepMinutes = nil
    }

    func end() {
        endedAt = Date()
        durationSeconds = endedAt!.timeIntervalSince(startedAt)
    }

    var durationFormatted: String {
        let mins = Int(durationSeconds) / 60
        let hours = mins / 60
        let remainMins = mins % 60
        if hours > 0 {
            return "\(hours)h \(remainMins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Sleep Analytics Summary
struct SleepAnalyticsSummary {
    let totalSessions: Int
    let totalMinutesPlayed: Double
    let averageSessionMinutes: Double
    let mostUsedSoundIDs: [String]
    let sessionsThisWeek: Int
    let longestSessionMinutes: Double

    static let empty = SleepAnalyticsSummary(
        totalSessions: 0,
        totalMinutesPlayed: 0,
        averageSessionMinutes: 0,
        mostUsedSoundIDs: [],
        sessionsThisWeek: 0,
        longestSessionMinutes: 0
    )
}
