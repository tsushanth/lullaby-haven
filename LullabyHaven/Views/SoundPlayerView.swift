//
//  SoundPlayerView.swift
//  LullabyHaven
//
//  Full-screen sound player with volume, timer, and controls
//

import SwiftUI
import SwiftData

struct SoundPlayerView: View {
    let sound: SoundDTO
    @Bindable var playerVM: PlayerViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit

    @Query(sort: \FavoriteSound.sortOrder) private var favorites: [FavoriteSound]

    @State private var showTimer = false
    @State private var showPaywall = false
    @State private var timerVM = TimerViewModel()

    var isFavorite: Bool { playerVM.isFavorite(soundID: sound.id, favorites: favorites) }
    var isThisPlaying: Bool { playerVM.currentSound?.id == sound.id && playerVM.isPlaying }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.lhBackground, Color.lhAccent.opacity(0.15)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Sound artwork
                    soundArtwork

                    // Sound name
                    VStack(spacing: 6) {
                        Text(sound.name)
                            .font(.title2.bold())
                            .foregroundStyle(Color.lhPrimary)
                        Text(sound.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(Color.lhSecondary)
                    }

                    // Volume slider
                    volumeControl

                    // Playback controls
                    playbackControls

                    // Timer section
                    timerSection

                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Color.lhPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        _ = playerVM.toggleFavorite(soundID: sound.id, favorites: favorites)
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : Color.lhSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { playerVM.setModelContext(modelContext) }
    }

    // MARK: - Artwork
    private var soundArtwork: some View {
        ZStack {
            Circle()
                .fill(Color.lhAccent.opacity(0.1))
                .frame(width: 180, height: 180)
            Circle()
                .fill(Color.lhAccent.opacity(0.2))
                .frame(width: 140, height: 140)
            Circle()
                .fill(Color.lhAccent.opacity(isThisPlaying ? 0.35 : 0.3))
                .frame(width: 100, height: 100)
                .scaleEffect(isThisPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isThisPlaying)
            Image(systemName: sound.iconName)
                .font(.system(size: 44))
                .foregroundStyle(Color.lhAccent)
        }
    }

    // MARK: - Volume
    private var volumeControl: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(Color.lhSecondary)
                Slider(value: Binding(
                    get: { Double(playerVM.masterVolume) },
                    set: { playerVM.masterVolume = Float($0) }
                ), in: 0...1)
                .tint(Color.lhAccent)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(Color.lhSecondary)
            }
        }
    }

    // MARK: - Controls
    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Mixer button (premium)
            Button {
                if storeKit.isPremium {
                    // add to mix
                    playerVM.addToMix(sound: sound)
                } else {
                    showPaywall = true
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(storeKit.isPremium ? Color.lhAccent : Color.lhSecondary)
                    Text("Mix")
                        .font(.caption2)
                        .foregroundStyle(Color.lhSecondary)
                }
            }

            // Play/Pause
            Button {
                if isThisPlaying {
                    playerVM.pausePlayback()
                } else {
                    playerVM.play(sound: sound)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.lhAccent)
                        .frame(width: 72, height: 72)
                    Image(systemName: isThisPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: Color.lhAccent.opacity(0.4), radius: 12)

            // Timer button
            Button {
                showTimer = true
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Image(systemName: "timer")
                            .font(.title2)
                            .foregroundStyle(playerVM.isTimerActive ? Color.lhAccent : Color.lhSecondary)
                        if playerVM.isTimerActive {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                                .offset(x: 10, y: -10)
                        }
                    }
                    Text(playerVM.isTimerActive ? playerVM.timerRemaining : "Timer")
                        .font(.caption2)
                        .foregroundStyle(playerVM.isTimerActive ? Color.lhAccent : Color.lhSecondary)
                        .monospacedDigit()
                }
            }
        }
        .sheet(isPresented: $showTimer) {
            TimerView(timerVM: timerVM, playerVM: playerVM)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        Group {
            if playerVM.isTimerActive {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.lhAccent)
                        Text("Timer: \(playerVM.timerRemaining) remaining")
                            .font(.subheadline)
                            .foregroundStyle(Color.lhPrimary)
                        Spacer()
                        Button("Cancel") {
                            playerVM.cancelTimer()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    }
                    ProgressView(value: playerVM.timerProgress)
                        .tint(Color.lhAccent)
                }
                .padding()
                .background(Color.lhCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
