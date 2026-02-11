import SwiftUI

struct StudyLessonSessionView: View {
    let lesson: StudyLesson
    let startInReverse: Bool
    let onComplete: (() -> Void)?
    let onReverseComplete: (() -> Void)?
    let onWritingComplete: (() -> Void)?

    @State private var queue: [StudyLessonCard]
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var dragOffset: CGSize = .zero
    @State private var sessionCorrect = 0
    @State private var sessionTotal = 0
    @State private var feedbackColor: Color = .clear
    @State private var showFeedback = false
    @State private var lastWasCorrect = false
    @State private var isGrading = false
    @State private var didNotifyCompletion = false

    init(
        lesson: StudyLesson,
        startInReverse: Bool = false,
        onComplete: (() -> Void)? = nil,
        onReverseComplete: (() -> Void)? = nil,
        onWritingComplete: (() -> Void)? = nil
    ) {
        self.lesson = lesson
        self.startInReverse = startInReverse
        self.onComplete = onComplete
        self.onReverseComplete = onReverseComplete
        self.onWritingComplete = onWritingComplete
        _queue = State(initialValue: lesson.cards)
    }

    private var currentCard: StudyLessonCard {
        queue[currentIndex]
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if queue.isEmpty || currentIndex >= queue.count {
                completionView
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
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 4) {
                    Text("✓")
                        .font(.caption.weight(.bold))
                    Text("\(sessionCorrect)/\(max(sessionTotal, 1))")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(AppTheme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(AppTheme.success.opacity(0.12)))

                Spacer()

                Text("Card \(currentIndex + 1) of \(queue.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            AnimatedProgressBar(current: currentIndex + 1, total: queue.count, color: AppTheme.info)
        }
        .padding(.horizontal, 20)
    }

    private var flashcardSection: some View {
        ZStack {
            FlashcardView(
                hanzi: currentCard.character,
                pinyin: currentCard.pinyin,
                meaning: currentCard.meaning,
                isRevealed: isRevealed,
                isReversed: startInReverse
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
                        guard !isGrading else { return }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard !isGrading else { return }
                        let threshold: CGFloat = 100
                        if value.translation.width > threshold {
                            triggerGrade(isCorrect: true, showOverlay: false)
                        } else if value.translation.width < -threshold {
                            triggerGrade(isCorrect: false, showOverlay: false)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture {
                guard !isGrading else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isRevealed.toggle()
                }
            }
            .allowsHitTesting(!isGrading)

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

    private var actionButtons: some View {
        HStack(spacing: 56) {
            Button {
                guard !isGrading else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: -80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    triggerGrade(isCorrect: false)
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
            .disabled(isGrading)

            Button {
                guard !isGrading else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: 80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    triggerGrade(isCorrect: true)
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
            .disabled(isGrading)
        }
        .padding(.bottom, 20)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.info.opacity(0.10))
                    .frame(width: 100, height: 100)
                Text("📚")
                    .font(.system(size: 48))
            }

            VStack(spacing: 8) {
                Text("Lesson Complete")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.primaryText)

                Text(startInReverse ? "Reverse mode complete" : "\(lesson.title): \(sessionCorrect)/\(max(sessionTotal, 1)) correct")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if startInReverse {
                NavigationLink {
                    StudyLessonWritingView(lesson: lesson, onComplete: onWritingComplete)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.and.scribble")
                        Text("Practice Writing")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.success)
                    )
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                NavigationLink {
                    StudyLessonSessionView(
                        lesson: lesson,
                        startInReverse: true,
                        onComplete: onReverseComplete,
                        onWritingComplete: onWritingComplete
                    )
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

                NavigationLink {
                    StudyLessonWritingView(lesson: lesson, onComplete: onWritingComplete)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.and.scribble")
                        Text("Practice Writing")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.success.opacity(0.12))
                    )
                }
                .buttonStyle(BounceButtonStyle())
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

    private func triggerGrade(isCorrect: Bool, showOverlay: Bool = true) {
        guard !isGrading else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dragOffset = CGSize(width: isCorrect ? 500 : -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            gradeCurrentCard(isCorrect: isCorrect, showOverlay: showOverlay)
        }
    }

    private func gradeCurrentCard(isCorrect: Bool, showOverlay: Bool) {
        guard !isGrading else { return }
        guard currentIndex >= 0 && currentIndex < queue.count else { return }
        isGrading = true

        sessionTotal += 1
        if isCorrect { sessionCorrect += 1 }

        lastWasCorrect = isCorrect
        if showOverlay {
            feedbackColor = isCorrect ? AppTheme.success : AppTheme.danger
            showFeedback = true
        } else {
            showFeedback = false
        }

        let gradedCard = currentCard
        isRevealed = false

        let advanceDelay: Double = showOverlay ? 0.35 : 0.08
        DispatchQueue.main.asyncAfter(deadline: .now() + advanceDelay) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFeedback = false
            }

            if !isCorrect {
                let insertIndex = min(currentIndex + 4, queue.count)
                queue.insert(gradedCard, at: insertIndex)
            }

            if currentIndex + 1 < queue.count {
                currentIndex += 1
            } else {
                currentIndex = queue.count
                if !didNotifyCompletion {
                    didNotifyCompletion = true
                    onComplete?()
                }
            }

            dragOffset = .zero
            isGrading = false
        }
    }
}
