//
//  HomeView.swift
//  LullabyHaven
//
//  Main home tab with featured sounds, currently playing, and quick access
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit
    @State private var playerVM = PlayerViewModel()
    @State private var showPaywall = false
    @State private var showNightMode = false

    @Query(sort: \FavoriteSound.sortOrder) private var favorites: [FavoriteSound]

    let library = SoundLibrary.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Currently Playing Mini Player
                    if playerVM.isPlaying || playerVM.currentSound != nil {
                        miniPlayer
                    }

                    // Quick Start – Free Sounds
                    quickStartSection

                    // Favorites
                    if !favorites.isEmpty {
                        favoritesSection
                    }

                    // Featured Categories
                    featuredCategories
                }
                .padding(.bottom, 100)
            }
            .background(Color.lhBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(Color.lhAccent)
                        Text("Lullaby Haven")
                            .font(.headline)
                            .foregroundStyle(Color.lhPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNightMode = true
                    } label: {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(Color.lhAccent)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !storeKit.isPremium {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Premium", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.lhGold)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .fullScreenCover(isPresented: $showNightMode) { NightModeView(playerVM: playerVM) }
        .onAppear {
            playerVM.setModelContext(modelContext)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Soothing Sounds for Baby")
                .font(.title2.bold())
                .foregroundStyle(Color.lhPrimary)
            Text("Tap a sound to start playing")
                .font(.subheadline)
                .foregroundStyle(Color.lhSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Mini Player
    private var miniPlayer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Sound icon
                ZStack {
                    Circle()
                        .fill(Color.lhAccent.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: playerVM.currentSound?.iconName ?? "waveform")
                        .foregroundStyle(Color.lhAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerVM.currentSound?.name ?? "Mix Playing")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.lhPrimary)
                    Text(playerVM.isPlaying ? "Playing" : "Paused")
                        .font(.caption)
                        .foregroundStyle(Color.lhSecondary)
                }
                Spacer()
                // Timer badge
                if playerVM.isTimerActive {
                    Text(playerVM.timerRemaining)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.lhAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.lhAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
                Button {
                    playerVM.togglePlayback()
                } label: {
                    Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.lhAccent)
                }
                Button {
                    playerVM.stopPlayback()
                } label: {
                    Image(systemName: "stop.circle")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.lhSecondary)
                }
            }
            .padding()
        }
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Quick Start
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Start", subtitle: "Free sounds to get started")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(library.freesSounds.prefix(6)) { sound in
                    SoundTileButton(sound: sound, isPlaying: playerVM.currentSound?.id == sound.id && playerVM.isPlaying) {
                        playerVM.play(sound: sound)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Favorites
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Favorites", subtitle: "Your saved sounds")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favorites.prefix(8)) { fav in
                        if let sound = library.sound(for: fav.soundID) {
                            SoundChipButton(sound: sound, isPlaying: playerVM.currentSound?.id == sound.id && playerVM.isPlaying) {
                                if sound.isPremium && !storeKit.isPremium {
                                    showPaywall = true
                                } else {
                                    playerVM.play(sound: sound)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Featured Categories
    private var featuredCategories: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Browse by Category", subtitle: nil)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SoundCategory.allCases, id: \.self) { category in
                    NavigationLink {
                        SoundLibraryView(initialCategory: category)
                    } label: {
                        CategoryCard(category: category)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.lhPrimary)
            if let sub = subtitle {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)
            }
        }
        .padding(.horizontal)
    }
}

struct SoundTileButton: View {
    let sound: SoundDTO
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.lhAccent : Color.lhAccent.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: sound.iconName)
                        .font(.title3)
                        .foregroundStyle(isPlaying ? .white : Color.lhAccent)
                }
                Text(sound.name)
                    .font(.caption2)
                    .foregroundStyle(Color.lhPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPlaying ? Color.lhAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SoundChipButton: View {
    let sound: SoundDTO
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: sound.iconName)
                    .font(.caption)
                    .foregroundStyle(isPlaying ? .white : Color.lhAccent)
                Text(sound.name)
                    .font(.caption.bold())
                    .foregroundStyle(isPlaying ? .white : Color.lhPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isPlaying ? Color.lhAccent : Color.lhCard)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CategoryCard: View {
    let category: SoundCategory

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.lhAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: category.iconName)
                    .foregroundStyle(Color.lhAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.lhPrimary)
                if category.isPremium {
                    Text("Premium")
                        .font(.caption2)
                        .foregroundStyle(Color.lhGold)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.lhSecondary)
        }
        .padding(12)
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
