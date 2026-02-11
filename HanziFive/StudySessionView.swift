import SwiftUI
import SwiftData

struct StudySessionView: View {
    let level: String
    let startInReverse: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [Word] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var feedbackColor: Color = .clear
    @State private var showFeedback = false
    @State private var showBurst = false
    @State private var isLoading = true
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var history: [Word] = []
    @State private var showUndoButton = false
    @State private var lastWasCorrect = false
    @State private var correctStreak = 0

    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""
    @AppStorage("uniqueWordsPerLevel") private var uniqueWordsPerLevel: Bool = false

    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var isRandomPractice = false
    @State private var showAllMastered = false
    @State private var hanziOriginalLevel: [String: String] = [:]
    @State private var isReverseMode = false
    @State private var attemptedCards: Set<UUID> = []

    @AppStorage("reverseCompletedLevels") private var reverseCompletedLevels: String = ""

    init(level: String, startInReverse: Bool = false) {
        self.level = level
        self.startInReverse = startInReverse
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if isLoading {
                LoadingView()
            } else if showAllMastered {
                AllMasteredView(level: level, onPracticeRandom: {
                    startRandomPractice()
                }, onStudyReverse: {
                    startReverseStudy()
                })
            } else if queue.isEmpty || currentIndex >= queue.count {
                CompletionView(level: level, totalCards: sessionTotal, correctCards: sessionCorrect, isRandomPractice: isRandomPractice, isReverseMode: isReverseMode)
            } else {
                VStack(spacing: 16) {
                    headerSection
                    flashcardSection
                    Spacer()
                    swipeHint
                    actionButtons
                }
                .padding(.vertical, 16)
                .maxReadableWidth(700)
            }

            FeedbackOverlayView(color: feedbackColor, isVisible: showFeedback, isCorrect: lastWasCorrect)

            if showBurst {
                CelebrationBurstView()
            }

        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(level)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.levelTint(for: level))

                    if isReverseMode {
                        Text("Reverse")
                            .font(.headline)
                            .foregroundStyle(AppTheme.purple)
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.purple)
                    } else if isRandomPractice {
                        Text("Practice")
                            .font(.headline)
                            .foregroundStyle(AppTheme.purple)
                        Image(systemName: "shuffle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.purple)
                    } else {
                        Text("Study")
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            if startInReverse {
                computeHanziOriginalLevel()
                startReverseStudy()
            } else {
                await loadSession()
            }
        }
        .onDisappear {
            saveProgress()
            updateStreak()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("✓")
                                .font(.caption.weight(.bold))
                            Text("\(sessionCorrect)/\(sessionTotal)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.success.opacity(0.12)))

                        if correctStreak > 1 {
                            HStack(spacing: 4) {
                                Text("🔥")
                                    .font(.caption)
                                Text("\(correctStreak)")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(AppTheme.streakColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(AppTheme.streakColor.opacity(0.12)))
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Card \(currentIndex + 1) of \(queue.count)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)

                        if canReorderNewFirst {
                            Button { reorderRemainingFirst() } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.up.to.line")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("New first")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(AppTheme.info)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppTheme.info.opacity(0.10)))
                            }
                            .buttonStyle(BounceButtonStyle())
                        }
                    }
                }

                Spacer()

                if showUndoButton {
                    Button {
                        undoLastAction()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward")
                            Text("Undo")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(AppTheme.accent.opacity(0.10))
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }

            VStack(spacing: 6) {
                AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.levelTint(for: level))

                if sessionTotal > 0 {
                    HStack(spacing: 4) {
                        Text("Accuracy:")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.15))
                                    .frame(height: 5)

                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(accuracyColor)
                                    .frame(width: max(geometry.size.width * sessionAccuracy, 0), height: 5)
                            }
                        }
                        .frame(height: 5)

                        Text("\(Int(sessionAccuracy * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accuracyColor)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.3), value: correctStreak)
        .animation(.spring(response: 0.3), value: sessionTotal)
    }

    private var sessionAccuracy: Double {
        guard sessionTotal > 0 else { return 0 }
        return Double(sessionCorrect) / Double(sessionTotal)
    }

    private var accuracyColor: Color {
        if sessionAccuracy >= 0.8 { return AppTheme.success }
        else if sessionAccuracy >= 0.5 { return AppTheme.warning }
        else { return AppTheme.danger }
    }

    // MARK: - Flashcard Section
    private var flashcardSection: some View {
        ZStack {
            FlashcardView(
                hanzi: currentWord.hanzi,
                pinyin: currentWord.pinyin,
                meaning: currentWord.meaning,
                isRevealed: isRevealed,
                levelLabel: hanziOriginalLevel[currentWord.hanzi],
                isReversed: isReverseMode
            )
            .frame(maxWidth: .infinity)
            .shadow(
                color: dragOffset.width > 0 ? AppTheme.success.opacity(0.5) :
                       dragOffset.width < 0 ? AppTheme.danger.opacity(0.5) :
                       Color.clear,
                radius: 25,
                x: 0,
                y: 12
            )
            .rotationEffect(.degrees(Double(dragOffset.width) * 0.03))
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        cardRotation = Double(value.translation.width) * 0.03
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        if value.translation.width > threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: 500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                gradeCurrentWord(isCorrect: true)
                            }
                        } else if value.translation.width < -threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: -500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                gradeCurrentWord(isCorrect: false)
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = .zero
                                cardRotation = 0
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isRevealed.toggle()
                }
            }

            // Swipe indicators
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.danger.opacity(0.15))
                        .frame(width: 66, height: 66)
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                }
                .opacity(min(max(-dragOffset.width / 80, 0), 1))
                .scaleEffect(min(max(-dragOffset.width / 80, 0.6), 1.2))

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.15))
                        .frame(width: 66, height: 66)
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                }
                .opacity(min(max(dragOffset.width / 80, 0), 1))
                .scaleEffect(min(max(dragOffset.width / 80, 0.6), 1.2))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Swipe Hint
    private var swipeHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left")
                .foregroundStyle(AppTheme.danger.opacity(0.5))
            Text("Swipe to grade")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.tertiaryText)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppTheme.success.opacity(0.5))
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 56) {
            // Wrong
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: -80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    gradeCurrentWord(isCorrect: false)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.danger)
                        .frame(width: 68, height: 68)
                    Image(systemName: "xmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                .warmShadow(0.15)
            }
            .buttonStyle(BounceButtonStyle())

            // Correct
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: 80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    gradeCurrentWord(isCorrect: true)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.success)
                        .frame(width: 68, height: 68)
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                .warmShadow(0.15)
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.bottom, 20)
    }

    private var currentWord: Word {
        queue[currentIndex]
    }

    private var progressKey: String {
        "studyProgress-\(level)"
    }

    private var canReorderNewFirst: Bool {
        guard currentIndex + 1 < queue.count, !isReverseMode, !isRandomPractice else { return false }
        let remaining = queue[(currentIndex + 1)...]
        let hasNew = remaining.contains { ($0.reviewState?.repetitions ?? 0) < 1 && !attemptedCards.contains($0.id) }
        let hasDueOrRequeued = remaining.contains { ($0.reviewState?.repetitions ?? 0) >= 1 || attemptedCards.contains($0.id) }
        return hasNew && hasDueOrRequeued
    }

    private func reorderRemainingFirst() {
        guard currentIndex + 1 < queue.count else { return }
        let remaining = Array(queue[(currentIndex + 1)...])
        // New unlearned cards first, then due/review cards and requeued wrong cards
        let newCards = remaining.filter { ($0.reviewState?.repetitions ?? 0) < 1 && !attemptedCards.contains($0.id) }
        let rest = remaining.filter { !(($0.reviewState?.repetitions ?? 0) < 1 && !attemptedCards.contains($0.id)) }
        queue = Array(queue[...currentIndex]) + newCards + rest
    }

    private func fetchWordsForLevel() -> [Word] {
        let allDescriptor = FetchDescriptor<Word>(sortBy: [SortDescriptor(\.id)])
        let allWords = (try? modelContext.fetch(allDescriptor)) ?? []

        if uniqueWordsPerLevel {
            // Unique mode: only this level's words
            return allWords.filter { $0.level == level }
        } else {
            // Cumulative mode: this level + all lower levels
            let levelNum = Int(level.replacingOccurrences(of: "HSK", with: "")) ?? 1
            let validLevels = Set((1...levelNum).map { "HSK\($0)" })
            return allWords.filter { validLevels.contains($0.level) }
        }
    }

    @MainActor
    private func loadSession() async {
        isLoading = true

        let allWords = fetchWordsForLevel()
        let now = Date()

        let wordsToStudy = allWords.filter { word in
            let reps = word.reviewState?.repetitions ?? 0
            let dueDate = word.reviewState?.dueDate ?? .distantPast
            return reps < 1 || dueDate <= now
        }.shuffled()

        let allStudied = allWords.allSatisfy { ($0.reviewState?.repetitions ?? 0) >= 1 }

        computeHanziOriginalLevel()

        if wordsToStudy.isEmpty && allStudied {
            showAllMastered = true
            isLoading = false
            return
        }

        if let progress = loadProgress(), !wordsToStudy.isEmpty {
            let wordMap = Dictionary(uniqueKeysWithValues: wordsToStudy.map { ($0.id, $0) })
            let restored = progress.wordIDs.compactMap { wordMap[$0] }
            if !restored.isEmpty {
                queue = restored
                currentIndex = min(progress.currentIndex, restored.count - 1)
                isRevealed = false
                history = []
                showUndoButton = false
                sessionTotal = restored.count
                isLoading = false
                return
            }
        }

        queue = wordsToStudy
        sessionTotal = wordsToStudy.count
        currentIndex = 0
        isRevealed = false
        history = []
        showUndoButton = false
        isLoading = false
    }

    private func computeHanziOriginalLevel() {
        let allDBDescriptor = FetchDescriptor<Word>()
        let allDBWords = (try? modelContext.fetch(allDBDescriptor)) ?? []
        var levelMap: [String: String] = [:]
        for word in allDBWords {
            let levelNum = Int(word.level.replacingOccurrences(of: "HSK", with: "")) ?? Int.max
            if let existing = levelMap[word.hanzi],
               let existingNum = Int(existing.replacingOccurrences(of: "HSK", with: "")) {
                if levelNum < existingNum {
                    levelMap[word.hanzi] = word.level
                }
            } else {
                levelMap[word.hanzi] = word.level
            }
        }
        hanziOriginalLevel = levelMap
    }

    private func startRandomPractice() {
        isRandomPractice = true
        showAllMastered = false
        isLoading = true

        let allWords = fetchWordsForLevel()
        let practiceCount = min(20, allWords.count)
        queue = Array(allWords.shuffled().prefix(practiceCount))
        sessionTotal = queue.count
        sessionCorrect = 0
        currentIndex = 0
        isRevealed = false
        history = []
        showUndoButton = false
        correctStreak = 0
        isLoading = false
    }

    private func startReverseStudy() {
        isReverseMode = true
        showAllMastered = false
        isLoading = true

        let allWords = fetchWordsForLevel()
        queue = allWords.shuffled()
        sessionTotal = queue.count
        sessionCorrect = 0
        currentIndex = 0
        isRevealed = false
        history = []
        showUndoButton = false
        correctStreak = 0
        attemptedCards = []
        isLoading = false
    }

    private func markReverseCompleted() {
        let completed = Set(reverseCompletedLevels.split(separator: ",").map(String.init))
        if !completed.contains(level) {
            if reverseCompletedLevels.isEmpty {
                reverseCompletedLevels = level
            } else {
                reverseCompletedLevels += ",\(level)"
            }
        }
    }

    private func saveProgress() {
        guard !queue.isEmpty && currentIndex < queue.count else {
            clearProgress()
            return
        }
        let remainingIDs = Array(queue[currentIndex...].map(\.id))
        let progress = StudyProgress(level: level, wordIDs: remainingIDs, currentIndex: 0)
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() -> StudyProgress? {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else { return nil }
        return try? JSONDecoder().decode(StudyProgress.self, from: data)
    }

    private func clearProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        let previousDateString = lastStudyDateString

        if previousDateString.isEmpty {
            currentStreak = 1
            lastStudyDateString = todayString
            return
        }

        if previousDateString == todayString { return }

        if let lastDate = dateFormatter.date(from: previousDateString) {
            let lastDateStart = Calendar.current.startOfDay(for: lastDate)
            let daysSince = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0
            if daysSince == 1 {
                currentStreak += 1
            } else if daysSince > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastStudyDateString = todayString
    }

    private func gradeCurrentWord(isCorrect: Bool) {
        attemptedCards.insert(currentWord.id)
        history.append(currentWord)
        if history.count > 1 {
            showUndoButton = true
        }

        lastWasCorrect = isCorrect

        if isCorrect {
            sessionCorrect += 1
        }

        updateDailyProgress()

        if isCorrect {
            correctStreak += 1
        } else {
            correctStreak = 0
        }


        if !isRandomPractice && !isReverseMode {
            let reviewState = currentWord.reviewState ?? ReviewState()
            currentWord.reviewState = reviewState
            modelContext.insert(reviewState)
            SM2Scheduler.applyScore(isCorrect ? 4 : 1, to: reviewState)

            // Cross-level sync: propagate mistakes to same hanzi in other levels
            if !isCorrect {
                let currentHanzi = currentWord.hanzi
                let currentWordID = currentWord.id
                let allDescriptor = FetchDescriptor<Word>()
                if let allWords = try? modelContext.fetch(allDescriptor) {
                    for word in allWords where word.hanzi == currentHanzi && word.id != currentWordID {
                        if let rs = word.reviewState {
                            SM2Scheduler.applyScore(1, to: rs)
                        }
                    }
                }
            }

            try? modelContext.save()
        }

        feedbackColor = isCorrect ? AppTheme.success : AppTheme.danger
        showFeedback = true
        showBurst = isCorrect
        Haptics.notify(isCorrect ? .success : .error)
        if isCorrect {
            SoundPlayer.playCorrect()
        } else {
            SoundPlayer.playWrong()
        }

        dragOffset = .zero
        cardRotation = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFeedback = false
                showBurst = false
            }
            advance(reinsert: !isCorrect)
        }
    }

    private func updateDailyProgress() {
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        if lastCardStudyDate != todayString {
            cardsStudiedToday = 0
            lastCardStudyDate = todayString
        }
        cardsStudiedToday += 1
    }

    private func advance(reinsert: Bool) {
        isRevealed = false
        // In reverse mode, never requeue wrong cards
        if reinsert && !isReverseMode {
            let insertIndex = min(currentIndex + 4, queue.count)
            queue.insert(currentWord, at: insertIndex)
        }
        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
            // Session complete
            if isReverseMode {
                markReverseCompleted()
            }
            currentIndex = queue.count
            clearProgress()
        }
        saveProgress()
    }

    private func undoLastAction() {
        guard let lastWord = history.popLast(), currentIndex > 0 else { return }
        currentIndex -= 1
        if queue.last?.id == lastWord.id && queue.count > currentIndex + 1 {
            queue.removeLast()
        }
        if let reviewState = lastWord.reviewState {
            reviewState.repetitions = max(0, reviewState.repetitions - 1)
            try? modelContext.save()
        }
        isRevealed = false
        showUndoButton = history.count > 1
        saveProgress()
    }
}

// MARK: - Supporting Views

struct StudyProgress: Codable {
    let level: String
    let wordIDs: [UUID]
    let currentIndex: Int
}

struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Warm paper background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.975, blue: 0.96),
                    Color(red: 0.97, green: 0.965, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle warm orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.accent.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: animate ? -200 : -180)
                .blur(radius: 60)

            // Subtle indigo orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.characterPrimary.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: -120, y: animate ? 320 : 300)
                .blur(radius: 50)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(AppTheme.characterPrimary.opacity(0.15), lineWidth: 3)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        AppTheme.characterGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }

            Text("Loading deck...")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct AnimatedProgressBar: View {
    let current: Int
    let total: Int
    let color: Color

    @State private var animatedProgress: Double = 0

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(color)
                    .frame(width: max(geometry.size.width * animatedProgress, 0), height: 10)
            }
        }
        .frame(height: 10)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

struct ProgressBarView: View {
    let current: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        AnimatedProgressBar(current: current, total: total, color: AppTheme.accent)
    }
}

struct CompletionView: View {
    let level: String
    let totalCards: Int
    let correctCards: Int
    var isRandomPractice: Bool = false
    var isReverseMode: Bool = false

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -5
    @State private var animatedAccuracy: Double = 0

    private var accuracy: Double {
        guard totalCards > 0 else { return 0 }
        return Double(correctCards) / Double(totalCards)
    }

    private var accuracyColor: Color {
        if accuracy >= 0.8 { return AppTheme.success }
        else if accuracy >= 0.5 { return AppTheme.warning }
        else { return AppTheme.danger }
    }

    private var gradeEmoji: String {
        if accuracy >= 0.9 { return "🌟" }
        else if accuracy >= 0.8 { return "🎉" }
        else if accuracy >= 0.6 { return "👍" }
        else { return "💪" }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(accuracyColor.opacity(0.10))
                        .frame(width: 110, height: 110)

                    Text(gradeEmoji)
                        .font(.system(size: 56))
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text(isReverseMode ? "Reverse Complete!" : isRandomPractice ? "Practice Complete!" : "Session Complete!")
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                }

                // Accuracy Ring
                ZStack {
                    Circle()
                        .stroke(accuracyColor.opacity(0.15), lineWidth: 8)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: animatedAccuracy)
                        .stroke(accuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(accuracy * 100))%")
                            .font(.title3.weight(.black))
                            .foregroundStyle(accuracyColor)
                        Text("Accuracy")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                Text("\(correctCards)/\(totalCards) correct")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)

                // Stats
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(level)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.levelTint(for: level))
                        Text("Level")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.levelTint(for: level).opacity(0.08))
                    )
                }

                if isReverseMode {
                    Text("Reverse mode complete! Your rainbow border awaits.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.purple)
                        .multilineTextAlignment(.center)
                } else if isRandomPractice {
                    Text("Practice mode - progress was not affected.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .warmShadow(0.12)
            )
            .padding(24)

            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedAccuracy = accuracy
            }
            if accuracy >= 0.7 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }
}

struct AllMasteredView: View {
    let level: String
    let onPracticeRandom: () -> Void
    let onStudyReverse: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 0.8
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.goldAccent.opacity(0.10))
                        .frame(width: 110, height: 110)

                    Text("🎓")
                        .font(.system(size: 56))
                }
                .scaleEffect(scale)

                VStack(spacing: 8) {
                    Text("All Caught Up!")
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("全部完成！")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.goldAccent)
                }

                VStack(spacing: 6) {
                    Text("You've studied all cards in \(level)!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("Come back later when cards are due for review, or challenge yourself in reverse!")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 12) {
                    Button {
                        onStudyReverse()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Study in Reverse")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.purple)
                        )
                    }
                    .buttonStyle(BounceButtonStyle())

                    Button {
                        onPracticeRandom()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "shuffle")
                            Text("Practice Random Cards")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.accent)
                        )
                    }
                    .buttonStyle(BounceButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Text("Go Back")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .warmShadow(0.12)
            )
            .padding(24)

            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}
