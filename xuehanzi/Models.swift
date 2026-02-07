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

// MARK: - Custom Decks (completely separate from HSK)

@Model
final class CustomDeck {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdDate: Date
    @Relationship(deleteRule: .cascade, inverse: \CustomCard.deck) var cards: [CustomCard]

    init(id: UUID = UUID(), name: String, createdDate: Date = Date(), cards: [CustomCard] = []) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
        self.cards = cards
    }
}

@Model
final class CustomCard {
    @Attribute(.unique) var id: UUID
    var front: String
    var back: String
    var subdeck: String?
    var deck: CustomDeck?
    // Embedded review state (separate from HSK ReviewState)
    var interval: Double
    var repetitions: Int
    var ease: Double
    var dueDate: Date
    var lastReviewed: Date?
    var lastScore: Int

    init(id: UUID = UUID(), front: String, back: String, subdeck: String? = nil, deck: CustomDeck? = nil,
         interval: Double = 0, repetitions: Int = 0, ease: Double = 2.5,
         dueDate: Date = Date(), lastReviewed: Date? = nil, lastScore: Int = 0) {
        self.id = id
        self.front = front
        self.back = back
        self.subdeck = subdeck
        self.deck = deck
        self.interval = interval
        self.repetitions = repetitions
        self.ease = ease
        self.dueDate = dueDate
        self.lastReviewed = lastReviewed
        self.lastScore = lastScore
    }
}

// MARK: - HSK Level Summary

struct LevelSummary: Identifiable {
    let id = UUID()
    let level: String
    let total: Int
    let due: Int
    let studied: Int      // Cards studied at least once correctly (repetitions >= 1)
    let mastered: Int     // Cards fully mastered (repetitions >= 3)
    var isReverseCompleted: Bool = false

    var isCompleted: Bool {
        total > 0 && studied >= total
    }
}
