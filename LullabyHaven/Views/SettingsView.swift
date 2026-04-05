//
//  SettingsView.swift
//  LullabyHaven
//
//  App settings and user preferences
//

import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreKitManager.self) private var storeKit
    @AppStorage("lh.fadeOutDuration") private var fadeOutDuration: Double = 30
    @AppStorage("lh.nightModeAutoOn") private var nightModeAutoOn: Bool = false
    @AppStorage("lh.notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var sessionCount: Int = 0

    var body: some View {
        NavigationStack {
            List {
                // Premium section
                if !storeKit.isPremium {
                    premiumBanner
                }

                // Playback
                Section("Playback") {
                    HStack {
                        Label("Fade-Out Duration", systemImage: "wand.and.stars")
                        Spacer()
                        Text("\(Int(fadeOutDuration))s")
                            .foregroundStyle(Color.lhSecondary)
                    }
                    Slider(value: $fadeOutDuration, in: 10...60, step: 5)
                        .tint(Color.lhAccent)
                }

                // Night Mode
                Section("Night Mode") {
                    Toggle(isOn: $nightModeAutoOn) {
                        Label("Auto Night Mode", systemImage: "moon.fill")
                    }
                    .tint(Color.lhAccent)
                }

                // Notifications
                Section("Notifications") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Timer Notifications", systemImage: "bell.fill")
                    }
                    .tint(Color.lhAccent)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            Task { _ = await NotificationManager.shared.requestPermission() }
                        }
                    }
                }

                // Analytics (premium)
                if storeKit.isPremium {
                    Section("Sleep Analytics") {
                        HStack {
                            Label("Total Sessions", systemImage: "chart.bar.fill")
                            Spacer()
                            Text("\(sessionCount)")
                                .foregroundStyle(Color.lhSecondary)
                        }
                        NavigationLink {
                            SleepAnalyticsView()
                        } label: {
                            Label("View Sleep Report", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                }

                // Account
                Section("Account") {
                    if storeKit.isPremium {
                        HStack {
                            Label("Premium Active", systemImage: "star.fill")
                                .foregroundStyle(Color.lhGold)
                            Spacer()
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        Button {
                            Task { await storeKit.restorePurchases() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade to Premium", systemImage: "star.fill")
                                .foregroundStyle(Color.lhGold)
                        }
                        Button {
                            Task { await storeKit.restorePurchases() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(Color.lhSecondary)
                    }
                    Link(destination: URL(string: "https://kreativekoala.llc/privacy")!) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    Link(destination: URL(string: "https://kreativekoala.llc/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    if let scene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene }).first {
                        Button {
                            SKStoreReviewController.requestReview(in: scene)
                        } label: {
                            Label("Rate Lullaby Haven", systemImage: "star.bubble")
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Clear Sleep History", systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Clear All Sleep History?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { clearHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your sleep session data.")
        }
        .onAppear { fetchSessionCount() }
    }

    private var premiumBanner: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundStyle(Color.lhGold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundStyle(Color.lhPrimary)
                        Text("Unlock all 50+ sounds, mixing, and analytics")
                            .font(.caption)
                            .foregroundStyle(Color.lhSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.lhSecondary)
                }
                .padding(4)
            }
            .buttonStyle(.plain)
        }
    }

    private func fetchSessionCount() {
        let descriptor = FetchDescriptor<SleepSession>()
        sessionCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func clearHistory() {
        let descriptor = FetchDescriptor<SleepSession>()
        if let sessions = try? modelContext.fetch(descriptor) {
            sessions.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
        sessionCount = 0
    }
}

// MARK: - Sleep Analytics View
struct SleepAnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sessions: [SleepSession] = []

    var summary: SleepAnalyticsSummary {
        guard !sessions.isEmpty else { return .empty }
        let totalMins = sessions.reduce(0) { $0 + $1.durationSeconds / 60 }
        let avgMins = totalMins / Double(sessions.count)
        let longest = sessions.map { $0.durationSeconds / 60 }.max() ?? 0

        let allSoundIDs = sessions.flatMap { $0.soundIDs }
        let counts = Dictionary(grouping: allSoundIDs, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let topSounds = Array(counts.prefix(3).map { $0.key })

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let thisWeek = sessions.filter { $0.startedAt >= weekAgo }.count

        return SleepAnalyticsSummary(
            totalSessions: sessions.count,
            totalMinutesPlayed: totalMins,
            averageSessionMinutes: avgMins,
            mostUsedSoundIDs: topSounds,
            sessionsThisWeek: thisWeek,
            longestSessionMinutes: longest
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AnalyticCard(title: "Total Sessions", value: "\(summary.totalSessions)", icon: "moon.fill")
                    AnalyticCard(title: "This Week", value: "\(summary.sessionsThisWeek)", icon: "calendar")
                    AnalyticCard(title: "Avg Duration", value: "\(Int(summary.averageSessionMinutes))m", icon: "timer")
                    AnalyticCard(title: "Longest Session", value: "\(Int(summary.longestSessionMinutes))m", icon: "star.fill")
                }

                // Recent sessions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Sessions")
                        .font(.headline)
                        .foregroundStyle(Color.lhPrimary)
                    ForEach(sessions.prefix(10)) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.lhPrimary)
                                Text(session.durationFormatted)
                                    .font(.caption)
                                    .foregroundStyle(Color.lhSecondary)
                            }
                            Spacer()
                            Text("\(session.soundIDs.count) sounds")
                                .font(.caption)
                                .foregroundStyle(Color.lhAccent)
                        }
                        .padding()
                        .background(Color.lhCard)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
        .background(Color.lhBackground)
        .navigationTitle("Sleep Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchSessions() }
    }

    private func fetchSessions() {
        let descriptor = FetchDescriptor<SleepSession>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        sessions = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct AnalyticCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.lhAccent)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Color.lhPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.lhSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.lhCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
