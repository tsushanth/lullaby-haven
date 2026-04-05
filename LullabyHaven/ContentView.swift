//
//  ContentView.swift
//  LullabyHaven
//
//  Root view with onboarding check and main tab navigation
//

import SwiftUI

struct ContentView: View {
    @AppStorage("lh.hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: Tab = .home

    init() {
        // FASTLANE_SNAPSHOT: skip onboarding for automated screenshots
        if ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT") {
            UserDefaults.standard.set(true, forKey: "lh.hasCompletedOnboarding")
        }
    }

    enum Tab: Int {
        case home, library, mixer, favorites, settings
    }

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            mainTabs
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == .home ? "moon.stars.fill" : "moon.stars")
                }
                .tag(Tab.home)

            SoundLibraryView()
                .tabItem {
                    Label("Library", systemImage: selectedTab == .library ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle")
                }
                .tag(Tab.library)

            MixerView()
                .tabItem {
                    Label("Mixer", systemImage: "slider.horizontal.3")
                }
                .tag(Tab.mixer)

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: selectedTab == .favorites ? "heart.fill" : "heart")
                }
                .tag(Tab.favorites)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color.lhAccent)
    }
}
