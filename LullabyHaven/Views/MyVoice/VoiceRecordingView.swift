//
//  VoiceRecordingView.swift
//  LullabyHaven
//
//  Voice recording flow: record → upload → confirm
//

import SwiftUI

struct VoiceRecordingView: View {
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    @State private var recorder = AudioRecorderService()
    @State private var voiceService = VoiceGenerationService.shared
    @State private var voiceName = ""
    @State private var phase: RecordingPhase = .ready
    @State private var errorMessage: String?

    private let minimumDuration: TimeInterval = 15
    private let recommendedDuration: TimeInterval = 30

    enum RecordingPhase {
        case ready, recording, uploading, done
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.lhBackground, Color.lhAccent.opacity(0.1)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: LHSpacing.lg) {
                    switch phase {
                    case .ready:
                        readyPhase
                    case .recording:
                        recordingPhase
                    case .uploading:
                        uploadingPhase
                    case .done:
                        donePhase
                    }
                }
                .padding(.horizontal, LHSpacing.lg)
            }
            .navigationTitle("Record Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if recorder.isRecording {
                            _ = recorder.stopRecording()
                            recorder.cleanup()
                        }
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Ready Phase

    private var readyPhase: some View {
        VStack(spacing: LHSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(Color.lhAccent.opacity(0.2))
                    .frame(width: 100, height: 100)
                Image(systemName: "mic.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.lhAccent)
            }

            VStack(spacing: LHSpacing.sm) {
                Text("Record Your Voice")
                    .font(.lhTitle)
                    .foregroundStyle(Color.lhPrimary)

                Text("Read the passage below naturally for at least 15 seconds. A longer recording (30s+) gives better results.")
                    .font(.lhBody)
                    .foregroundStyle(Color.lhSecondary)
                    .multilineTextAlignment(.center)
            }

            // Sample text to read
            VStack(alignment: .leading, spacing: LHSpacing.sm) {
                Text("Read this aloud in a soft, soothing voice:")
                    .font(.lhCaption)
                    .foregroundStyle(Color.lhSecondary)

                Text("\"Hush now, little one, close your eyes. The moon is rising in the skies. Stars are twinkling, soft and bright, keeping watch throughout the night. Dream of meadows, flowers, and streams, floating gently through your dreams. Tomorrow brings a brand new day, filled with laughter, love, and play.\"")
                    .font(.lhBody)
                    .foregroundStyle(Color.lhPrimary)
                    .italic()
            }
            .padding(LHSpacing.md)
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))

            // Voice name
            TextField("Voice name (e.g., Mom, Dad)", text: $voiceName)
                .font(.lhBody)
                .padding(LHSpacing.md)
                .background(Color.lhCard)
                .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))
                .foregroundStyle(Color.lhPrimary)

            Button {
                startRecording()
            } label: {
                HStack {
                    Image(systemName: "record.circle")
                    Text("Start Recording")
                        .font(.lhHeadline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LHSpacing.md)
                .background(Color.red.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: LHRadius.lg))
            }
            .disabled(voiceName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(voiceName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

            if let error = errorMessage {
                Text(error)
                    .font(.lhCaption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }

    // MARK: - Recording Phase

    private var recordingPhase: some View {
        VStack(spacing: LHSpacing.md) {
            // Script to read while recording
            VStack(alignment: .leading, spacing: LHSpacing.xs) {
                Text("Read aloud:")
                    .font(.lhCaption)
                    .foregroundStyle(Color.lhSecondary)

                Text("\"Hush now, little one, close your eyes. The moon is rising in the skies. Stars are twinkling, soft and bright, keeping watch throughout the night. Dream of meadows, flowers, and streams, floating gently through your dreams. Tomorrow brings a brand new day, filled with laughter, love, and play.\"")
                    .font(.lhBody)
                    .foregroundStyle(Color.lhPrimary)
                    .italic()
            }
            .padding(LHSpacing.md)
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))

            Spacer()

            // Audio level visualization
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 160, height: 160)
                    .scaleEffect(1 + CGFloat(recorder.audioLevel) * 0.3)
                    .animation(.easeOut(duration: 0.1), value: recorder.audioLevel)

                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1 + CGFloat(recorder.audioLevel) * 0.2)
                    .animation(.easeOut(duration: 0.1), value: recorder.audioLevel)

                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 80, height: 80)

                Image(systemName: "mic.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }

            // Duration
            Text(formatDuration(recorder.recordingDuration))
                .font(.system(size: 40, weight: .light, design: .rounded))
                .foregroundStyle(Color.lhPrimary)
                .monospacedDigit()

            // Status
            if recorder.recordingDuration < minimumDuration {
                HStack(spacing: LHSpacing.xs) {
                    ProgressView(value: recorder.recordingDuration / minimumDuration)
                        .tint(Color.lhAccent)
                    Text("\(Int(minimumDuration - recorder.recordingDuration))s more needed")
                        .font(.lhCaption)
                        .foregroundStyle(Color.lhSecondary)
                }
                .padding(.horizontal, LHSpacing.xl)
            } else if recorder.recordingDuration < recommendedDuration {
                Text("Good! Keep going for best results...")
                    .font(.lhBody)
                    .foregroundStyle(.green)
            } else {
                Text("Great recording length!")
                    .font(.lhBody)
                    .foregroundStyle(.green)
            }

            // Audio level bars
            audioLevelBars

            Spacer()

            // Stop button
            Button {
                stopAndUpload()
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Recording")
                        .font(.lhHeadline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LHSpacing.md)
                .background(recorder.recordingDuration >= minimumDuration ? Color.lhAccent : Color.lhSecondary)
                .clipShape(RoundedRectangle(cornerRadius: LHRadius.lg))
            }
            .disabled(recorder.recordingDuration < minimumDuration)
        }
    }

    private var audioLevelBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(index: i))
                    .frame(width: 8, height: barHeight(index: i))
                    .animation(.easeOut(duration: 0.08), value: recorder.audioLevel)
            }
        }
        .frame(height: 40)
    }

    private func barColor(index: Int) -> Color {
        let threshold = Float(index) / 20.0
        return recorder.audioLevel > threshold ? Color.lhAccent : Color.lhSecondary.opacity(0.3)
    }

    private func barHeight(index: Int) -> CGFloat {
        let threshold = Float(index) / 20.0
        let active = recorder.audioLevel > threshold
        return active ? CGFloat(12 + (recorder.audioLevel - threshold) * 60) : 6
    }

    // MARK: - Uploading Phase

    private var uploadingPhase: some View {
        VStack(spacing: LHSpacing.lg) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.lhAccent)

            Text("Generating your voice...")
                .font(.lhHeadline)
                .foregroundStyle(Color.lhPrimary)

            Text("This may take a moment")
                .font(.lhBody)
                .foregroundStyle(Color.lhSecondary)

            if let error = errorMessage {
                Text(error)
                    .font(.lhCaption)
                    .foregroundStyle(.red)
                    .padding(.top)

                Button("Try Again") {
                    phase = .ready
                    errorMessage = nil
                }
                .foregroundStyle(Color.lhAccent)
            }

            Spacer()
        }
    }

    // MARK: - Done Phase

    private var donePhase: some View {
        VStack(spacing: LHSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }

            Text("Voice Ready!")
                .font(.lhTitle)
                .foregroundStyle(Color.lhPrimary)

            Text("You can now generate lullabies in your voice.")
                .font(.lhBody)
                .foregroundStyle(Color.lhSecondary)
                .multilineTextAlignment(.center)

            Button {
                onComplete()
                dismiss()
            } label: {
                Text("Continue")
                    .font(.lhHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LHSpacing.md)
                    .background(Color.lhAccent)
                    .clipShape(RoundedRectangle(cornerRadius: LHRadius.lg))
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func startRecording() {
        errorMessage = nil
        do {
            try recorder.startRecording()
            phase = .recording
        } catch {
            errorMessage = "Microphone access failed: \(error.localizedDescription)"
        }
    }

    private func stopAndUpload() {
        let url = recorder.stopRecording()
        let duration = recorder.recordingDuration
        phase = .uploading

        Task {
            do {
                guard let audioData = recorder.getAudioData() else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No audio data recorded"])
                }

                // Step 1: Create voice on backend
                let createResponse = try await voiceService.createVoice(name: voiceName.trimmingCharacters(in: .whitespaces))

                // Step 2: Upload audio to presigned URL
                try await voiceService.uploadAudio(url: createResponse.uploadUrl, audioData: audioData)

                // Step 3: Confirm upload
                _ = try await voiceService.confirmUpload(
                    voiceId: createResponse.id,
                    duration: duration,
                    fileSize: audioData.count
                )

                recorder.cleanup()
                phase = .done
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
