import Foundation

struct SM2Scheduler {
    static func applyScore(_ score: Int, to state: ReviewState, on date: Date = Date()) {
        let clampedScore = max(0, min(5, score))
        let qualityFactor = Double(5 - clampedScore)
        state.ease = max(1.3, state.ease + 0.1 - (qualityFactor * (0.08 + qualityFactor * 0.02)))
        state.lastReviewed = date
        state.lastScore = clampedScore

        if clampedScore < 3 {
            state.repetitions = 0
            state.interval = 1
        } else {
            state.repetitions += 1
            if state.repetitions == 1 {
                state.interval = 1
            } else if state.repetitions == 2 {
                state.interval = 6
            } else {
                state.interval = state.interval * state.ease
            }
        }

        if let nextDue = Calendar.current.date(byAdding: .day, value: Int(state.interval.rounded()), to: date) {
            state.dueDate = nextDue
        } else {
            state.dueDate = date
        }
    }
}
