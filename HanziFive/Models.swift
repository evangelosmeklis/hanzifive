import Foundation
import SwiftData

@Model
final class Word {
    @Attribute(.unique) var id: UUID
    var hanzi: String
    var pinyin: String
    var meaning: String
    var level: String
    var reviewState: ReviewState?

    init(id: UUID = UUID(), hanzi: String, pinyin: String, meaning: String, level: String, reviewState: ReviewState? = nil) {
        self.id = id
        self.hanzi = hanzi
        self.pinyin = pinyin
        self.meaning = meaning
        self.level = level
        self.reviewState = reviewState
    }
}

@Model
final class ReviewState {
    @Attribute(.unique) var id: UUID
    var interval: Double
    var repetitions: Int
    var ease: Double
    var dueDate: Date
    var lastReviewed: Date?
    var lastScore: Int

    init(id: UUID = UUID(), interval: Double = 0, repetitions: Int = 0, ease: Double = 2.5, dueDate: Date = Date(), lastReviewed: Date? = nil, lastScore: Int = 0) {
        self.id = id
        self.interval = interval
        self.repetitions = repetitions
        self.ease = ease
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.lastScore = lastScore
    }
}

@Model
final class LevelAchievement {
    @Attribute(.unique) var id: UUID
    var level: String
    var achievedDate: Date
    var accuracy: Double

    init(id: UUID = UUID(), level: String, achievedDate: Date = Date(), accuracy: Double) {
        self.id = id
        self.level = level
        self.achievedDate = achievedDate
        self.accuracy = accuracy
    }
}

struct LevelSummary: Identifiable {
    let id = UUID()
    let level: String
    let total: Int
    let due: Int
    let studied: Int      // Cards studied at least once correctly (repetitions >= 1)
    let mastered: Int     // Cards fully mastered (repetitions >= 3)
    let achievement: LevelAchievement?
}
