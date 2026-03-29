//
//  VoiceCloningService.swift
//  LullabyHaven
//
//  API client for voice generation backend.
//

import Foundation
import UIKit

// MARK: - Models

struct SavedVoice: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let durationSec: Double?
    let exaggeration: Double?
    let isDefault: Bool?
    let usageCount: Int?
    let createdAt: String?
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, exaggeration
        case durationSec = "duration_sec"
        case isDefault = "is_default"
        case usageCount = "usage_count"
        case createdAt = "created_at"
        case audioUrl = "audio_url"
    }
}

struct CreateVoiceResponse: Codable {
    let id: String
    let name: String
    let uploadUrl: String

    enum CodingKeys: String, CodingKey {
        case id, name
        case uploadUrl = "upload_url"
    }
}

struct VoiceListResponse: Codable {
    let voices: [SavedVoice]
}

// MARK: - Service

@MainActor
@Observable
final class VoiceGenerationService {
    static let shared = VoiceGenerationService()

    private let baseURL = "https://listenai-backend-3t2vweivqa-uc.a.run.app"

    var voices: [SavedVoice] = []
    var isLoading = false
    var error: String?

    var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    // MARK: - List Voices

    func loadVoices() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: URL(string: "\(baseURL)/api/cloned-voices?include_audio_urls=true")!)
            request.addValue(deviceId, forHTTPHeaderField: "X-Device-ID")

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(VoiceListResponse.self, from: data)
            voices = response.voices
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Create Voice

    func createVoice(name: String) async throws -> CreateVoiceResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/cloned-voices")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        request.httpBody = try JSONEncoder().encode([
            "name": name,
            "description": "LullabyHaven voice",
            "exaggeration": "0.5"
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(CreateVoiceResponse.self, from: data)
    }

    // MARK: - Upload Audio

    func uploadAudio(url: String, audioData: Data) async throws {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "PUT"
        request.addValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Confirm Upload

    func confirmUpload(voiceId: String, duration: Double, fileSize: Int) async throws -> SavedVoice {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/cloned-voices/\(voiceId)/confirm")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(deviceId, forHTTPHeaderField: "X-Device-ID")

        let body: [String: Any] = ["duration_sec": duration, "file_size_bytes": fileSize]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SavedVoice.self, from: data)
    }

    // MARK: - Synthesize Lullaby

    func synthesize(text: String, voiceId: String, voiceURL: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/tts/cloned")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "text": text,
            "voice_id": voiceId,
            "voice_url": voiceURL,
            "speed": 0.85,
            "model": "chatterbox"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Delete Voice

    func deleteVoice(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/cloned-voices/\(id)")!)
        request.httpMethod = "DELETE"
        request.addValue(deviceId, forHTTPHeaderField: "X-Device-ID")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }
        voices.removeAll { $0.id == id }
    }

    // MARK: - Cache Management

    func cachedAudioURL(voiceId: String, lullabyId: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("lullaby_\(voiceId)_\(lullabyId).wav")
    }

    func hasCachedAudio(voiceId: String, lullabyId: String) -> Bool {
        FileManager.default.fileExists(atPath: cachedAudioURL(voiceId: voiceId, lullabyId: lullabyId).path)
    }

    func saveCachedAudio(_ data: Data, voiceId: String, lullabyId: String) throws {
        try data.write(to: cachedAudioURL(voiceId: voiceId, lullabyId: lullabyId))
    }

    func loadCachedAudio(voiceId: String, lullabyId: String) -> Data? {
        try? Data(contentsOf: cachedAudioURL(voiceId: voiceId, lullabyId: lullabyId))
    }
}
