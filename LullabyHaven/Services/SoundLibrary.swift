//
//  SoundLibrary.swift
//  LullabyHaven
//
//  Manages the full catalog of sleep sounds, filtering, and search
//

import Foundation
import Observation

@MainActor
@Observable
final class SoundLibrary {
    // MARK: - Properties
    private(set) var allSounds: [SoundDTO] = []
    private(set) var isLoaded: Bool = false

    var searchQuery: String = ""
    var selectedCategory: SoundCategory? = nil
    var showPremiumOnly: Bool = false

    // MARK: - Computed
    var filteredSounds: [SoundDTO] {
        var result = allSounds

        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter { $0.name.lowercased().contains(q) }
        }

        if showPremiumOnly {
            result = result.filter { $0.isPremium }
        }

        return result
    }

    var soundsByCategory: [SoundCategory: [SoundDTO]] {
        var dict: [SoundCategory: [SoundDTO]] = [:]
        for category in SoundCategory.allCases {
            let sounds = allSounds.filter { $0.category == category }
            if !sounds.isEmpty { dict[category] = sounds }
        }
        return dict
    }

    var freesSounds: [SoundDTO] { allSounds.filter { !$0.isPremium } }
    var premiumSounds: [SoundDTO] { allSounds.filter { $0.isPremium } }

    // MARK: - Singleton
    static let shared = SoundLibrary()

    private init() {
        load()
    }

    // MARK: - Load
    func load() {
        allSounds = Sound.makeLibrary()
        isLoaded = true
    }

    func sound(for id: String) -> SoundDTO? {
        allSounds.first { $0.id == id }
    }

    func sounds(for ids: [String]) -> [SoundDTO] {
        ids.compactMap { sound(for: $0) }
    }

    func sounds(in category: SoundCategory) -> [SoundDTO] {
        allSounds.filter { $0.category == category }
    }

    func resetFilters() {
        searchQuery = ""
        selectedCategory = nil
        showPremiumOnly = false
    }
}
