import SwiftUI
import SwiftData

struct LevelDetailView: View {
    let level: String
    @Query private var words: [Word]

    @State private var showStats = false

    init(level: String) {
        self.level = level
        _words = Query(filter: #Predicate<Word> { $0.level == level })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                statsCard
                actionCards
            }
            .padding(20)
            .maxReadableWidth(700)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showStats = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Text(level)
                        .font(.title.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)

                    if studiedCount >= words.count && words.count > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                            Text("Completed")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(AppTheme.goldAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.goldAccent.opacity(0.12))
                        )
                    }
                }

                Text("\(words.count) words to learn")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("\(studiedCount)/\(words.count) cards learned")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text("\(Int(masteryProgress * 100))%")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(levelTint)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelTint.opacity(0.12))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelTint)
                        .frame(width: showStats ? max(geometry.size.width * masteryProgress, 0) : 0, height: 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: showStats)
                }
            }
            .frame(height: 8)

            // Stats grid
            HStack(spacing: 12) {
                StatBox(
                    icon: "checkmark.circle.fill",
                    value: "\(studiedCount)/\(words.count)",
                    label: "Learned",
                    color: levelTint
                )

                StatBox(
                    icon: "clock.fill",
                    value: "\(dueCount)",
                    label: "Due Now",
                    color: AppTheme.coral
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
        )
        .warmShadow(0.06)
    }

    // MARK: - Action Cards
    private var actionCards: some View {
        NavigationLink {
            StudySessionView(level: level)
        } label: {
            ActionCardClean(
                icon: "book.fill",
                title: "Study Session",
                subtitle: "Focus on words that need review",
                color: AppTheme.accent
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Computed Properties
    private var dueCount: Int {
        words.filter { ($0.reviewState?.dueDate ?? .distantPast) <= Date() }.count
    }

    private var studiedCount: Int {
        words.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
    }

    private var levelTint: Color {
        AppTheme.levelTint(for: level)
    }

    private var masteryProgress: Double {
        guard words.count > 0 else { return 0 }
        return Double(studiedCount) / Double(words.count)
    }
}

// MARK: - Stat Box Component
struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Action Card Clean
struct ActionCardClean: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.card)
        )
        .warmShadow(0.06)
    }
}
