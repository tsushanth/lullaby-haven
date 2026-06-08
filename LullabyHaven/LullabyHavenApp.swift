//
//  LullabyHavenApp.swift
//  LullabyHaven
//
//  Main app entry point with SwiftData, StoreKit 2, and background audio
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct LullabyHavenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    @State private var storeKitManager = StoreKitManager()

    init() {
        do {
            let schema = Schema([
                FavoriteSound.self,
                SoundMix.self,
                SleepSession.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Pre-load sound library
        _ = SoundLibrary.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeKitManager)
                .onAppear {
                    Task {
                        await storeKitManager.updatePurchasedProducts()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - App Delegate
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Configure audio session for background playback
        configureAudioSession()

        // Request notification permission
        Task {
            _ = await NotificationManager.shared.requestPermission()
        }

        // Register Apple Search Ads attribution token (one-time, fire-and-forget)
        AttributionService.shared.trackAttribution()

        return true
    }

    private func configureAudioSession() {
        // AudioPlayerService handles session configuration on first use
        _ = AudioPlayerService.shared
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
