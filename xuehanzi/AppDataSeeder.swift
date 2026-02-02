import Foundation
import SwiftData

@MainActor
enum AppDataSeeder {
    private static let seedVersion = "2026-02-01-hsk-cedict-v2"

    static func seedIfNeeded(modelContext: ModelContext) {
        let storedVersion = UserDefaults.standard.string(forKey: "seedVersion")
        if storedVersion != seedVersion {
            resetData(modelContext: modelContext)
        }

        let descriptor = FetchDescriptor<Word>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        ["HSK1", "HSK2", "HSK3"].forEach { level in
            let url = Bundle.main.url(forResource: level, withExtension: "json", subdirectory: "hsk_levels")
                ?? Bundle.main.url(forResource: level, withExtension: "json")
            guard let url else {
                return
            }

            do {
                let data = try Data(contentsOf: url)
                if let payload = try? JSONDecoder().decode(LevelPayload.self, from: data) {
                    insertLegacyWords(payload: payload, fallbackLevel: level, modelContext: modelContext)
                } else if let payloads = try? JSONDecoder().decode([ModernWordPayload].self, from: data) {
                    insertModernWords(payloads: payloads, level: level, modelContext: modelContext)
                } else {
                    assertionFailure("Unsupported JSON format for \(level)")
                }
            } catch {
                assertionFailure("Failed to load \(level): \(error)")
            }
        }

        try? modelContext.save()
        UserDefaults.standard.set(seedVersion, forKey: "seedVersion")
    }

    private static func insertLegacyWords(payload: LevelPayload, fallbackLevel: String, modelContext: ModelContext) {
        let level = payload.level.isEmpty ? fallbackLevel : payload.level
        payload.words.forEach { wordPayload in
            let reviewState = ReviewState()
            let word = Word(
                hanzi: wordPayload.hanzi,
                pinyin: wordPayload.pinyin,
                meaning: wordPayload.meaning,
                level: level,
                reviewState: reviewState
            )
            modelContext.insert(reviewState)
            modelContext.insert(word)
        }
    }

    private static func insertModernWords(payloads: [ModernWordPayload], level: String, modelContext: ModelContext) {
        payloads.forEach { payload in
            guard let form = payload.forms.first else { return }
            let pinyin = form.transcriptions.pinyin?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let meaning = form.meanings.joined(separator: "; ")
            let reviewState = ReviewState()
            let word = Word(
                hanzi: payload.simplified,
                pinyin: pinyin,
                meaning: meaning,
                level: level,
                reviewState: reviewState
            )
            modelContext.insert(reviewState)
            modelContext.insert(word)
        }
    }

    private static func resetData(modelContext: ModelContext) {
        let wordDescriptor = FetchDescriptor<Word>()
        let reviewDescriptor = FetchDescriptor<ReviewState>()
        let achievementDescriptor = FetchDescriptor<LevelAchievement>()

        (try? modelContext.fetch(wordDescriptor))?.forEach { modelContext.delete($0) }
        (try? modelContext.fetch(reviewDescriptor))?.forEach { modelContext.delete($0) }
        (try? modelContext.fetch(achievementDescriptor))?.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

private struct LevelPayload: Decodable {
    let level: String
    let language: String
    let words: [WordPayload]
}

private struct WordPayload: Decodable {
    let hanzi: String
    let pinyin: String
    let meaning: String
}

private struct ModernWordPayload: Decodable {
    let simplified: String
    let forms: [ModernForm]
}

private struct ModernForm: Decodable {
    let transcriptions: ModernTranscriptions
    let meanings: [String]
}

private struct ModernTranscriptions: Decodable {
    let pinyin: String?
}
