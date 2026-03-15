//
//  Sound.swift
//  LullabyHaven
//
//  Core sound model representing a sleep sound or lullaby
//

import Foundation
import SwiftData

// MARK: - Sound Category
enum SoundCategory: String, CaseIterable, Codable {
    case whiteNoise = "White Noise"
    case pinkNoise = "Pink Noise"
    case brownNoise = "Brown Noise"
    case nature = "Nature"
    case womb = "Womb"
    case lullaby = "Lullaby"
    case mechanical = "Mechanical"
    case shushing = "Shushing"

    var iconName: String {
        switch self {
        case .whiteNoise: return "waveform"
        case .pinkNoise: return "waveform.path"
        case .brownNoise: return "waveform.path.ecg"
        case .nature: return "cloud.rain"
        case .womb: return "heart.fill"
        case .lullaby: return "music.note"
        case .mechanical: return "fan"
        case .shushing: return "mouth"
        }
    }

    var isPremium: Bool {
        switch self {
        case .whiteNoise, .pinkNoise: return false
        default: return true
        }
    }
}

// MARK: - Sound Type
enum SoundType: String, Codable {
    case generated   // AVAudioEngine synthesized
    case bundled     // Bundled audio file
    case lullaby     // Lullaby music track
}

// MARK: - Sound Model
@Model
final class Sound {
    @Attribute(.unique) var id: String
    var name: String
    var categoryRaw: String
    var typeRaw: String
    var fileName: String?       // nil for generated sounds
    var isPremium: Bool
    var isFavorite: Bool
    var playCount: Int
    var lastPlayedAt: Date?
    var createdAt: Date

    // Generator parameters (for generated sounds)
    var noiseTypeRaw: String?   // "white", "pink", "brown"
    var baseFrequency: Double   // Hz, used for some generated sounds

    init(
        id: String,
        name: String,
        category: SoundCategory,
        type: SoundType,
        fileName: String? = nil,
        isPremium: Bool = false,
        noiseType: String? = nil,
        baseFrequency: Double = 0
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.typeRaw = type.rawValue
        self.fileName = fileName
        self.isPremium = isPremium
        self.isFavorite = false
        self.playCount = 0
        self.lastPlayedAt = nil
        self.createdAt = Date()
        self.noiseTypeRaw = noiseType
        self.baseFrequency = baseFrequency
    }

    var category: SoundCategory {
        SoundCategory(rawValue: categoryRaw) ?? .whiteNoise
    }

    var soundType: SoundType {
        SoundType(rawValue: typeRaw) ?? .generated
    }

    var noiseType: String? {
        noiseTypeRaw
    }
}

// MARK: - Sound Library Data
extension Sound {
    static func makeLibrary() -> [SoundDTO] {
        return [
            // --- White Noise ---
            SoundDTO(id: "white_noise_pure",      name: "Pure White Noise",     category: .whiteNoise, type: .generated, isPremium: false, noiseType: "white"),
            SoundDTO(id: "white_noise_soft",       name: "Soft White Noise",     category: .whiteNoise, type: .generated, isPremium: false, noiseType: "white"),
            SoundDTO(id: "white_noise_deep",       name: "Deep White Noise",     category: .whiteNoise, type: .generated, isPremium: false, noiseType: "white"),

            // --- Pink Noise ---
            SoundDTO(id: "pink_noise_pure",        name: "Pure Pink Noise",      category: .pinkNoise,  type: .generated, isPremium: false, noiseType: "pink"),
            SoundDTO(id: "pink_noise_gentle",      name: "Gentle Pink Noise",    category: .pinkNoise,  type: .generated, isPremium: false, noiseType: "pink"),

            // --- Brown Noise ---
            SoundDTO(id: "brown_noise_pure",       name: "Brown Noise",          category: .brownNoise, type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "brown_noise_deep",       name: "Deep Brown Noise",     category: .brownNoise, type: .generated, isPremium: true,  noiseType: "brown"),

            // --- Nature ---
            SoundDTO(id: "rain_gentle",            name: "Gentle Rain",          category: .nature,     type: .generated, isPremium: false, noiseType: "rain"),
            SoundDTO(id: "rain_heavy",             name: "Heavy Rain",           category: .nature,     type: .generated, isPremium: true,  noiseType: "rain"),
            SoundDTO(id: "rain_window",            name: "Rain on Window",       category: .nature,     type: .generated, isPremium: true,  noiseType: "rain"),
            SoundDTO(id: "thunder_rain",           name: "Thunder & Rain",       category: .nature,     type: .generated, isPremium: true,  noiseType: "rain"),
            SoundDTO(id: "ocean_waves",            name: "Ocean Waves",          category: .nature,     type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "river_stream",           name: "River Stream",         category: .nature,     type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "forest_night",           name: "Forest Night",         category: .nature,     type: .generated, isPremium: true,  noiseType: "pink"),
            SoundDTO(id: "crickets",               name: "Crickets",             category: .nature,     type: .generated, isPremium: true,  noiseType: "pink"),
            SoundDTO(id: "wind_gentle",            name: "Gentle Wind",          category: .nature,     type: .generated, isPremium: true,  noiseType: "pink"),

            // --- Womb ---
            SoundDTO(id: "heartbeat_slow",         name: "Heartbeat (Slow)",     category: .womb,       type: .generated, isPremium: false, noiseType: "heartbeat", baseFrequency: 1.0),
            SoundDTO(id: "heartbeat_normal",       name: "Heartbeat (Normal)",   category: .womb,       type: .generated, isPremium: false, noiseType: "heartbeat", baseFrequency: 1.2),
            SoundDTO(id: "womb_sounds",            name: "Womb Sounds",          category: .womb,       type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "womb_heartbeat",         name: "Womb & Heartbeat",     category: .womb,       type: .generated, isPremium: true,  noiseType: "heartbeat", baseFrequency: 1.1),

            // --- Shushing ---
            SoundDTO(id: "shush_soft",             name: "Soft Shushing",        category: .shushing,   type: .generated, isPremium: false, noiseType: "white"),
            SoundDTO(id: "shush_rhythmic",         name: "Rhythmic Shushing",    category: .shushing,   type: .generated, isPremium: true,  noiseType: "white"),
            SoundDTO(id: "shush_loud",             name: "Loud Shushing",        category: .shushing,   type: .generated, isPremium: true,  noiseType: "white"),

            // --- Mechanical ---
            SoundDTO(id: "fan_box",                name: "Box Fan",              category: .mechanical, type: .generated, isPremium: false, noiseType: "white"),
            SoundDTO(id: "fan_ceiling",            name: "Ceiling Fan",          category: .mechanical, type: .generated, isPremium: true,  noiseType: "white"),
            SoundDTO(id: "vacuum_cleaner",         name: "Vacuum Cleaner",       category: .mechanical, type: .generated, isPremium: true,  noiseType: "white"),
            SoundDTO(id: "hair_dryer",             name: "Hair Dryer",           category: .mechanical, type: .generated, isPremium: true,  noiseType: "white"),
            SoundDTO(id: "washing_machine",        name: "Washing Machine",      category: .mechanical, type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "car_ride",               name: "Car Ride",             category: .mechanical, type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "airplane_cabin",         name: "Airplane Cabin",       category: .mechanical, type: .generated, isPremium: true,  noiseType: "brown"),
            SoundDTO(id: "train_rhythm",           name: "Train Rhythm",         category: .mechanical, type: .generated, isPremium: true,  noiseType: "brown"),

            // --- Lullabies ---
            SoundDTO(id: "lullaby_twinkle",        name: "Twinkle Little Star",  category: .lullaby,    type: .lullaby,   isPremium: false),
            SoundDTO(id: "lullaby_brahms",         name: "Brahms Lullaby",       category: .lullaby,    type: .lullaby,   isPremium: false),
            SoundDTO(id: "lullaby_rock_baby",      name: "Rock-a-bye Baby",      category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_hush_little",    name: "Hush Little Baby",     category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_golden_slumber", name: "Golden Slumbers",      category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_moonlight",      name: "Moonlight Sonata",     category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_claire",         name: "Clair de Lune",        category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_nocturne",       name: "Chopin Nocturne",      category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_piano_gentle",   name: "Gentle Piano",         category: .lullaby,    type: .lullaby,   isPremium: true),
            SoundDTO(id: "lullaby_music_box",      name: "Music Box",            category: .lullaby,    type: .lullaby,   isPremium: true),
        ]
    }
}

// MARK: - Sound Data Transfer Object
struct SoundDTO: Identifiable {
    let id: String
    let name: String
    let category: SoundCategory
    let type: SoundType
    let isPremium: Bool
    let noiseType: String?
    let baseFrequency: Double

    init(
        id: String,
        name: String,
        category: SoundCategory,
        type: SoundType,
        isPremium: Bool,
        noiseType: String? = nil,
        baseFrequency: Double = 0
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.isPremium = isPremium
        self.noiseType = noiseType
        self.baseFrequency = baseFrequency
    }

    var iconName: String { category.iconName }
}
