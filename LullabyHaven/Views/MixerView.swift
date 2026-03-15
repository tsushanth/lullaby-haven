//
//  MixerView.swift
//  LullabyHaven
//
//  Multi-sound mixer for premium users
//

import SwiftUI
import SwiftData

struct MixerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit

    @State private var mixerVM = MixerViewModel()
    @State private var playerVM = PlayerViewModel()
    @State private var showSoundPicker = false
    @State private var showSaveMixAlert = false
    @State private var showPaywall = false
    @State private var mixNameInput = ""

    var body: some View {
        NavigationStack {
            Group {
                if storeKit.isPremium {
                    mixerContent
                } else {
                    premiumGate
                }
            }
            .background(Color.lhBackground)
            .navigationTitle("Sound Mixer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            mixerVM.setModelContext(modelContext)
            playerVM.setModelContext(modelContext)
        }
        .alert("Save Mix", isPresented: $showSaveMixAlert) {
            TextField("Mix name", text: $mixNameInput)
            Button("Save") {
                mixerVM.mixName = mixNameInput.isEmpty ? "My Mix" : mixNameInput
                mixerVM.saveMix()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerSheet(mixerVM: mixerVM)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Mixer Content
    private var mixerContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active Tracks
                activeTracksSection

                // Add Sound
                if mixerVM.canAddMore {
                    addSoundButton
                }

                // Playback Controls
                playbackControls

                // Saved Mixes
                if !mixerVM.savedMixes.isEmpty {
                    savedMixesSection
                }
            }
            .padding()
            .padding(.bottom, 60)
        }
    }

    // MARK: - Active Tracks
    private var activeTracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Tracks (\(mixerVM.activeTracks.count)/5)")
                    .font(.headline)
                    .foregroundStyle(Color.lhPrimary)
                Spacer()
                if !mixerVM.activeTracks.isEmpty {
                    Button {
                        mixNameInput = "My Mix"
                        showSaveMixAlert = true
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.lhAccent)
                    .controlSize(.small)
                }
            }

            if mixerVM.activeTracks.isEmpty {
                emptyMixState
            } else {
                ForEach(mixerVM.activeTracks) { track in
                    MixTrackRow(
                        track: track,
                        sound: mixerVM.soundDTO(for: track.id)
                    ) { volume in
                        mixerVM.setVolume(for: track.id, volume: Float(volume))
                    } onRemove: {
                        mixerVM.removeSound(id: track.id)
                        playerVM.removeFromMix(soundID: track.id)
                    }
                }
            }
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyMixState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(Color.lhSecondary)
            Text("Add up to 5 sounds")
                .font(.subheadline)
                .foregroundStyle(Color.lhSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var addSoundButton: some View {
        Button {
            showSoundPicker = true
        } label: {
            Label("Add Sound to Mix", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.lhAccent)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Playback Controls
    private var playbackControls: some View {
        HStack(spacing: 16) {
            Button {
                if playerVM.isPlaying { playerVM.pausePlayback() } else { playerVM.resumePlayback() }
            } label: {
                Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(mixerVM.activeTracks.isEmpty ? Color.lhSecondary : Color.lhAccent)
            }
            .disabled(mixerVM.activeTracks.isEmpty)

            Button {
                playerVM.stopPlayback()
            } label: {
                Image(systemName: "stop.circle")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.lhSecondary)
            }
            .disabled(!playerVM.isPlaying)

            Spacer()

            // Master volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.1")
                    .foregroundStyle(Color.lhSecondary)
                Slider(value: Binding(
                    get: { Double(playerVM.masterVolume) },
                    set: { playerVM.masterVolume = Float($0) }
                ), in: 0...1)
                .tint(Color.lhAccent)
                .frame(width: 100)
                Image(systemName: "speaker.wave.3")
                    .foregroundStyle(Color.lhSecondary)
            }
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Saved Mixes
    private var savedMixesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Mixes")
                .font(.headline)
                .foregroundStyle(Color.lhPrimary)

            ForEach(mixerVM.savedMixes) { mix in
                SavedMixRow(mix: mix) {
                    mixerVM.loadMix(mix)
                } onDelete: {
                    mixerVM.deleteMix(mix)
                }
            }
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Premium Gate
    private var premiumGate: some View {
        VStack(spacing: 24) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 64))
                .foregroundStyle(Color.lhAccent)

            VStack(spacing: 8) {
                Text("Sound Mixer")
                    .font(.title.bold())
                    .foregroundStyle(Color.lhPrimary)
                Text("Mix up to 5 sounds simultaneously\nCreate your perfect sleep soundscape")
                    .font(.subheadline)
                    .foregroundStyle(Color.lhSecondary)
                    .multilineTextAlignment(.center)
            }

            Button { showPaywall = true } label: {
                Label("Unlock Premium", systemImage: "star.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lhGold)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Mix Track Row
struct MixTrackRow: View {
    let track: ActiveTrack
    let sound: SoundDTO?
    let onVolumeChange: (Double) -> Void
    let onRemove: () -> Void

    @State private var volume: Double = 0.7

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lhAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: sound?.iconName ?? "waveform")
                    .foregroundStyle(Color.lhAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sound?.name ?? track.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.lhPrimary)
                Slider(value: $volume, in: 0...1, onEditingChanged: { _ in
                    onVolumeChange(volume)
                })
                .tint(Color.lhAccent)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.lhSecondary)
            }
        }
        .onAppear { volume = Double(track.volume) }
    }
}

// MARK: - Saved Mix Row
struct SavedMixRow: View {
    let mix: SoundMix
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mix.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.lhPrimary)
                Text("\(mix.tracks.count) tracks")
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)
            }
            Spacer()
            Button("Load", action: onLoad)
                .font(.caption.bold())
                .buttonStyle(.bordered)
                .tint(Color.lhAccent)
                .controlSize(.small)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sound Picker Sheet
struct SoundPickerSheet: View {
    @Bindable var mixerVM: MixerViewModel
    @Environment(\.dismiss) private var dismiss
    let library = SoundLibrary.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundCategory.allCases, id: \.self) { cat in
                    Section(cat.rawValue) {
                        ForEach(library.sounds(in: cat)) { sound in
                            HStack {
                                Image(systemName: sound.iconName)
                                    .foregroundStyle(Color.lhAccent)
                                Text(sound.name)
                                    .foregroundStyle(Color.lhPrimary)
                                Spacer()
                                if mixerVM.activeTracks.contains(where: { $0.id == sound.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.lhAccent)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                mixerVM.addSound(sound)
                                if !mixerVM.canAddMore { dismiss() }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Sound")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
