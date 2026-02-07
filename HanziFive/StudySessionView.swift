import SwiftUI
import SwiftData

struct StudySessionView: View {
    let level: String
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
    @State private var showXPPopup = false
    @State private var sessionXP = 0
    @State private var correctStreak = 0
    
    // Gamification storage
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""
    
    // Session stats
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    
    // Random practice mode (doesn't affect review state)
    @State private var isRandomPractice = false
    @State private var showAllMastered = false

    init(level: String) {
        self.level = level
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            if isLoading {
                LoadingView()
            } else if showAllMastered {
                // No cards to study - all mastered!
                AllMasteredView(level: level) {
                    startRandomPractice()
                }
            } else if queue.isEmpty || currentIndex >= queue.count {
                CompletionView(level: level, totalCards: sessionTotal, correctCards: sessionCorrect, xpEarned: sessionXP, isRandomPractice: isRandomPractice)
            } else {
                VStack(spacing: 16) {
                    // Header with progress and stats
                    headerSection
                    
                    // Flashcard with swipe gestures
                    flashcardSection
                    
                    Spacer()
                    
                    // Swipe hint
                    swipeHint
                    
                    // Action buttons
                    actionButtons
                }
                .padding(.vertical, 16)
            }

            // Feedback overlay
            FeedbackOverlayView(color: feedbackColor, isVisible: showFeedback, isCorrect: lastWasCorrect)

            // Celebration effects
            if showBurst {
                CelebrationBurstView()
            }
            
            // XP Popup
            if showXPPopup {
                GeometryReader { geometry in
                    XPPopupView(amount: correctStreak > 2 ? 15 : 10)
                        .position(x: geometry.size.width / 2, y: 150)
                }
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
                    
                    if isRandomPractice {
                        Text("Practice")
                            .font(.headline)
                            .foregroundStyle(AppTheme.lavenderPurple)
                        
                        Image(systemName: "shuffle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.lavenderPurple)
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
            await loadSession()
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
                        // Session XP indicator
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
                        
                        // Correct/Total indicator
                        HStack(spacing: 4) {
                            Text("✓")
                                .font(.caption.weight(.bold))
                            Text("\(sessionCorrect)/\(sessionTotal)")
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
                                Text("🔥")
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

                    Text("Card \(currentIndex + 1) of \(queue.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
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
                            Capsule()
                                .fill(AppTheme.accent.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }

            // Animated progress bar with session stats
            VStack(spacing: 6) {
                AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.levelTint(for: level))
                
                // Accuracy bar
                if sessionTotal > 0 {
                    HStack(spacing: 4) {
                        Text("Accuracy:")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.2))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(accuracyColor)
                                    .frame(width: max(geometry.size.width * sessionAccuracy, 0), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
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
        if sessionAccuracy >= 0.8 {
            return AppTheme.success
        } else if sessionAccuracy >= 0.5 {
            return AppTheme.warning
        } else {
            return AppTheme.danger
        }
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
                // Wrong indicator
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

                // Correct indicator
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
            Text("Swipe to grade")
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
            // Wrong button
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

            // Correct button
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
        "studyProgress-\(level)"
    }

    @MainActor
    private func loadSession() async {
        isLoading = true
        let currentLevel = level

        let allPredicate = #Predicate<Word> { $0.level == currentLevel }
        var allDescriptor = FetchDescriptor<Word>(predicate: allPredicate)
        allDescriptor.sortBy = [SortDescriptor(\.id)]

        let allWords = (try? modelContext.fetch(allDescriptor)) ?? []
        let now = Date()

        // Get words that need study: NEW (never studied) or DUE (need review)
        let wordsToStudy = allWords.filter { word in
            let reps = word.reviewState?.repetitions ?? 0
            let dueDate = word.reviewState?.dueDate ?? .distantPast
            // Include if never studied (reps < 1) OR due for review (dueDate <= now)
            return reps < 1 || dueDate <= now
        }.shuffled()

        // Check if all words have been studied at least once
        let allStudied = allWords.allSatisfy { ($0.reviewState?.repetitions ?? 0) >= 1 }

        if wordsToStudy.isEmpty && allStudied {
            // All cards studied and none are due - show All Caught Up
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
    
    private func startRandomPractice() {
        isRandomPractice = true
        showAllMastered = false
        isLoading = true
        
        // Load all words for random practice (doesn't affect their review state)
        let currentLevel = level
        let allPredicate = #Predicate<Word> { $0.level == currentLevel }
        var allDescriptor = FetchDescriptor<Word>(predicate: allPredicate)
        allDescriptor.sortBy = [SortDescriptor(\.id)]
        
        let allWords = (try? modelContext.fetch(allDescriptor)) ?? []
        
        // Shuffle and take 10-20 random cards for practice
        let practiceCount = min(20, allWords.count)
        queue = Array(allWords.shuffled().prefix(practiceCount))
        sessionTotal = queue.count
        sessionCorrect = 0
        sessionXP = 0
        currentIndex = 0
        isRevealed = false
        history = []
        showUndoButton = false
        correctStreak = 0
        isLoading = false
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
        
        // Get previous study date before updating
        let previousDateString = lastStudyDateString
        
        // If this is the first time studying
        if previousDateString.isEmpty {
            currentStreak = 1
            lastStudyDateString = todayString
            return
        }
        
        // If already studied today, don't increment streak again
        if previousDateString == todayString {
            return
        }
        
        // Parse the previous study date
        if let lastDate = dateFormatter.date(from: previousDateString) {
            let lastDateStart = Calendar.current.startOfDay(for: lastDate)
            let daysSince = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0
            
            if daysSince == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysSince > 1 {
                // Missed days - reset streak
                currentStreak = 1
            }
            // If daysSince == 0, same day, don't change streak
        } else {
            // Can't parse date, start fresh
            currentStreak = 1
        }
        
        // Update last study date to today
        lastStudyDateString = todayString
    }

    private func gradeCurrentWord(isCorrect: Bool) {
        history.append(currentWord)
        if history.count > 1 {
            showUndoButton = true
        }

        lastWasCorrect = isCorrect
        
        // Update session stats (only increment sessionTotal if not already counted)
        if isCorrect {
            sessionCorrect += 1
        }
        
        // Update daily progress
        updateDailyProgress()
        
        // XP and streak logic
        if isCorrect {
            correctStreak += 1
            let xpGained = correctStreak > 2 ? 15 : 10 // Bonus for streaks
            sessionXP += xpGained
            totalXP += xpGained
            
            showXPPopup = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showXPPopup = false
            }
        } else {
            correctStreak = 0
        }

        // Only update review state if NOT in random practice mode
        if !isRandomPractice {
            let reviewState = currentWord.reviewState ?? ReviewState()
            currentWord.reviewState = reviewState
            modelContext.insert(reviewState)
            SM2Scheduler.applyScore(isCorrect ? 4 : 1, to: reviewState)
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
        
        // Reset if it's a new day
        if lastCardStudyDate != todayString {
            cardsStudiedToday = 0
            lastCardStudyDate = todayString
        }
        
        cardsStudiedToday += 1
    }

    private func advance(reinsert: Bool) {
        isRevealed = false

        if reinsert {
            queue.append(currentWord)
        }

        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
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
            // Bright, clean background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Bright blue floating orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.characterPrimary.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: 150, y: animate ? -200 : -180)
                .blur(radius: 50)
            
            // Bright purple floating orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.characterSecondary.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: -120, y: animate ? 320 : 300)
                .blur(radius: 45)
            
            // Mint accent orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.mint.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: animate ? -50 : -30, y: -350)
                .blur(radius: 35)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
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
                    .stroke(AppTheme.characterPrimary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.characterPrimary, AppTheme.characterSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            
            VStack(spacing: 8) {
                Text("Loading deck...")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                
                Text("加载中...")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geometry.size.width * animatedProgress, 0), height: 12)
                    .overlay(
                        // Shine effect
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 6)
                            .offset(y: -3)
                            .mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    )
                    .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
        .frame(height: 12)
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
    let xpEarned: Int
    var isRandomPractice: Bool = false
    
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
    
    private var completionTitle: String {
        isRandomPractice ? "Practice Complete!" : "Session Complete!"
    }
    
    private var completionSubtitle: String {
        isRandomPractice ? "好练习！" : "太棒了！"
    }
    
    private var completionNote: String {
        isRandomPractice ? "Your progress was not affected - this was just practice!" : "Keep practicing to master these characters!"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Trophy animation
                ZStack {
                    Circle()
                        .fill(accuracyColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(accuracyColor.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    
                    Text(gradeEmoji)
                        .font(.system(size: 60))
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)

                VStack(spacing: 10) {
                    Text(completionTitle)
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    
                    Text(completionSubtitle)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(isRandomPractice ? AppTheme.lavenderPurple : AppTheme.accent)
                }
                
                // Accuracy Ring
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(accuracyColor.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: animatedAccuracy)
                            .stroke(accuracyColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(Int(accuracy * 100))%")
                                .font(.title2.weight(.black))
                                .foregroundStyle(accuracyColor)
                            Text("Accuracy")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    
                    Text("\(correctCards)/\(totalCards) correct")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                // Stats Row
                HStack(spacing: 16) {
                    // XP Badge
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.subheadline)
                            Text("+\(xpEarned)")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.xpColor)
                        Text("XP")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.xpColor.opacity(0.1))
                    )
                    
                    // Level Badge
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
                            .fill(AppTheme.levelTint(for: level).opacity(0.1))
                    )
                }

                Text(completionNote)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: accuracyColor.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(accuracyColor.opacity(0.3), lineWidth: 2)
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

// MARK: - All Mastered View (when no cards to study)
struct AllMasteredView: View {
    let level: String
    let onPracticeRandom: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 0.8
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Trophy animation
                ZStack {
                    Circle()
                        .fill(AppTheme.goldAccent.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .stroke(AppTheme.goldAccent.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)
                    
                    Text("🎓")
                        .font(.system(size: 60))
                }
                .scaleEffect(scale)

                VStack(spacing: 10) {
                    Text("All Caught Up!")
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    
                    Text("全部完成！")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.goldAccent)
                }
                
                VStack(spacing: 8) {
                    Text("You've studied all cards in \(level)!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    Text("Come back later when cards are due for review, or practice some random cards to stay sharp!")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    // Practice Random Cards button
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
                                .fill(AppTheme.primaryGradient)
                        )
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(BounceButtonStyle())
                    
                    // Go Back button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                            Text("Go Back")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: AppTheme.goldAccent.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.goldAccent.opacity(0.3), lineWidth: 2)
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
