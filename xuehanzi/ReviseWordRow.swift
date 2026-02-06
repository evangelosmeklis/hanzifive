import SwiftUI

struct ReviseWordRow: View {
    let word: Word
    let showMistakeRate: Bool
    let onRemove: () -> Void
    @State private var showFlashcard = false
    @State private var swipeOffset: CGFloat = 0

    private let deleteThreshold: CGFloat = -150

    private var levelColor: Color {
        AppTheme.levelTint(for: word.level)
    }

    private var difficultyColor: Color {
        guard let rs = word.reviewState else { return AppTheme.tertiaryText }
        if rs.ease < 1.5 { return AppTheme.danger }
        if rs.ease < 2.0 { return AppTheme.warning }
        return AppTheme.amber
    }

    private var isPastThreshold: Bool {
        swipeOffset < deleteThreshold
    }

    /// Mistake rate derived from ease factor degradation.
    /// ease 2.5 (default) = 0%, ease 1.3 (minimum) = 100%
    private var mistakePercent: Int {
        let ease = word.reviewState?.ease ?? 2.5
        let pct = (2.5 - ease) / 1.2 * 100
        return Int(max(0, min(100, pct)))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Red delete background (revealed when swiping left)
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(isPastThreshold ? "Release to delete" : "Delete")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.trailing, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isPastThreshold ? AppTheme.danger : AppTheme.danger.opacity(0.85))
            )
            .opacity(swipeOffset < 0 ? 1 : 0)

            // Main card content (no Button — plain view with tap gesture)
            HStack(spacing: 14) {
                // Hanzi
                Text(word.hanzi)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.characterGradient)
                    .frame(width: 48, alignment: .center)

                // Pinyin + meaning
                VStack(alignment: .leading, spacing: 3) {
                    Text(word.pinyin)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(word.meaning)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                // Mistake rate (Frequent tab only)
                if showMistakeRate {
                    Text("\(mistakePercent)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(difficultyColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(difficultyColor.opacity(0.12))
                        )
                }

                // Level pill
                Text(word.level)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(levelColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(levelColor.opacity(0.12))
                    )

                // Difficulty dot
                Circle()
                    .fill(difficultyColor)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            )
            .offset(x: swipeOffset)
            .contentShape(Rectangle())
            .onTapGesture {
                if swipeOffset == 0 {
                    showFlashcard = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        swipeOffset = 0
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    // Only allow left swipe
                    if value.translation.width < 0 {
                        withAnimation(.interactiveSpring()) {
                            swipeOffset = value.translation.width
                        }
                    } else if swipeOffset < 0 {
                        // Allow dragging back to the right
                        withAnimation(.interactiveSpring()) {
                            swipeOffset = min(0, swipeOffset + value.translation.width)
                        }
                    }
                }
                .onEnded { _ in
                    if isPastThreshold {
                        // Animate off screen then remove
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            swipeOffset = -500
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onRemove()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            swipeOffset = 0
                        }
                    }
                }
        )
        .sheet(isPresented: $showFlashcard) {
            SoloFlashcardView(word: word)
        }
    }
}

// MARK: - Solo Flashcard View
struct SoloFlashcardView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.975, blue: 0.96),
                    Color(red: 0.97, green: 0.965, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Flashcard
                FlashcardView(
                    hanzi: word.hanzi,
                    pinyin: word.pinyin,
                    meaning: word.meaning,
                    isRevealed: isRevealed
                )
                .padding(.horizontal, 20)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isRevealed.toggle()
                    }
                }

                Spacer()

                // Level + hint
                VStack(spacing: 8) {
                    Text(word.level)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.levelTint(for: word.level))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(AppTheme.levelTint(for: word.level).opacity(0.12))
                        )

                    Text(isRevealed ? "Tap card to hide" : "Tap card to reveal")
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Detail Chip
struct DetailChip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Date Helper
extension Date {
    var relativeLabel: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: self), to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Yesterday"
        case 2...6: return "\(days)d ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        }
    }
}
