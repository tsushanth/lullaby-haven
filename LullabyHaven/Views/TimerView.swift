//
//  TimerView.swift
//  LullabyHaven
//
//  Sleep timer configuration and countdown display
//

import SwiftUI

struct TimerView: View {
    @Bindable var timerVM: TimerViewModel
    @Bindable var playerVM: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitManager.self) private var storeKit
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Active timer ring
                    if timerVM.isRunning {
                        activeTimerDisplay
                    }

                    // Duration picker
                    durationPicker

                    // Fade out toggle
                    fadeOutToggle

                    // Action button
                    actionButton
                }
                .padding()
            }
            .background(Color.lhBackground)
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Active Timer Ring
    private var activeTimerDisplay: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.lhAccent.opacity(0.2), lineWidth: 10)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: timerVM.progress)
                    .stroke(Color.lhAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerVM.progress)
                VStack(spacing: 2) {
                    Text(timerVM.timeRemainingFormatted)
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color.lhPrimary)
                    Text(timerVM.timerStatusLabel)
                        .font(.caption)
                        .foregroundStyle(Color.lhSecondary)
                }
            }

            HStack(spacing: 16) {
                if timerVM.timerState == .running {
                    Button("Pause") { timerVM.pauseTimer() }
                        .buttonStyle(.bordered)
                        .tint(Color.lhAccent)
                } else if timerVM.timerState == .paused {
                    Button("Resume") { timerVM.resumeTimer() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.lhAccent)
                }
                Button("Cancel") {
                    timerVM.cancelTimer()
                    playerVM.cancelTimer()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Duration Picker
    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timer Duration")
                .font(.headline)
                .foregroundStyle(Color.lhPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(timerVM.durations) { duration in
                    TimerDurationButton(
                        duration: duration,
                        isSelected: timerVM.selectedDuration.minutes == duration.minutes,
                        isPremiumRequired: duration.isPremium && !storeKit.isPremium
                    ) {
                        if duration.isPremium && !storeKit.isPremium {
                            showPaywall = true
                        } else {
                            timerVM.selectedDuration = duration
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fade Out Toggle
    private var fadeOutToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gentle Fade Out")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.lhPrimary)
                Text("Volume gradually decreases before stopping")
                    .font(.caption)
                    .foregroundStyle(Color.lhSecondary)
            }
            Spacer()
            Toggle("", isOn: $timerVM.isFadeOutEnabled)
                .tint(Color.lhAccent)
                .labelsHidden()
        }
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Group {
            if !timerVM.isRunning {
                Button {
                    timerVM.startTimer(isPremium: storeKit.isPremium)
                    playerVM.startTimer(duration: timerVM.selectedDuration)
                    if timerVM.isRunning { dismiss() }
                } label: {
                    Label("Start Timer", systemImage: "timer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lhAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(!playerVM.isPlaying)
                .opacity(playerVM.isPlaying ? 1 : 0.5)

                if !playerVM.isPlaying {
                    Text("Start a sound first to use the timer")
                        .font(.caption)
                        .foregroundStyle(Color.lhSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Timer Duration Button
struct TimerDurationButton: View {
    let duration: TimerDuration
    let isSelected: Bool
    let isPremiumRequired: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isPremiumRequired ? "lock.fill" : duration.iconName)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : (isPremiumRequired ? Color.lhGold : Color.lhAccent))
                Text(duration.displayName)
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? .white : Color.lhPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.lhAccent : Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPremiumRequired ? Color.lhGold.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
