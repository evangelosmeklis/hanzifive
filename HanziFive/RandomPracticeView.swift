import SwiftUI
import SwiftData

struct RandomPracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var queue: [Word] = []
    @State private var currentIndex = 0
    @State private var isRevealed = false
    @State private var isLoading = true
    @State private var dragOffset: CGSize = .zero

    private let batchSize = 20

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            if isLoading {
                LoadingView()
            } else if queue.isEmpty {
                noWordsState
            } else if currentIndex >= queue.count {
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
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image("random1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text("Random Practice")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.purple)
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadRandomWords()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.caption)
                        Text("Practice Mode")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(AppTheme.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppTheme.purple.opacity(0.12)))
                }

                Spacer()

                Text("Card \(currentIndex + 1) of \(queue.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(AppTheme.purple.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(AppTheme.purple)
                        .frame(width: max(geometry.size.width * progress, 0), height: 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentIndex)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 20)
    }

    private var progress: Double {
        guard queue.count > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(queue.count)
    }

    // MARK: - Flashcard
    private var flashcardSection: some View {
        ZStack {
            if currentIndex < queue.count {
                let word = queue[currentIndex]

                FlashcardView(
                    hanzi: word.hanzi,
                    pinyin: word.pinyin,
                    meaning: word.meaning,
                    isRevealed: isRevealed
                )
                .frame(maxWidth: .infinity)
                .rotationEffect(.degrees(Double(dragOffset.width) * 0.03))
                .offset(x: dragOffset.width, y: dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            if abs(value.translation.width) > threshold {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    dragOffset = CGSize(width: value.translation.width > 0 ? 500 : -500, height: 0)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    advance()
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

                // Level pill overlay
                VStack {
                    HStack {
                        Text(word.level)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.levelTint(for: word.level))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(AppTheme.levelTint(for: word.level).opacity(0.12))
                            )
                        Spacer()
                    }
                    .padding(.leading, 28)
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Swipe Hint
    private var swipeHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left")
                .foregroundStyle(AppTheme.tertiaryText.opacity(0.5))
            Text("Swipe for next")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.tertiaryText)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppTheme.tertiaryText.opacity(0.5))
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
                    advance()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.purple.opacity(0.15))
                        .frame(width: 68, height: 68)
                    Image(systemName: "arrow.left")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.purple)
                }
            }
            .buttonStyle(BounceButtonStyle())

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragOffset = CGSize(width: 80, height: 0)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dragOffset = .zero
                    advance()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.purple.opacity(0.15))
                        .frame(width: 68, height: 68)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.purple)
                }
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(.bottom, 20)
    }

    // MARK: - Empty / Completion States
    private var noWordsState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.info.opacity(0.10))
                    .frame(width: 100, height: 100)
                Image(systemName: "book.closed")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.info)
            }

            VStack(spacing: 8) {
                Text("No Words Yet")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Study some words first, then come back\nto practice them randomly!")
                    .font(.subheadline)
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
    }

    private var completionState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.purple.opacity(0.10))
                    .frame(width: 100, height: 100)
                Text("🎲")
                    .font(.system(size: 48))
            }

            VStack(spacing: 8) {
                Text("Nice Review!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppTheme.primaryText)

                Text("You reviewed \(queue.count) random words.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text("Practice mode \u{2014} no progress was affected.")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
                .multilineTextAlignment(.center)

            Button {
                Task { await loadRandomWords() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("Shuffle Again")
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
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .warmShadow(0.12)
        )
        .padding(24)
    }

    // MARK: - Logic
    private func advance() {
        isRevealed = false
        dragOffset = .zero
        if currentIndex + 1 <= queue.count {
            currentIndex += 1
        }
    }

    @MainActor
    private func loadRandomWords() async {
        isLoading = true
        currentIndex = 0
        isRevealed = false
        dragOffset = .zero

        let descriptor = FetchDescriptor<Word>()
        let allWords = (try? modelContext.fetch(descriptor)) ?? []

        // Only words the user has already learned (repetitions >= 1)
        let learnedWords = allWords.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }
        queue = Array(learnedWords.shuffled().prefix(batchSize))
        isLoading = false
    }
}
