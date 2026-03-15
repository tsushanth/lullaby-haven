//
//  MixerViewModel.swift
//  LullabyHaven
//
//  ViewModel for the multi-sound mixer (premium feature)
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class MixerViewModel {
    private let audio = AudioPlayerService.shared
    private let library = SoundLibrary.shared
    private var modelContext: ModelContext?

    var mixName: String = "My Mix"
    var currentMix: SoundMix?
    var savedMixes: [SoundMix] = []

    var activeTracks: [ActiveTrack] { audio.activeTracks }
    var canAddMore: Bool { activeTracks.count < 5 }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    func setModelContext(_ ctx: ModelContext) {
        self.modelContext = ctx
        fetchMixes()
    }

    // MARK: - Mix Control
    func addSound(_ sound: SoundDTO) {
        guard canAddMore else { return }
        audio.addToMix(sound: sound, volume: 0.7)
    }

    func removeSound(id: String) {
        audio.removeFromMix(soundID: id)
    }

    func setVolume(for trackID: String, volume: Float) {
        audio.setTrackVolume(soundID: trackID, volume: volume)
    }

    func soundDTO(for trackID: String) -> SoundDTO? {
        library.sound(for: trackID)
    }

    // MARK: - Save Mix
    func saveMix() {
        guard let ctx = modelContext, !activeTracks.isEmpty else { return }
        let tracks = activeTracks.map { track in
            MixTrack(soundID: track.id, volume: track.volume)
        }
        let mix = SoundMix(name: mixName, tracks: tracks)
        ctx.insert(mix)
        try? ctx.save()
        fetchMixes()
    }

    func deleteMix(_ mix: SoundMix) {
        guard let ctx = modelContext else { return }
        ctx.delete(mix)
        try? ctx.save()
        fetchMixes()
    }

    func loadMix(_ mix: SoundMix) {
        audio.stopAll(immediate: true)
        for track in mix.tracks {
            if let sound = library.sound(for: track.soundID) {
                audio.addToMix(sound: sound, volume: track.volume)
            }
        }
        currentMix = mix
        mixName = mix.name
    }

    // MARK: - Fetch
    private func fetchMixes() {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<SoundMix>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        savedMixes = (try? ctx.fetch(descriptor)) ?? []
    }
}
