//
//  OnboardingView.swift
//  LullabyHaven
//
//  First-launch onboarding flow
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var showPaywall = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            title: "Welcome to\nLullaby Haven",
            subtitle: "The ultimate sleep companion for your baby. Soothing sounds, lullabies, and smart timers all in one place.",
            gradient: [Color(hex: "#0d1117"), Color(hex: "#1a2744")]
        ),
        OnboardingPage(
            icon: "waveform.path.ecg",
            title: "50+ Sleep Sounds",
            subtitle: "From pure white noise to gentle heartbeats, rain, and classical lullabies. Science-backed sounds that really work.",
            gradient: [Color(hex: "#0d1117"), Color(hex: "#1a2744")]
        ),
        OnboardingPage(
            icon: "slider.horizontal.3",
            title: "Mix Your Perfect\nSoundscape",
            subtitle: "Layer multiple sounds together. Combine rain with white noise, or heartbeat with a lullaby for a custom mix.",
            gradient: [Color(hex: "#0d1117"), Color(hex: "#1a2744")]
        ),
        OnboardingPage(
            icon: "timer",
            title: "Smart Sleep Timer",
            subtitle: "Set a timer for 15 minutes or all night. The app gently fades the sound as your baby drifts off.",
            gradient: [Color(hex: "#0d1117"), Color(hex: "#1a2744")]
        ),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding()
                    }
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { idx in
                        pageContent(pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { idx in
                        Capsule()
                            .fill(currentPage == idx ? Color.lhAccent : .white.opacity(0.3))
                            .frame(width: currentPage == idx ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 24)

                Spacer()

                // Navigation
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.lhAccent.opacity(0.15))
                    .frame(width: 130, height: 130)
                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.lhAccent)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 24)
    }

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if currentPage < pages.count - 1 {
                Button {
                    withAnimation { currentPage += 1 }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lhAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                VStack(spacing: 12) {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Try Premium Free")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lhAccent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Continue with Free")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
