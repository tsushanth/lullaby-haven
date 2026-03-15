//
//  NightModeView.swift
//  LullabyHaven
//
//  Dark screen night mode — tap to wake, minimal UI to preserve night vision
//

import SwiftUI

struct NightModeView: View {
    @Bindable var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isAwake = false
    @State private var wakeTimer: Timer?
    @State private var brightness: Double = UIScreen.main.brightness
    private let dimBrightness: Double = 0.02

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isAwake {
                wakeContent
            } else {
                sleepContent
            }
        }
        .statusBarHidden(!isAwake)
        .onTapGesture {
            wakeUp()
        }
        .onAppear {
            dimScreen()
        }
        .onDisappear {
            restoreScreen()
        }
    }

    // MARK: - Sleep Content (dim)
    private var sleepContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.15))
            if playerVM.isTimerActive {
                Text(playerVM.timerRemaining)
                    .font(.system(size: 18, weight: .light).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
    }

    // MARK: - Wake Content
    private var wakeContent: some View {
        VStack(spacing: 28) {
            HStack {
                Spacer()
                Button {
                    restoreScreen()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding()
            }

            Spacer()

            // Sound name
            VStack(spacing: 8) {
                Image(systemName: playerVM.currentSound?.iconName ?? "moon.stars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.8))
                Text(playerVM.currentSound?.name ?? "Lullaby Haven")
                    .font(.title2.bold())
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Playback button
            Button {
                playerVM.togglePlayback()
            } label: {
                Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Timer display
            if playerVM.isTimerActive {
                VStack(spacing: 6) {
                    Text("Timer: \(playerVM.timerRemaining)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                    ProgressView(value: playerVM.timerProgress)
                        .tint(.white.opacity(0.5))
                        .frame(maxWidth: 200)
                }
            }

            Spacer()

            Text("Tap anywhere to dim")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 32)
        }
        .background(Color.black.opacity(0.95).ignoresSafeArea())
    }

    // MARK: - Helpers
    private func wakeUp() {
        guard !isAwake else {
            // Tap while awake → go back to sleep
            isAwake = false
            dimScreen()
            return
        }
        withAnimation(.easeIn(duration: 0.3)) { isAwake = true }
        restoreScreen(partial: true)

        // Auto-sleep after 5 seconds
        wakeTimer?.invalidate()
        wakeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            Task { @MainActor in
                withAnimation { isAwake = false }
                dimScreen()
            }
        }
    }

    private func dimScreen() {
        brightness = UIScreen.main.brightness
        UIScreen.main.brightness = dimBrightness
    }

    private func restoreScreen(partial: Bool = false) {
        UIScreen.main.brightness = partial ? 0.3 : brightness
    }
}
