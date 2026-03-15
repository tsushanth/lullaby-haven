//
//  FavoriteSound.swift
//  LullabyHaven
//
//  SwiftData model for persisted favorite sounds
//

import Foundation
import SwiftData

@Model
final class FavoriteSound {
    @Attribute(.unique) var soundID: String
    var addedAt: Date
    var sortOrder: Int

    init(soundID: String, sortOrder: Int = 0) {
        self.soundID = soundID
        self.addedAt = Date()
        self.sortOrder = sortOrder
    }
}
