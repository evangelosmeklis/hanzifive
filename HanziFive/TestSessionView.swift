import SwiftUI
import SwiftData

struct TestSessionView: View {
    let level: String
    let part: Int? // nil for HSK1/HSK2, 1 or 2 for HSK3
    
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
    
    // Alerts
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
        return max(1, (cardCount * 10) / 60) // 10 seconds per card
    }
    
    private func getTestCardCount() -> Int {
        if level == "HSK3" {
            return 300 // Half of HSK3
        }
        return words.count
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()

            if !testStarted {
                // Show start confirmation
                TestStartView(
                    level: level,
                    part: part,
                    cardCount: getTestCardCount(),
                    estimatedMinutes: estimatedMinutes,
                    onStart: {
                        testStarted = true
                        loadProgressOrStart()
                    },
                    onCancel: {
                        dismiss()
                    }
                )
            } else if queue.isEmpty {
                LoadingView()
            } else if showResults {
                TestResultsView(level: level, accuracy: finalAccuracy, xpEarned: sessionXP, part: part)
            } else {
                VStack(spacing: 16) {
                    // Header section
                    headerSection
                    
                    // Flashcard section
                    flashcardSection

                    Spacer()

                    // Swipe hint
                    swipeHint
                    
                    // Action buttons
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
                        // Test XP indicator
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                            Text("+\(sessionXP) XP")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.xpColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.xpColor.opacity(0.15))
                        )
                        
                        // Score indicator
                        HStack(spacing: 4) {
                            Text("✓")
                                .font(.caption.weight(.bold))
                            Text("\(correctCount)/\(currentIndex)")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.success.opacity(0.15))
                        )
                        
                        // Correct streak
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
                            .background(
                                Capsule()
                                    .fill(AppTheme.streakColor.opacity(0.15))
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text("Question \(currentIndex + 1) of \(queue.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }

            // Progress and accuracy bars
            VStack(spacing: 6) {
                AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.levelTint(for: level))
                
                // Accuracy bar
                if currentIndex > 0 {
                    HStack(spacing: 4) {
                        Text("Score:")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(testAccuracyColor)
                                    .frame(width: max(geometry.size.width * testAccuracy, 0), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
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
                color: dragOffset.width > 0 ? AppTheme.success.opacity(0.6) :
                       dragOffset.width < 0 ? AppTheme.danger.opacity(0.6) :
                       AppTheme.accent.opacity(0.2),
                radius: 30,
                x: 0,
                y: 15
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

            // Swipe indicators
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.danger.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                }
                .opacity(min(max(-dragOffset.width / 80, 0), 1))
                .scaleEffect(min(max(-dragOffset.width / 80, 0.6), 1.2))

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.success.opacity(0.2))
                        .frame(width: 70, height: 70)
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
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
                .foregroundStyle(AppTheme.danger.opacity(0.6))
            Text("Swipe to answer")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppTheme.success.opacity(0.6))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 60) {
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
                        .fill(AppTheme.danger.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(AppTheme.danger, lineWidth: 3)
                        .frame(width: 72, height: 72)
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.danger)
                }
                .shadow(color: AppTheme.danger.opacity(0.3), radius: 10, x: 0, y: 5)
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
                        .fill(AppTheme.success.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(AppTheme.success, lineWidth: 3)
                        .frame(width: 72, height: 72)
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.success)
                }
                .shadow(color: AppTheme.success.opacity(0.3), radius: 10, x: 0, y: 5)
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
        // For HSK1/HSK2, no saving - must complete in one sitting
        // For HSK3, we allow parts but each part must be completed in one sitting
        startFresh()
    }

    private func startFresh() {
        var allWords = words.shuffled()
        
        // For HSK3, split into parts
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
        // Update daily progress
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
        
        // Reset if it's a new day
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
        // Only save achievement for full test (not parts) or combine parts
        if level == "HSK3" && part != nil {
            // For HSK3 parts, we could track partial progress separately
            // For now, just save the part completion
            let partKey = "hsk3Part\(part!)Completed"
            UserDefaults.standard.set(accuracy, forKey: partKey)
            
            // Check if both parts are completed with 90%+
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

    private func saveProgress() {
        // No saving for tests - must complete in one sitting
    }

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
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.levelTint(for: level).opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.levelTint(for: level))
            }
            .scaleEffect(scale)
            
            // Title
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
            
            // Info cards
            VStack(spacing: 12) {
                InfoRow(icon: "doc.text.fill", title: "Questions", value: "\(cardCount) cards", color: .blue)
                InfoRow(icon: "clock.fill", title: "Estimated Time", value: "~\(estimatedMinutes) minutes", color: .orange)
                InfoRow(icon: "exclamationmark.triangle.fill", title: "Important", value: "Complete in one sitting", color: .red)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.8))
            )
            
            // Warning text
            Text("⚠️ You cannot save progress during a test. Make sure you have enough time before starting.")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Buttons
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
                            .fill(AppTheme.primaryGradient)
                    )
                    .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 5)
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
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: AppTheme.levelTint(for: level).opacity(0.2), radius: 30, x: 0, y: 15)
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
