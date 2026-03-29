//
//  VoiceCloneView.swift
//  LullabyHaven
//
//  Voice management hub: manage voices + record new ones
//

import SwiftUI

struct MyVoiceView: View {
    @State private var voiceService = VoiceGenerationService.shared
    @State private var showRecording = false
    @State private var selectedVoice: SavedVoice?
    @State private var showDeleteConfirm = false
    @State private var voiceToDelete: SavedVoice?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lhBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LHSpacing.lg) {
                        heroSection
                        recordButton

                        if voiceService.isLoading {
                            ProgressView()
                                .tint(Color.lhAccent)
                                .padding(.top, LHSpacing.xl)
                        } else if voiceService.voices.isEmpty {
                            emptyState
                        } else {
                            voicesList
                        }

                        if let error = voiceService.error {
                            Text(error)
                                .font(.lhCaption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, LHSpacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("My Voice")
            .refreshable {
                await voiceService.loadVoices()
            }
            .task {
                await voiceService.loadVoices()
            }
            .fullScreenCover(isPresented: $showRecording) {
                VoiceRecordingView {
                    Task { await voiceService.loadVoices() }
                }
            }
            .navigationDestination(item: $selectedVoice) { voice in
                LullabyGeneratorView(voice: voice)
            }
            .alert("Remove Voice?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let voice = voiceToDelete {
                        Task {
                            try? await voiceService.deleteVoice(id: voice.id)
                        }
                    }
                }
            } message: {
                Text("This will permanently remove this voice and its recordings.")
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: LHSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Circle()
                    .fill(Color.lhAccent.opacity(0.2))
                    .frame(width: 72, height: 72)
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.lhAccent)
            }

            Text("Lullabies in Your Voice")
                .font(.lhHeadline)
                .foregroundStyle(Color.lhPrimary)

            Text("Record a short voice sample and we'll generate lullabies that sound just like you.")
                .font(.lhBody)
                .foregroundStyle(Color.lhSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LHSpacing.xl)
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            showRecording = true
        } label: {
            HStack(spacing: LHSpacing.sm) {
                Image(systemName: "mic.fill")
                    .font(.title3)
                Text("Record My Voice")
                    .font(.lhHeadline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LHSpacing.md)
            .background(Color.lhAccent)
            .clipShape(RoundedRectangle(cornerRadius: LHRadius.lg))
        }
        .padding(.horizontal, LHSpacing.lg)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LHSpacing.sm) {
            Image(systemName: "person.wave.2")
                .font(.system(size: 40))
                .foregroundStyle(Color.lhSecondary.opacity(0.5))
            Text("No voices yet")
                .font(.lhHeadline)
                .foregroundStyle(Color.lhSecondary)
            Text("Record your voice to get started")
                .font(.lhCaption)
                .foregroundStyle(Color.lhSecondary.opacity(0.7))
        }
        .padding(.top, LHSpacing.xl)
    }

    // MARK: - Voices List

    private var voicesList: some View {
        VStack(alignment: .leading, spacing: LHSpacing.sm) {
            Text("My Voices")
                .font(.lhHeadline)
                .foregroundStyle(Color.lhPrimary)
                .padding(.horizontal, LHSpacing.lg)

            ForEach(voiceService.voices) { voice in
                Button {
                    selectedVoice = voice
                } label: {
                    voiceRow(voice)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        voiceToDelete = voice
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .padding(.horizontal, LHSpacing.lg)
        }
    }

    private func voiceRow(_ voice: SavedVoice) -> some View {
        HStack(spacing: LHSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(Color.lhAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(voice.name)
                    .font(.lhHeadline)
                    .foregroundStyle(Color.lhPrimary)

                HStack(spacing: LHSpacing.xs) {
                    if let duration = voice.durationSec {
                        Text("\(Int(duration))s recorded")
                            .font(.lhCaption)
                            .foregroundStyle(Color.lhSecondary)
                    }
                    if let count = voice.usageCount, count > 0 {
                        Text("\u{00b7}")
                            .foregroundStyle(Color.lhSecondary)
                        Text("\(count) lullabies")
                            .font(.lhCaption)
                            .foregroundStyle(Color.lhSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.lhSecondary)
        }
        .padding(LHSpacing.md)
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: LHRadius.md))
    }
}
