//
//  AudioRecorderService.swift
//  LullabyHaven
//
//  Handles microphone recording for voice capture.
//

import Foundation
import AVFoundation

@MainActor
@Observable
final class AudioRecorderService {
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?

    private var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("voice_recording.wav")
    }

    // MARK: - Start Recording

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        recordingDuration = 0
        audioLevel = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.recordingDuration += 0.1
            }
        }

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let db = recorder.averagePower(forChannel: 0)
                // Normalize from dB (-160 to 0) to 0-1 range
                let normalized = max(0, min(1, (db + 50) / 50))
                self.audioLevel = normalized
            }
        }
    }

    // MARK: - Stop Recording

    func stopRecording() -> URL {
        audioRecorder?.stop()
        timer?.invalidate()
        levelTimer?.invalidate()
        timer = nil
        levelTimer = nil
        isRecording = false

        // Restore audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        return recordingURL
    }

    // MARK: - Get Audio Data

    func getAudioData() -> Data? {
        try? Data(contentsOf: recordingURL)
    }

    // MARK: - Cleanup

    func cleanup() {
        try? FileManager.default.removeItem(at: recordingURL)
    }
}
