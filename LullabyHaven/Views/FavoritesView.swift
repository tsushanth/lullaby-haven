//
//  FavoritesView.swift
//  LullabyHaven
//
//  Displays and manages favorited sounds
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit

    @Query(sort: \FavoriteSound.sortOrder) private var favorites: [FavoriteSound]
    @State private var playerVM = PlayerViewModel()
    @State private var selectedSound: SoundDTO?
    @State private var showPaywall = false

    let library = SoundLibrary.shared

    var favoriteSounds: [SoundDTO] {
        favorites.compactMap { library.sound(for: $0.soundID) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    soundGrid
                }
            }
            .background(Color.lhBackground)
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedSound) { sound in
            SoundPlayerView(sound: sound, playerVM: playerVM)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { playerVM.setModelContext(modelContext) }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 56))
                .foregroundStyle(Color.lhSecondary)
            Text("No Favorites Yet")
                .font(.title2.bold())
                .foregroundStyle(Color.lhPrimary)
            Text("Tap the heart icon on any sound\nto save it here for quick access.")
                .font(.subheadline)
                .foregroundStyle(Color.lhSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var soundGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(favoriteSounds) { sound in
                    FavoriteSoundCard(
                        sound: sound,
                        isPlaying: playerVM.currentSound?.id == sound.id && playerVM.isPlaying
                    ) {
                        if sound.isPremium && !storeKit.isPremium {
                            showPaywall = true
                        } else {
                            selectedSound = sound
                        }
                    } onRemove: {
                        removeFavorite(soundID: sound.id)
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
    }

    private func removeFavorite(soundID: String) {
        if let fav = favorites.first(where: { $0.soundID == soundID }) {
            modelContext.delete(fav)
            try? modelContext.save()
        }
    }
}

// MARK: - Favorite Sound Card
struct FavoriteSoundCard: View {
    let sound: SoundDTO
    let isPlaying: Bool
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(isPlaying ? Color.lhAccent : Color.lhAccent.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: sound.iconName)
                            .font(.title2)
                            .foregroundStyle(isPlaying ? .white : Color.lhAccent)
                    }
                    Button(action: onRemove) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                            .padding(4)
                            .background(.white)
                            .clipShape(Circle())
                    }
                }

                VStack(spacing: 3) {
                    Text(sound.name)
                        .font(.caption.bold())
                        .foregroundStyle(Color.lhPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(sound.category.rawValue)
                        .font(.caption2)
                        .foregroundStyle(Color.lhSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPlaying ? Color.lhAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
