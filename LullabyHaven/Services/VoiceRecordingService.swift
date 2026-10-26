// VoiceRecordingService.swift
// LullabyHaven
//
// Records a short parent voice sample using the device microphone.
// Output is a WAV file suitable for voice profile creation.
//

import Foundation
import AVFoundation

// MARK: - Recording State

enum RecordingState: Equatable {
    case idle
    case requestingPermission
    case ready          // permission granted, not yet recording
    case recording
    case processing
    case done(URL)
    case failed(String)
}

// MARK: - Service

@MainActor
@Observable
final class VoiceRecordingService: NSObject {

    // MARK: - State

    private(set) var state: RecordingState = .idle
    private(set) var elapsed: TimeInterval = 0

    // MARK: - Private

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var outputURL: URL?

    // MARK: - Public API

    /// Request microphone access and prepare for recording.
    func prepare() async {
        state = .requestingPermission
        let granted = await AVAudioApplication.requestRecordPermission()
        state = granted ? .ready : .failed("Microphone access is required. Please enable it in Settings.")
    }

    /// Begin recording. Call `prepare()` first.
    func startRecording() throws {
        guard case .ready = state else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("lh_voice_sample_\(UUID().uuidString).wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = false
            recorder?.record()

            outputURL = url
            elapsed = 0
            state = .recording

            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.elapsed += 0.5
                }
            }
        } catch {
            state = .failed("Could not start recording: \(error.localizedDescription)")
        }
    }

    /// Stop recording and return the audio file URL.
    @discardableResult
    func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil

        guard let url = outputURL else {
            state = .failed("No recording found")
            return nil
        }

        state = .done(url)
        return url
    }

    /// Reset back to ready state (keeps permission).
    func reset() {
        stopRecording()
        outputURL = nil
        elapsed = 0
        state = .ready
    }

    // MARK: - Helpers

    var isRecording: Bool {
        if case .recording = state { return true }
        return false
    }

    var recordedURL: URL? {
        if case .done(let url) = state { return url }
        return nil
    }

    var formattedElapsed: String {
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                self.state = .failed("Recording ended unexpectedly")
            }
        }
    }
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.state = .failed(error?.localizedDescription ?? "Encoding error")
        }
    }
}
