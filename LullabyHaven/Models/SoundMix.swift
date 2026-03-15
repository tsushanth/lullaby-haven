//
//  SoundMix.swift
//  LullabyHaven
//
//  Model for multi-sound mixing (premium feature)
//

import Foundation
import SwiftData

// MARK: - Mix Track
struct MixTrack: Codable, Identifiable {
    let id: String
    var soundID: String
    var volume: Float    // 0.0 - 1.0

    init(soundID: String, volume: Float = 0.7) {
        self.id = UUID().uuidString
        self.soundID = soundID
        self.volume = volume
    }
}

// MARK: - Sound Mix Model
@Model
final class SoundMix {
    @Attribute(.unique) var id: String
    var name: String
    var tracksData: Data       // Encoded [MixTrack]
    var isFavorite: Bool
    var createdAt: Date
    var lastPlayedAt: Date?
    var playCount: Int

    init(name: String, tracks: [MixTrack] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.tracksData = (try? JSONEncoder().encode(tracks)) ?? Data()
        self.isFavorite = false
        self.createdAt = Date()
        self.lastPlayedAt = nil
        self.playCount = 0
    }

    var tracks: [MixTrack] {
        get {
            (try? JSONDecoder().decode([MixTrack].self, from: tracksData)) ?? []
        }
        set {
            tracksData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    func addTrack(soundID: String, volume: Float = 0.7) {
        var current = tracks
        guard current.count < 5 else { return }   // max 5 tracks
        current.append(MixTrack(soundID: soundID, volume: volume))
        tracks = current
    }

    func removeTrack(id: String) {
        tracks = tracks.filter { $0.id != id }
    }

    func updateVolume(trackID: String, volume: Float) {
        var current = tracks
        if let idx = current.firstIndex(where: { $0.id == trackID }) {
            current[idx].volume = volume
        }
        tracks = current
    }
}

// MARK: - Mix Preview DTO
struct SoundMixDTO: Identifiable {
    let id: String
    let name: String
    var tracks: [MixTrack]
    var isFavorite: Bool

    init(from mix: SoundMix) {
        self.id = mix.id
        self.name = mix.name
        self.tracks = mix.tracks
        self.isFavorite = mix.isFavorite
    }
}
