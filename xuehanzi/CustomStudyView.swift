import SwiftUI
import SwiftData

struct CustomStudyView: View {
    let deck: CustomDeck
    var subdeck: String? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [CustomCard] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var feedbackColor: Color = .clear
    @State private var showFeedback = false
    @State private var showBurst = false
    @State private var isLoading = true
    @State private var dragOffset: CGSize = .zero
    @State private var history: [CustomCard] = []
    @State private var showUndoButton = false
    @State private var lastWasCorrect = false
    @State private var showXPPopup = false
    @State private var sessionXP = 0
    @State private var correctStreak = 0
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var showAllStudied = false

    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if isLoading {
                LoadingView()
            } else if showAllStudied {
                allStudiedState
            } else if queue.isEmpty || currentIndex >= queue.count {
                completionState
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
                    Text(subdeck ?? deck.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.customTeal)
                        .lineLimit(1)

                    Text("Study")
                        .font(.headline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadSession()
        }
        .onDisappear {
            updateStreak()
        }
    }

    // MARK: - Header
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
                            Text("\u{2713}")
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
                                Text("\u{1F525}")
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
                        .foregroundStyle(AppTheme.customTeal)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(AppTheme.customTeal.opacity(0.10))
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }

            VStack(spacing: 6) {
                AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.customTeal)

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

    // MARK: - Flashcard
    private var flashcardSection: some View {
        ZStack {
            CustomFlashcardView(
                front: currentCard.front,
                back: currentCard.back,
                isRevealed: isRevealed
            )
            .frame(maxWidth: .infinity)
            .shadow(
                color: dragOffset.width > 0 ? AppTheme.success.opacity(0.5) :
                       dragOffset.width < 0 ? AppTheme.danger.opacity(0.5) :
                       Color.clear,
                radius: 25, x: 0, y: 12
            )
            .rotationEffect(.degrees(Double(dragOffset.width) * 0.03))
            .offset(x: dragOffset.width, y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        if value.translation.width > threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: 500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                gradeCurrentCard(isCorrect: true)
                            }
                        } else if value.translation.width < -threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = CGSize(width: -500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                gradeCurrentCard(isCorrect: false)
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = .zero
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
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: -80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    gradeCurrentCard(isCorrect: false)
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
                    gradeCurrentCard(isCorrect: true)
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

    // MARK: - All Studied State
    private var allStudiedState: some View {
        ZStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(AppTheme.goldAccent.opacity(0.10))
                        .frame(width: 110, height: 110)
                    Text("\u{1F393}")
                        .font(.system(size: 56))
                }

                VStack(spacing: 8) {
                    Text("All Caught Up!")
                        .font(.title2.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("You've studied all cards in this \(subdeck != nil ? "lesson" : "deck")!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)

                    Text("Come back later when cards are due for review.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .warmShadow(0.12)
            )
            .padding(24)
        }
    }

    // MARK: - Completion State
    private var completionState: some View {
        ZStack {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(completionAccuracyColor.opacity(0.10))
                        .frame(width: 110, height: 110)
                    Text(completionEmoji)
                        .font(.system(size: 56))
                }

                Text("Session Complete!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.primaryText)

                // Accuracy ring
                ZStack {
                    Circle()
                        .stroke(completionAccuracyColor.opacity(0.15), lineWidth: 8)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: sessionAccuracy)
                        .stroke(completionAccuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(sessionAccuracy * 100))%")
                            .font(.title3.weight(.black))
                            .foregroundStyle(completionAccuracyColor)
                        Text("Accuracy")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                Text("\(sessionCorrect)/\(sessionTotal) correct")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.subheadline)
                            Text("+\(sessionXP)")
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
                            .fill(AppTheme.xpColor.opacity(0.08))
                    )

                    VStack(spacing: 4) {
                        Text("\(relevantCards.count)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.customTeal)
                        Text("Cards")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.customTeal.opacity(0.08))
                    )
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .warmShadow(0.12)
            )
            .padding(24)

            if sessionAccuracy >= 0.7 {
                ConfettiView()
            }
        }
    }

    private var completionAccuracyColor: Color {
        if sessionAccuracy >= 0.8 { return AppTheme.success }
        else if sessionAccuracy >= 0.5 { return AppTheme.warning }
        else { return AppTheme.danger }
    }

    private var completionEmoji: String {
        if sessionAccuracy >= 0.9 { return "\u{1F31F}" }
        else if sessionAccuracy >= 0.8 { return "\u{1F389}" }
        else if sessionAccuracy >= 0.6 { return "\u{1F44D}" }
        else { return "\u{1F4AA}" }
    }

    private var currentCard: CustomCard {
        queue[currentIndex]
    }

    private var relevantCards: [CustomCard] {
        if let subdeck = subdeck {
            return deck.cards.filter { ($0.subdeck ?? "") == subdeck }
        }
        return deck.cards
    }

    // MARK: - Logic
    @MainActor
    private func loadSession() async {
        isLoading = true
        let now = Date()

        var cardsToStudy = relevantCards.filter { card in
            card.repetitions < 1 || card.dueDate <= now
        }.shuffled()

        // If all cards are already studied and none are due, load all for practice
        if cardsToStudy.isEmpty {
            let allStudied = relevantCards.allSatisfy { $0.repetitions >= 1 }
            if allStudied && !relevantCards.isEmpty {
                cardsToStudy = relevantCards.shuffled()
            } else {
                showAllStudied = true
                isLoading = false
                return
            }
        }

        queue = cardsToStudy
        sessionTotal = cardsToStudy.count
        currentIndex = 0
        isRevealed = false
        history = []
        showUndoButton = false
        isLoading = false
    }

    private func gradeCurrentCard(isCorrect: Bool) {
        history.append(currentCard)
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
            let xpGained = correctStreak > 2 ? 15 : 10
            sessionXP += xpGained
            totalXP += xpGained

            showXPPopup = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showXPPopup = false
            }
        } else {
            correctStreak = 0
        }

        SM2Scheduler.applyScore(isCorrect ? 4 : 1, to: currentCard)
        try? modelContext.save()

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFeedback = false
                showBurst = false
            }
            advance(reinsert: !isCorrect)
        }
    }

    private func advance(reinsert: Bool) {
        isRevealed = false
        if reinsert {
            queue.append(currentCard)
        }
        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else {
            currentIndex = queue.count
        }
    }

    private func undoLastAction() {
        guard let lastCard = history.popLast(), currentIndex > 0 else { return }
        currentIndex -= 1
        if queue.last?.id == lastCard.id && queue.count > currentIndex + 1 {
            queue.removeLast()
        }
        lastCard.repetitions = max(0, lastCard.repetitions - 1)
        try? modelContext.save()
        isRevealed = false
        showUndoButton = history.count > 1
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
}

// MARK: - Custom Flashcard View
struct CustomFlashcardView: View {
    let front: String
    let back: String
    let isRevealed: Bool

    private var frontFontSize: CGFloat {
        if front.count <= 4 { return 80 }
        else if front.count <= 10 { return 52 }
        else if front.count <= 20 { return 36 }
        else { return 28 }
    }

    var body: some View {
        VStack(spacing: 28) {
            // Front text
            ZStack {
                Text(front)
                    .font(.system(size: frontFontSize, weight: .bold))
                    .foregroundStyle(AppTheme.characterPrimary.opacity(0.15))
                    .blur(radius: 30)

                Text(front)
                    .font(.system(size: frontFontSize, weight: .bold))
                    .foregroundStyle(AppTheme.characterGradient)
                    .minimumScaleFactor(0.3)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }

            if isRevealed {
                VStack(spacing: 16) {
                    // Divider
                    RoundedRectangle(cornerRadius: 1)
                        .fill(AppTheme.stroke)
                        .frame(width: 60, height: 2)

                    Text(back)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRevealed)
            } else {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.characterPrimary.opacity(0.06))
                            .frame(width: 56, height: 56)

                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.characterPrimary.opacity(0.5))
                            .symbolEffect(.pulse)
                    }

                    Text("Tap to reveal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.top, 16)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
        .warmShadow(0.10)
    }
}
