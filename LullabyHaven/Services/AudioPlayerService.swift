//
//  AudioPlayerService.swift
//  LullabyHaven
//
//  AVAudioEngine-based audio playback with synthesized noise generation
//  and background audio support.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Playback State
enum PlaybackState: Equatable {
    case idle
    case playing
    case paused
    case fadingOut
    case stopped
}

// MARK: - Active Sound Track
struct ActiveTrack: Identifiable {
    let id: String          // soundDTO.id
    let name: String
    var volume: Float       // 0.0 - 1.0
}

// MARK: - Audio Player Service
@MainActor
@Observable
final class AudioPlayerService {
    // MARK: - State
    private(set) var playbackState: PlaybackState = .idle
    private(set) var activeTracks: [ActiveTrack] = []
    private(set) var masterVolume: Float = 0.8

    // MARK: - Private Engine Components
    private var engine = AVAudioEngine()
    private var mixerNode = AVAudioMixerNode()
    private var sourceNodes: [String: AVAudioSourceNode] = [:]    // soundID -> node
    private var playerNodes: [String: AVAudioPlayerNode] = [:]    // soundID -> player (for files)
    private var trackMixers: [String: AVAudioMixerNode] = [:]     // soundID -> per-track mixer

    // Noise generators (pink noise filter state)
    private var noiseStates: [String: NoiseGeneratorState] = [:]

    // Fade
    private var fadeTimer: Timer?
    private var fadeStartVolume: Float = 0.8
    private var fadeDuration: TimeInterval = 30
    private var fadeElapsed: TimeInterval = 0

    // MARK: - Singleton
    static let shared = AudioPlayerService()

    private init() {
        setupAudioSession()
        setupEngine()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try session.setActive(true)
        } catch {
            print("[AudioPlayerService] Failed to configure audio session: \(error)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    private func setupEngine() {
        engine.attach(mixerNode)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: nil)
    }

    // MARK: - Public API

    /// Play a single sound (stops other sounds)
    func play(sound: SoundDTO) {
        stopAll(immediate: true)
        addTrack(sound: sound, volume: masterVolume)
        startEngineIfNeeded()
        playbackState = .playing
    }

    /// Add a sound to the current mix (premium)
    func addToMix(sound: SoundDTO, volume: Float = 0.7) {
        guard !activeTracks.contains(where: { $0.id == sound.id }) else { return }
        addTrack(sound: sound, volume: volume)
        startEngineIfNeeded()
        playbackState = .playing
    }

    /// Remove a sound from the current mix
    func removeFromMix(soundID: String) {
        removeTrack(soundID: soundID)
        if activeTracks.isEmpty { playbackState = .idle }
    }

    /// Set volume for a specific track
    func setTrackVolume(soundID: String, volume: Float) {
        if let idx = activeTracks.firstIndex(where: { $0.id == soundID }) {
            activeTracks[idx].volume = volume
        }
        trackMixers[soundID]?.outputVolume = volume
    }

    /// Set master volume
    func setMasterVolume(_ volume: Float) {
        masterVolume = volume
        mixerNode.outputVolume = volume
    }

    func pause() {
        guard playbackState == .playing || playbackState == .fadingOut else { return }
        engine.pause()
        playbackState = .paused
    }

    func resume() {
        guard playbackState == .paused else { return }
        startEngineIfNeeded()
        playbackState = .playing
    }

    func stopAll(immediate: Bool = false) {
        fadeTimer?.invalidate()
        fadeTimer = nil
        if engine.isRunning { engine.stop() }
        tearDownAllNodes()
        activeTracks.removeAll()
        playbackState = .idle
    }

    // MARK: - Fade Out
    func startFadeOut(over duration: TimeInterval) {
        guard playbackState == .playing else { return }
        playbackState = .fadingOut
        fadeStartVolume = masterVolume
        fadeDuration = duration
        fadeElapsed = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fadeStep()
            }
        }
        RunLoop.main.add(fadeTimer!, forMode: .common)
    }

    private func fadeStep() {
        fadeElapsed += 0.1
        let fraction = Float(min(fadeElapsed / fadeDuration, 1.0))
        let newVol = fadeStartVolume * (1.0 - fraction)
        mixerNode.outputVolume = max(newVol, 0)

        if fraction >= 1.0 {
            fadeTimer?.invalidate()
            fadeTimer = nil
            stopAll(immediate: true)
        }
    }

    // MARK: - Private Helpers

    private func addTrack(sound: SoundDTO, volume: Float) {
        let trackMixer = AVAudioMixerNode()
        trackMixer.outputVolume = volume
        engine.attach(trackMixer)
        engine.connect(trackMixer, to: mixerNode, format: nil)
        trackMixers[sound.id] = trackMixer

        switch sound.type {
        case .generated:
            addGeneratedSource(sound: sound, mixer: trackMixer)
        case .lullaby, .bundled:
            addFileSource(sound: sound, mixer: trackMixer)
        }

        activeTracks.append(ActiveTrack(id: sound.id, name: sound.name, volume: volume))
    }

    private func addGeneratedSource(sound: SoundDTO, mixer: AVAudioMixerNode) {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        var state = NoiseGeneratorState()
        state.noiseType = sound.noiseType ?? "white"
        state.heartbeatRate = sound.baseFrequency > 0 ? sound.baseFrequency : 0
        state.sampleRate = sampleRate
        noiseStates[sound.id] = state

        let sid = sound.id
        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard var state = self.noiseStates[sid] else { return noErr }

            for frame in 0..<Int(frameCount) {
                let sample = state.nextSample()
                for buffer in ablPointer {
                    guard let buf = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    buf[frame] = sample
                }
            }
            self.noiseStates[sid] = state
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: mixer, format: format)
        sourceNodes[sound.id] = sourceNode
    }

    private func addFileSource(sound: SoundDTO, mixer: AVAudioMixerNode) {
        // For lullabies/bundled audio: use AVAudioPlayerNode with a silent buffer
        // (actual audio files would be added to bundle in production)
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: mixer, format: format)

        // Try to load from bundle, fall back to silence
        if let url = Bundle.main.url(forResource: sound.id, withExtension: "m4a") {
            do {
                let file = try AVAudioFile(forReading: url)
                playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            } catch {
                scheduleSilentBuffer(playerNode: playerNode, format: format)
            }
        } else {
            scheduleSilentBuffer(playerNode: playerNode, format: format)
        }

        playerNode.play()
        playerNodes[sound.id] = playerNode
    }

    private func scheduleSilentBuffer(playerNode: AVAudioPlayerNode, format: AVAudioFormat) {
        let bufferSize = AVAudioFrameCount(44100 * 4)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else { return }
        buffer.frameLength = bufferSize
        // Buffer is silent (zeroed) by default
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
    }

    private func removeTrack(soundID: String) {
        if let src = sourceNodes[soundID] {
            engine.detach(src)
            sourceNodes[soundID] = nil
        }
        if let player = playerNodes[soundID] {
            player.stop()
            engine.detach(player)
            playerNodes[soundID] = nil
        }
        if let mixer = trackMixers[soundID] {
            engine.detach(mixer)
            trackMixers[soundID] = nil
        }
        noiseStates[soundID] = nil
        activeTracks.removeAll { $0.id == soundID }
    }

    private func tearDownAllNodes() {
        for (id, node) in sourceNodes { engine.detach(node); sourceNodes[id] = nil }
        for (id, node) in playerNodes { node.stop(); engine.detach(node); playerNodes[id] = nil }
        for (id, node) in trackMixers { engine.detach(node); trackMixers[id] = nil }
        noiseStates.removeAll()
        sourceNodes.removeAll()
        playerNodes.removeAll()
        trackMixers.removeAll()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        // Reconnect mixer if needed after stop
        if engine.inputConnectionPoint(for: engine.mainMixerNode, inputBus: 0) == nil {
            engine.connect(mixerNode, to: engine.mainMixerNode, format: nil)
        }
        do {
            try engine.start()
            mixerNode.outputVolume = masterVolume
        } catch {
            print("[AudioPlayerService] Engine start failed: \(error)")
        }
    }

    // MARK: - Interruption Handling
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            if playbackState == .playing { pause() }
        } else if type == .ended {
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) { resume() }
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            // Headphones removed — pause
            if playbackState == .playing { pause() }
        }
    }
}

// MARK: - Noise Generator State
struct NoiseGeneratorState {
    var noiseType: String = "white"
    var heartbeatRate: Double = 0    // beats per second (0 = no heartbeat)
    var sampleRate: Double = 44100

    // Pink noise filter state (Paul Kellet's algorithm)
    var b0: Float = 0, b1: Float = 0, b2: Float = 0
    var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0

    // Brown noise integration state
    var brownLast: Float = 0

    // Heartbeat envelope state
    var heartbeatPhase: Double = 0

    mutating func nextSample() -> Float {
        var white = Float.random(in: -1...1)
        var sample: Float

        switch noiseType {
        case "white":
            sample = white * 0.5

        case "pink":
            // Pink noise via Paul Kellet's method
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            sample = pink * 0.11

        case "brown":
            white = Float.random(in: -1...1) * 0.02
            brownLast = (brownLast + white) * 0.998
            brownLast = max(-1, min(1, brownLast))
            sample = brownLast * 3.5

        case "rain":
            // Rain = pink noise + amplitude modulation
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink2 = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            let mod = Float(0.7 + 0.3 * sin(heartbeatPhase * 0.001))
            sample = pink2 * 0.11 * mod

        case "heartbeat":
            // Brown noise base + heartbeat pulse
            white = Float.random(in: -1...1) * 0.01
            brownLast = (brownLast + white) * 0.998
            brownLast = max(-1, min(1, brownLast))
            var hbSample: Float = brownLast * 1.5

            // Add heartbeat "lub-dub" pulse
            let rate = heartbeatRate > 0 ? heartbeatRate : 1.2
            heartbeatPhase += rate / sampleRate
            if heartbeatPhase >= 1.0 { heartbeatPhase -= 1.0 }

            // First beat (lub)
            let lub = Float(exp(-50.0 * pow(heartbeatPhase - 0.1, 2)))
            // Second beat (dub)
            let dub = Float(exp(-80.0 * pow(heartbeatPhase - 0.2, 2))) * 0.6
            hbSample += (lub + dub) * 0.4
            sample = hbSample

        default:
            sample = white * 0.5
        }

        return sample
    }
}
