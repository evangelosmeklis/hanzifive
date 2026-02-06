import SwiftUI

struct ReviseWordRow: View {
    let word: Word
    @State private var isExpanded = false

    private var levelColor: Color {
        AppTheme.levelTint(for: word.level)
    }

    private var difficultyColor: Color {
        guard let rs = word.reviewState else { return AppTheme.tertiaryText }
        if rs.ease < 1.5 { return AppTheme.danger }
        if rs.ease < 2.0 { return AppTheme.warning }
        return AppTheme.amber
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(spacing: 0) {
                // Main row — always visible
                HStack(spacing: 14) {
                    // Hanzi
                    Text(word.hanzi)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.characterGradient)
                        .frame(width: 52, alignment: .center)

                    // Pinyin + meaning
                    VStack(alignment: .leading, spacing: 4) {
                        Text(word.pinyin)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text(word.meaning)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Level pill
                    Text(word.level)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(levelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(levelColor.opacity(0.12))
                        )

                    // Difficulty dot
                    Circle()
                        .fill(difficultyColor)
                        .frame(width: 8, height: 8)

                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)

                // Expanded detail
                if isExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 16)

                        // Detail chips
                        HStack(spacing: 10) {
                            DetailChip(
                                label: "Ease",
                                value: String(format: "%.2f", word.reviewState?.ease ?? 2.5),
                                color: difficultyColor
                            )
                            DetailChip(
                                label: "Reps",
                                value: "\(word.reviewState?.repetitions ?? 0)",
                                color: AppTheme.info
                            )
                            if let lastReviewed = word.reviewState?.lastReviewed {
                                DetailChip(
                                    label: "Last",
                                    value: lastReviewed.relativeLabel,
                                    color: AppTheme.secondaryText
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                        // Study link
                        NavigationLink {
                            StudySessionView(level: word.level)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "book.fill")
                                    .font(.caption)
                                Text("Study \(word.level)")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(levelColor)
                            )
                        }
                        .buttonStyle(BounceButtonStyle())
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .buttonStyle(PressableCardStyle())
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
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
