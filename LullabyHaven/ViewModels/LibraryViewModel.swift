//
//  LibraryViewModel.swift
//  LullabyHaven
//
//  ViewModel for the sound library browser
//

import Foundation
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    private let library = SoundLibrary.shared

    var searchQuery: String = "" {
        didSet { library.searchQuery = searchQuery }
    }
    var selectedCategory: SoundCategory? {
        didSet { library.selectedCategory = selectedCategory }
    }

    var filteredSounds: [SoundDTO] { library.filteredSounds }
    var allSounds: [SoundDTO] { library.allSounds }
    var soundsByCategory: [SoundCategory: [SoundDTO]] { library.soundsByCategory }
    var categories: [SoundCategory] { SoundCategory.allCases }

    var isSearching: Bool { !searchQuery.isEmpty }

    func resetFilters() {
        searchQuery = ""
        selectedCategory = nil
        library.resetFilters()
    }

    func sounds(in category: SoundCategory, isPremium: Bool) -> [SoundDTO] {
        library.sounds(in: category).filter { !$0.isPremium || isPremium }
    }

    func sound(for id: String) -> SoundDTO? {
        library.sound(for: id)
    }
}
