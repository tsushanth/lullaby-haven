//
//  LullabyGeneratorView.swift
//  LullabyHaven
//
//  Generate lullabies read aloud in a chosen voice
//

import SwiftUI
import AVFoundation

struct LullabyText: Identifiable {
    let id: String
    let title: String
    let lyrics: String
    let iconName: String
}

private let lullabyTexts: [LullabyText] = [
    LullabyText(
        id: "twinkle",
        title: "Twinkle Twinkle Little Star",
        lyrics: "Twinkle, twinkle, little star, how I wonder what you are. Up above the world so high, like a diamond in the sky. Twinkle, twinkle, little star, how I wonder what you are.",
        iconName: "star.fill"
    ),
    LullabyText(
        id: "hush",
        title: "Hush Little Baby",
        lyrics: "Hush little baby, don't say a word, Mama's gonna buy you a mockingbird. And if that mockingbird won't sing, Mama's gonna buy you a diamond ring.",
        iconName: "bird.fill"
    ),
    LullabyText(
        id: "rockabye",
        title: "Rock-a-bye Baby",
        lyrics: "Rock-a-bye baby, on the treetop. When the wind blows, the cradle will rock. When the bough breaks, the cradle will fall, and down will come baby, cradle and all.",
        iconName: "leaf.fill"
    ),
    LullabyText(
        id: "brahms",
        title: "Brahms' Lullaby",
        lyrics: "Lullaby and good night, with roses bedight, with lilies bedecked, is baby's sweet bed. Lay thee down now and rest, may thy slumber be blessed. Lay thee down now and rest, may thy slumber be blessed.",
        iconName: "moon.fill"
    ),
    LullabyText(
        id: "golden",
        title: "Golden Slumbers",
        lyrics: "Golden slumbers kiss your eyes, smiles await you when you rise. Sleep, pretty baby, do not cry, and I will sing a lullaby.",
        iconName: "sun.max.fill"
    ),
    LullabyText(
        id: "goodnight",
        title: "Good Night",
        lyrics: "Good night, sleep tight, don't let the bedbugs bite. Close your eyes and dream away, tomorrow is another day. The stars are shining bright above, surrounding you with all my love.",
        iconName: "sparkles"
    ),
]

// MARK: - Voice Selection (wraps both standard and cloned)

enum LullabyVoice: Identifiable, Hashable {
    case standard(StandardVoice)
    case cloned(SavedVoice)

    var id: String {
        switch self {
        case .standard(let v): return "std_\(v.id)"
        case .cloned(let v): return "cln_\(v.id)"
        }
    }

    var name: String {
        switch self {
        case .standard(let v): return v.name
        case .cloned(let v): return v.name
        }
    }

    var subtitle: String {
        switch self {
        case .standard(let v): return v.style
        case .cloned(let v):
            if let d = v.durationSec { return "Your voice (\(Int(d))s)" }
            return "Your voice"
        }
    }

    var voiceId: String {
        switch self {
        case .standard(let v): return v.id
        case .cloned(let v): return v.id
        }
    }

    var iconName: String {
        switch self {
        case .standard: return "speaker.wave.2.fill"
        case .cloned: return "waveform.and.mic"
        }
    }
}

// MARK: - View Model

@MainActor
@Observable
final class LullabyGeneratorViewModel {
    let voice: LullabyVoice
    private let service = VoiceGenerationService.shared

    var generatingID: String?
    var playingID: String?
    var error: String?

    private var audioPlayer: AVAudioPlayer?

    init(voice: LullabyVoice) {
        self.voice = voice
    }

    private var pollTimer: Timer?

    func generate(lullaby: LullabyText) async {
        if service.hasCachedAudio(voiceId: voice.voiceId, lullabyId: lullaby.id) {
            play(lullabyId: lullaby.id)
            return
        }

        error = nil

        switch voice {
        case .standard(let stdVoice):
            // Standard voices are fast — wait synchronously
            generatingID = lullaby.id
            do {
                let audioData = try await service.synthesizeStandard(
                    text: lullaby.lyrics,
                    voiceId: stdVoice.id
                )
                try service.saveCachedAudio(audioData, voiceId: voice.voiceId, lullabyId: lullaby.id)
                generatingID = nil
                play(lullabyId: lullaby.id)
            } catch {
                generatingID = nil
                self.error = "Generation failed: \(error.localizedDescription)"
            }

        case .cloned(let savedVoice):
            // Cloned voices are slow on CPU — fire and forget, poll for result
            guard let voiceURL = savedVoice.audioUrl else {
                error = "Voice audio not available"
                return
            }
            service.submitClonedGeneration(
                text: lullaby.lyrics,
                voiceId: savedVoice.id,
                voiceURL: voiceURL,
                lullabyId: lullaby.id
            )
            startPolling(lullabyId: lullaby.id)
        }
    }

    private func startPolling(lullabyId: String) {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.service.hasCachedAudio(voiceId: self.voice.voiceId, lullabyId: lullabyId) {
                    self.pollTimer?.invalidate()
                    self.pollTimer = nil
                    self.play(lullabyId: lullabyId)
                }
            }
        }
    }

    func play(lullabyId: String) {
        stop()
        guard let data = service.loadCachedAudio(voiceId: voice.voiceId, lullabyId: lullabyId) else { return }
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            playingID = lullabyId
        } catch {
            self.error = "Playback failed"
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingID = nil
    }

    func hasCached(_ lullabyId: String) -> Bool {
        service.hasCachedAudio(voiceId: voice.voiceId, lullabyId: lullabyId)
    }

    func isPending(_ lullabyId: String) -> Bool {
        service.isGenerationPending(voiceId: voice.voiceId, lullabyId: lullabyId)
    }

    func cleanup() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

// MARK: - Lullaby Generator View

struct LullabyGeneratorView: View {
    let voice: LullabyVoice
    @State private var vm: LullabyGeneratorViewModel

    init(voice: LullabyVoice) {
        self.voice = voice
        self._vm = State(initialValue: LullabyGeneratorViewModel(voice: voice))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LHSpacing.lg) {
                // Header
                VStack(spacing: LHSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.lhAccent.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: voice.iconName)
                            .font(.system(size: 32))
                            .foregroundStyle(Color.lhAccent)
                    }

                    Text("Lullabies as \(voice.name)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.lhPrimary)

                    Text("Tap a lullaby to hear it read aloud")
                        .font(.subheadline)
                        .foregroundStyle(Color.lhSecondary)

                    if case .cloned = voice {
                        Text("Voice cloning runs on CPU — first generation may take up to a minute.")
                            .font(.caption)
                            .foregroundStyle(Color.lhSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, LHSpacing.md)

                if let error = vm.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Lullaby list
                ForEach(lullabyTexts) { lullaby in
                    LullabyCard(
                        lullaby: lullaby,
                        isGenerating: vm.generatingID == lullaby.id,
                        isPending: vm.isPending(lullaby.id),
                        isPlaying: vm.playingID == lullaby.id,
                        isCached: vm.hasCached(lullaby.id)
                    ) {
                        if vm.playingID == lullaby.id {
                            vm.stop()
                        } else if vm.hasCached(lullaby.id) {
                            vm.play(lullabyId: lullaby.id)
                        } else {
                            Task { await vm.generate(lullaby: lullaby) }
                        }
                    }
                }
            }
            .padding(.horizontal, LHSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(Color.lhBackground)
        .navigationTitle("Read Lullaby")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { vm.stop(); vm.cleanup() }
    }
}

// MARK: - Lullaby Card

struct LullabyCard: View {
    let lullaby: LullabyText
    let isGenerating: Bool
    let isPending: Bool
    let isPlaying: Bool
    let isCached: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LHSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.lhAccent : Color.lhAccent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: lullaby.iconName)
                        .font(.title3)
                        .foregroundStyle(isPlaying ? .white : Color.lhAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(lullaby.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.lhPrimary)

                    if isPending {
                        Text("Generating in background — stay on this screen...")
                            .font(.caption)
                            .foregroundStyle(Color.lhAccent)
                    } else {
                        Text(lullaby.lyrics.prefix(60) + "...")
                            .font(.caption)
                            .foregroundStyle(Color.lhSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if isGenerating || isPending {
                    ProgressView()
                        .tint(Color.lhAccent)
                } else if isPlaying {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.lhAccent)
                } else if isCached {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.lhAccent)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                        .foregroundStyle(Color.lhAccent)
                }
            }
            .padding(LHSpacing.md)
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(isGenerating || isPending)
    }
}
