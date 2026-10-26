// VoiceProfileService.swift
// LullabyHaven
//
// Manages parent voice profiles for personalized lullaby generation.
// Communicates with the ReadAloud AI backend using device-based auth.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Voice Profile Model

struct VoiceProfile: Codable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let durationSec: Double?
    let createdAt: Date?
    let audioUrl: String?

    var isReady: Bool {
        (durationSec ?? 0) > 0
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case durationSec = "duration_sec"
        case createdAt = "created_at"
        case audioUrl = "audio_url"
    }
}

// MARK: - Errors

enum VoiceProfileError: LocalizedError, Sendable {
    case notConfigured
    case audioTooShort(minimumSeconds: Int)
    case audioTooLong(maximumSeconds: Int)
    case invalidAudioFormat
    case uploadFailed(String)
    case saveFailed(String)
    case profileNotFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service is not configured"
        case .audioTooShort(let min):
            return "Recording must be at least \(min) seconds"
        case .audioTooLong(let max):
            return "Recording must be no longer than \(max) seconds"
        case .invalidAudioFormat:
            return "Unsupported audio format"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .saveFailed(let reason):
            return "Could not save voice profile: \(reason)"
        case .profileNotFound:
            return "Voice profile not found"
        case .networkError(let msg):
            return "Network error: \(msg)"
        }
    }
}

// MARK: - Service

actor VoiceProfileService {

    // MARK: - Configuration

    static let shared = VoiceProfileService()

    static let minimumRecordingDuration: TimeInterval = 5
    static let maximumRecordingDuration: TimeInterval = 300

    private let backendURL = URL(string: "https://listenai-backend-917362189743.us-central1.run.app")!
    private let profilesKey = "com.lullabyhaven.voiceProfiles"

    private init() {}

    // MARK: - Public API

    /// Create and save a voice profile from a recorded audio file.
    /// Three-step process: register profile → upload audio → confirm.
    func saveVoiceProfile(name: String, audioFileURL: URL) async throws -> VoiceProfile {
        let (durationSec, fileSizeBytes) = try await validateAudio(at: audioFileURL)
        let audioData = try Data(contentsOf: audioFileURL)

        // Step 1: Register and get upload URL
        let registration = try await registerProfile(name: name)

        // Step 2: Upload audio to storage
        try await uploadAudio(data: audioData, to: registration.uploadUrl)

        // Step 3: Confirm and finalize
        let profile = try await confirmUpload(
            profileId: registration.id,
            durationSec: durationSec,
            fileSizeBytes: fileSizeBytes
        )

        persistProfileLocally(profile)
        return profile
    }

    /// Fetch all saved voice profiles from the backend and update local cache.
    func fetchVoiceProfiles(forceRefresh: Bool = false) async throws -> [VoiceProfile] {
        if !forceRefresh {
            let cached = loadProfilesFromDisk()
            if !cached.isEmpty {
                Task { try? await refreshFromBackend() }
                return cached
            }
        }
        return try await refreshFromBackend()
    }

    /// Remove a voice profile by ID.
    func removeVoiceProfile(_ profileId: String) async throws {
        let request = try makeRequest(endpoint: "/api/cloned-voices/\(profileId)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw VoiceProfileError.networkError("Invalid response")
        }
        switch http.statusCode {
        case 200, 204:
            removeProfileFromDisk(profileId)
        case 404:
            throw VoiceProfileError.profileNotFound
        default:
            throw VoiceProfileError.networkError("HTTP \(http.statusCode)")
        }
    }

    /// Return locally cached profiles without a network call.
    func cachedProfiles() -> [VoiceProfile] {
        loadProfilesFromDisk()
    }

    // MARK: - Private: API Steps

    private struct RegistrationResponse: Decodable {
        let id: String
        let name: String
        let uploadUrl: String
        enum CodingKeys: String, CodingKey {
            case id, name
            case uploadUrl = "upload_url"
        }
    }

    private struct ProfilesListResponse: Decodable {
        let voices: [VoiceProfile]
    }

    private func registerProfile(name: String) async throws -> RegistrationResponse {
        var request = try makeRequest(endpoint: "/api/cloned-voices", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["name": name, "exaggeration": 0.5]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...201).contains(http.statusCode) else {
            throw VoiceProfileError.saveFailed("Registration failed")
        }
        return try JSONDecoder().decode(RegistrationResponse.self, from: data)
    }

    private func uploadAudio(data: Data, to urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw VoiceProfileError.uploadFailed("Invalid upload URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        request.timeoutInterval = 120

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw VoiceProfileError.uploadFailed("Storage upload failed")
        }
    }

    private func confirmUpload(profileId: String, durationSec: Double, fileSizeBytes: Int) async throws -> VoiceProfile {
        var request = try makeRequest(endpoint: "/api/cloned-voices/\(profileId)/confirm", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["duration_sec": durationSec, "file_size_bytes": fileSizeBytes]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw VoiceProfileError.saveFailed("Confirmation failed")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.dateStrategy
        return try decoder.decode(VoiceProfile.self, from: data)
    }

    @discardableResult
    private func refreshFromBackend() async throws -> [VoiceProfile] {
        let request = try makeRequest(endpoint: "/api/cloned-voices?include_audio_urls=true", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw VoiceProfileError.networkError("Fetch failed")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.dateStrategy
        let list = try decoder.decode(ProfilesListResponse.self, from: data)
        persistAllProfilesToDisk(list.voices)
        return list.voices
    }

    // MARK: - Private: Validation

    private func validateAudio(at url: URL) async throws -> (durationSec: Double, fileSizeBytes: Int) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VoiceProfileError.uploadFailed("File not found")
        }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? Int) ?? 0

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)

        if seconds < Self.minimumRecordingDuration {
            throw VoiceProfileError.audioTooShort(minimumSeconds: Int(Self.minimumRecordingDuration))
        }
        if seconds > Self.maximumRecordingDuration {
            throw VoiceProfileError.audioTooLong(maximumSeconds: Int(Self.maximumRecordingDuration))
        }
        return (seconds, size)
    }

    // MARK: - Private: Networking

    private func makeRequest(endpoint: String, method: String) throws -> URLRequest {
        var base = backendURL.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        let path = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        guard let url = URL(string: base + path) else {
            throw VoiceProfileError.networkError("Bad URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        return request
    }

    private var deviceId: String {
        if let cached = UserDefaults.standard.string(forKey: "com.lullabyhaven.deviceId"), !cached.isEmpty {
            return cached
        }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(id, forKey: "com.lullabyhaven.deviceId")
        return id
    }

    // MARK: - Private: Persistence

    private func loadProfilesFromDisk() -> [VoiceProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.dateStrategy
        return (try? decoder.decode([VoiceProfile].self, from: data)) ?? []
    }

    private func persistAllProfilesToDisk(_ profiles: [VoiceProfile]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func persistProfileLocally(_ profile: VoiceProfile) {
        var profiles = loadProfilesFromDisk()
        profiles.removeAll { $0.id == profile.id }
        profiles.insert(profile, at: 0)
        persistAllProfilesToDisk(profiles)
    }

    private func removeProfileFromDisk(_ profileId: String) {
        var profiles = loadProfilesFromDisk()
        profiles.removeAll { $0.id == profileId }
        persistAllProfilesToDisk(profiles)
    }

    // MARK: - Private: Date Decoding

    private static let dateStrategy: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)

        let withFraction: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let plain: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()

        if let d = withFraction.date(from: str) { return d }
        if let d = plain.date(from: str) { return d }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(str)")
    }
}
