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
    @State private var voiceService = VoiceGenerationService.shared
    @State private var showSoundPicker = false
    @State private var showSaveMixAlert = false
    @State private var showPaywall = false
    @State private var showVoiceRecording = false
    @State private var mixNameInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // My Voice section (always visible)
                    myVoiceSection

                    if storeKit.isPremium {
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
                    } else {
                        premiumGate
                    }
                }
                .padding()
                .padding(.bottom, 60)
            }
            .background(Color.lhBackground)
            .navigationTitle("Mixer")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            mixerVM.setModelContext(modelContext)
            playerVM.setModelContext(modelContext)
            Task { await voiceService.loadVoices() }
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
        .fullScreenCover(isPresented: $showVoiceRecording) {
            VoiceRecordingView {
                Task { await voiceService.loadVoices() }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - My Voice
    private var myVoiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section: Standard Voices
            VStack(alignment: .leading, spacing: 10) {
                Text("Read Lullabies Aloud")
                    .font(.headline)
                    .foregroundStyle(Color.lhPrimary)

                Text("Choose a voice to read lullabies to your little one.")
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)

                ForEach(StandardVoice.all) { stdVoice in
                    NavigationLink {
                        LullabyGeneratorView(voice: .standard(stdVoice))
                    } label: {
                        voiceRow(
                            icon: "speaker.wave.2.fill",
                            name: stdVoice.name,
                            detail: stdVoice.style,
                            trailing: "Listen"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().padding(.vertical, 4)

            // Section: Record Your Voice
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Voice")
                    .font(.headline)
                    .foregroundStyle(Color.lhPrimary)

                Text("Record your voice and hear lullabies read as you.")
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)

                Button { showVoiceRecording = true } label: {
                    HStack(spacing: LHSpacing.sm) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Record My Voice")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.lhAccent)
                    .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))
                }

                if voiceService.isLoading {
                    HStack {
                        Spacer()
                        ProgressView().tint(Color.lhAccent)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                ForEach(voiceService.voices) { voice in
                    NavigationLink {
                        LullabyGeneratorView(voice: .cloned(voice))
                    } label: {
                        voiceRow(
                            icon: "waveform.and.mic",
                            name: voice.name,
                            detail: voice.durationSec.map { "\(Int($0))s recorded" } ?? "Your voice",
                            trailing: "Listen"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func voiceRow(icon: String, name: String, detail: String, trailing: String) -> some View {
        HStack(spacing: LHSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(Color.lhAccent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.lhPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)
            }
            Spacer()
            Text(trailing)
                .font(.caption.bold())
                .foregroundStyle(Color.lhAccent)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.lhSecondary)
        }
        .padding(LHSpacing.sm)
        .background(Color.lhBackground)
        .clipShape(RoundedRectangle(cornerRadius: LHRadius.sm))
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
