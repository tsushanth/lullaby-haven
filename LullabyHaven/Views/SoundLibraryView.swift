//
//  SoundLibraryView.swift
//  LullabyHaven
//
//  Full sound browser with search and category filter
//

import SwiftUI
import SwiftData

struct SoundLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit
    @State private var vm = LibraryViewModel()
    @State private var playerVM = PlayerViewModel()
    @State private var showPaywall = false
    @State private var showPlayer = false
    @State private var selectedSound: SoundDTO?

    @Query(sort: \FavoriteSound.sortOrder) private var favorites: [FavoriteSound]

    var initialCategory: SoundCategory? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Category filter
            categoryFilter

            // Sound list
            if vm.filteredSounds.isEmpty {
                emptyState
            } else {
                soundList
            }
        }
        .background(Color.lhBackground)
        .navigationTitle("Sound Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !storeKit.isPremium {
                    Button { showPaywall = true } label: {
                        Label("Premium", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.lhGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $selectedSound) { sound in
            SoundPlayerView(sound: sound, playerVM: playerVM)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            vm.selectedCategory = initialCategory
            playerVM.setModelContext(modelContext)
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.lhSecondary)
            TextField("Search sounds...", text: $vm.searchQuery)
                .foregroundStyle(Color.lhPrimary)
            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.lhSecondary)
                }
            }
        }
        .padding(10)
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(title: "All", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(vm.categories, id: \.self) { cat in
                    CategoryChip(
                        title: cat.rawValue,
                        isSelected: vm.selectedCategory == cat,
                        isPremiumOnly: cat.isPremium
                    ) {
                        vm.selectedCategory = vm.selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Sound List
    private var soundList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(vm.filteredSounds) { sound in
                    SoundRow(
                        sound: sound,
                        isPlaying: playerVM.currentSound?.id == sound.id && playerVM.isPlaying,
                        isFavorite: playerVM.isFavorite(soundID: sound.id, favorites: favorites),
                        isPremiumUser: storeKit.isPremium
                    ) {
                        handleSoundTap(sound)
                    } onFavorite: {
                        _ = playerVM.toggleFavorite(soundID: sound.id, favorites: favorites)
                    }
                    Divider().padding(.leading, 72)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundStyle(Color.lhSecondary)
            Text("No sounds found")
                .font(.headline)
                .foregroundStyle(Color.lhPrimary)
            Button("Clear Filters") { vm.resetFilters() }
                .buttonStyle(.borderedProminent)
                .tint(Color.lhAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleSoundTap(_ sound: SoundDTO) {
        if sound.isPremium && !storeKit.isPremium {
            showPaywall = true
        } else {
            selectedSound = sound
        }
    }
}

// MARK: - Sound Row
struct SoundRow: View {
    let sound: SoundDTO
    let isPlaying: Bool
    let isFavorite: Bool
    let isPremiumUser: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isPlaying ? Color.lhAccent : Color.lhAccent.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: sound.iconName)
                        .foregroundStyle(isPlaying ? .white : Color.lhAccent)
                    if isPlaying {
                        // Animated indicator
                        WaveformIndicator()
                            .frame(width: 20, height: 10)
                            .offset(y: 16)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(sound.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.lhPrimary)
                        if sound.isPremium {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.lhGold)
                        }
                    }
                    Text(sound.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(Color.lhSecondary)
                }

                Spacer()

                // Favorite button
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : Color.lhSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(isPlaying ? Color.lhAccent.opacity(0.05) : Color.clear)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    var isPremiumOnly: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                if isPremiumOnly {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.lhGold)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color.lhAccent : Color.lhCard)
            .foregroundStyle(isSelected ? .white : Color.lhPrimary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Waveform Indicator
struct WaveformIndicator: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(.white)
                    .frame(width: 3, height: phase ? CGFloat([4,8,6,4][i]) : CGFloat([8,4,8,6][i]))
                    .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.1).repeatForever(autoreverses: true), value: phase)
            }
        }
        .onAppear { phase = true }
    }
}
