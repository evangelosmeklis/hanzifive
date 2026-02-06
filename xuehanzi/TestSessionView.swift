import SwiftUI
import SwiftData

struct TestSessionView: View {
    let level: String
    let part: Int?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var words: [Word]
    @Query private var achievements: [LevelAchievement]

    @State private var queue: [Word] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var isRevealed = false
    @State private var feedbackColor: Color = .clear
    @State private var showFeedback = false
    @State private var showBurst = false
    @State private var finalAccuracy: Double = 0
    @State private var showResults = false
    @State private var lastWasCorrect = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var correctStreak = 0
    @State private var showXPPopup = false
    @State private var sessionXP = 0

    @State private var showStartAlert = true
    @State private var showQuitAlert = false
    @State private var testStarted = false

    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""

    init(level: String, part: Int? = nil) {
        self.level = level
        self.part = part
        _words = Query(filter: #Predicate<Word> { $0.level == level })
        _achievements = Query(filter: #Predicate<LevelAchievement> { $0.level == level })
    }

    private var testTitle: String {
        if let part = part {
            return "\(level) Test - Part \(part)"
        }
        return "\(level) Test"
    }

    private var estimatedMinutes: Int {
        let cardCount = getTestCardCount()
        return max(1, (cardCount * 10) / 60)
    }

    private func getTestCardCount() -> Int {
        if level == "HSK3" { return 300 }
        return words.count
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if !testStarted {
                TestStartView(
                    level: level,
                    part: part,
                    cardCount: getTestCardCount(),
                    estimatedMinutes: estimatedMinutes,
                    onStart: {
                        testStarted = true
                        loadProgressOrStart()
                    },
                    onCancel: { dismiss() }
                )
            } else if queue.isEmpty {
                LoadingView()
            } else if showResults {
                TestResultsView(level: level, accuracy: finalAccuracy, xpEarned: sessionXP, part: part)
            } else {
                VStack(spacing: 16) {
                    headerSection
                    flashcardSection
                    Spacer()
                    swipeHint
                    actionButtons
                }
                .padding(.vertical, 16)
            }

            FeedbackOverlayView(color: feedbackColor, isVisible: showFeedback, isCorrect: lastWasCorrect)

            if showBurst {
                CelebrationBurstView()
            }

            if showXPPopup {
                GeometryReader { geometry in
                    XPPopupView(amount: correctStreak > 2 ? 20 : 15)
                        .position(x: geometry.size.width / 2, y: 150)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(testStarted && !showResults)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Text(level)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.levelTint(for: level))

                    if let part = part {
                        Text("Part \(part)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Text("Test")
                        .font(.headline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if testStarted && !showResults {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showQuitAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Quit")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.danger)
                    }
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert("Quit Test?", isPresented: $showQuitAlert) {
            Button("Continue Test", role: .cancel) { }
            Button("Quit & Lose Progress", role: .destructive) {
                clearProgress()
                dismiss()
            }
        } message: {
            Text("You will lose all progress on this test. Tests must be completed in one sitting.")
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                            Text("+\(sessionXP) XP")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.xpColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.xpColor.opacity(0.12)))

                        HStack(spacing: 4) {
                            Text("✓")
                                .font(.caption.weight(.bold))
                            Text("\(correctCount)/\(currentIndex)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AppTheme.success.opacity(0.12)))

                        if correctStreak > 1 {
                            HStack(spacing: 4) {
                                Text("🎯")
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

                    Text("Question \(currentIndex + 1) of \(queue.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }

            VStack(spacing: 6) {
                AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.levelTint(for: level))

                if currentIndex > 0 {
                    HStack(spacing: 4) {
                        Text("Score:")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.15))
                                    .frame(height: 5)

                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(testAccuracyColor)
                                    .frame(width: max(geometry.size.width * testAccuracy, 0), height: 5)
                            }
                        }
                        .frame(height: 5)

                        Text("\(Int(testAccuracy * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(testAccuracyColor)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.3), value: correctStreak)
        .animation(.spring(response: 0.3), value: currentIndex)
    }

    private var testAccuracy: Double {
        guard currentIndex > 0 else { return 0 }
        return Double(correctCount) / Double(currentIndex)
    }

    private var testAccuracyColor: Color {
        if testAccuracy >= 0.8 { return AppTheme.success }
        else if testAccuracy >= 0.5 { return AppTheme.warning }
        else { return AppTheme.danger }
    }

    // MARK: - Flashcard Section
    private var flashcardSection: some View {
        ZStack {
            FlashcardView(
                hanzi: currentWord.hanzi,
                pinyin: currentWord.pinyin,
                meaning: currentWord.meaning,
                isRevealed: isRevealed
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
                                registerAnswer(isCorrect: true)
                            }
                        } else if value.translation.width < -threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: -500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                registerAnswer(isCorrect: false)
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
            Text("Swipe to answer")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.tertiaryText)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppTheme.success.opacity(0.5))
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 56) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: -80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    registerAnswer(isCorrect: false)
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

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: 80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    registerAnswer(isCorrect: true)
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
        if let part = part {
            return "testProgress-\(level)-part\(part)"
        }
        return "testProgress-\(level)"
    }

    private func loadProgressOrStart() {
        startFresh()
    }

    private func startFresh() {
        var allWords = words.shuffled()
        if level == "HSK3" {
            let midpoint = allWords.count / 2
            if part == 1 {
                allWords = Array(allWords.prefix(midpoint))
            } else if part == 2 {
                allWords = Array(allWords.suffix(from: midpoint))
            }
        }
        queue = allWords
        currentIndex = 0
        correctCount = 0
        isRevealed = false
    }

    private func registerAnswer(isCorrect: Bool) {
        updateDailyProgress()

        if isCorrect {
            correctCount += 1
            correctStreak += 1
            let xpGained = correctStreak > 2 ? 20 : 15
            sessionXP += xpGained
            totalXP += xpGained

            showXPPopup = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showXPPopup = false
            }
        } else {
            correctStreak = 0
        }

        lastWasCorrect = isCorrect
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
            advance()
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

    private func advance() {
        isRevealed = false
        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
            finalAccuracy = queue.isEmpty ? 0 : Double(correctCount) / Double(queue.count)
            if finalAccuracy >= 0.9 {
                upsertAchievement(accuracy: finalAccuracy)
            }
            clearProgress()
            showResults = true
        }
    }

    private func upsertAchievement(accuracy: Double) {
        if level == "HSK3" && part != nil {
            let partKey = "hsk3Part\(part!)Completed"
            UserDefaults.standard.set(accuracy, forKey: partKey)
            let part1 = UserDefaults.standard.double(forKey: "hsk3Part1Completed")
            let part2 = UserDefaults.standard.double(forKey: "hsk3Part2Completed")
            if part1 >= 0.9 && part2 >= 0.9 {
                let combinedAccuracy = (part1 + part2) / 2
                saveFullAchievement(accuracy: combinedAccuracy)
            }
            return
        }
        saveFullAchievement(accuracy: accuracy)
    }

    private func saveFullAchievement(accuracy: Double) {
        if let existing = achievements.first {
            existing.accuracy = max(existing.accuracy, accuracy)
            existing.achievedDate = Date()
        } else {
            let achievement = LevelAchievement(level: level, accuracy: accuracy)
            modelContext.insert(achievement)
        }
        try? modelContext.save()
    }

    private func saveProgress() { }

    private func clearProgress() {
        UserDefaults.standard.removeObject(forKey: progressKey)
    }
}

// MARK: - Test Start View
struct TestStartView: View {
    let level: String
    let part: Int?
    let cardCount: Int
    let estimatedMinutes: Int
    let onStart: () -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 0.9

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.levelTint(for: level).opacity(0.10))
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.levelTint(for: level))
            }
            .scaleEffect(scale)

            VStack(spacing: 8) {
                Text("Ready for the Test?")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                if let part = part {
                    Text("\(level) - Part \(part)")
                        .font(.headline)
                        .foregroundStyle(AppTheme.levelTint(for: level))
                } else {
                    Text(level)
                        .font(.headline)
                        .foregroundStyle(AppTheme.levelTint(for: level))
                }
            }

            VStack(spacing: 12) {
                InfoRow(icon: "doc.text.fill", title: "Questions", value: "\(cardCount) cards", color: AppTheme.info)
                InfoRow(icon: "clock.fill", title: "Estimated Time", value: "~\(estimatedMinutes) min", color: AppTheme.streakColor)
                InfoRow(icon: "exclamationmark.triangle.fill", title: "Important", value: "Complete in one sitting", color: AppTheme.danger)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.background)
            )

            Text("You cannot save progress during a test. Make sure you have enough time.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Test")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.accent)
                    )
                }
                .buttonStyle(BounceButtonStyle())

                Button(action: onCancel) {
                    Text("Not Now")
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}

struct TestProgress: Codable {
    let level: String
    let wordIDs: [UUID]
    let currentIndex: Int
    let correctCount: Int
}
