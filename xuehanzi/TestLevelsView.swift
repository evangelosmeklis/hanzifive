import SwiftUI
import SwiftData

struct TestLevelsView: View {
    @Query private var words: [Word]
    @Query private var achievements: [LevelAchievement]

    private let quickActions = [
        QuickAction(title: "完整测试", subtitle: "测试整个级别", color: AppTheme.accent),
        QuickAction(title: "准确率", subtitle: "查看测试成绩", color: AppTheme.info),
        QuickAction(title: "徽章", subtitle: "解锁成就", color: AppTheme.goldAccent),
        QuickAction(title: "历史记录", subtitle: "查看过往测试", color: AppTheme.warning)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.imperialGradient)
                            .frame(width: 6, height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("测试")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(AppTheme.accent)

                            Text("HSK Test")
                                .font(.largeTitle.bold())
                                .fontDesign(.serif)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }

                    Text("通过测试解锁星星徽章")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent.opacity(0.8))
                        .padding(.leading, 18)

                    Text("Unlock stars by completing full level tests")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.leading, 18)
                }
                .padding(.top, 12)

                SearchBarView(placeholder: "搜索级别测试")

                // Category Cards inspired by Chinese app design
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(quickActions.prefix(2)) { action in
                            QuickActionCard(action: action)
                        }
                    }
                    HStack(spacing: 12) {
                        ForEach(quickActions.suffix(2)) { action in
                            QuickActionCard(action: action)
                        }
                    }
                }

                BannerCardView(
                    title: "测试挑战",
                    subtitle: "达到90%以上获得金色星星",
                    highlight: "90%+"
                )

                HStack {
                    Text("HSK Levels")
                        .font(.title3.bold())
                        .fontDesign(.serif)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                }
                .padding(.top, 8)

                ForEach(levelSummaries) { summary in
                    NavigationLink {
                        TestSessionView(level: summary.level)
                    } label: {
                        TestLevelCardView(summary: summary)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .padding(24)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 250, height: 250)
                    .offset(x: 100, y: -100)
                Circle()
                    .fill(AppTheme.goldAccent.opacity(0.08))
                    .frame(width: 150, height: 150)
                    .offset(x: 60, y: -60)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(AppTheme.levelColors[3].opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: -80, y: 100)
        }
    }

    private var levelSummaries: [LevelSummary] {
        let grouped = Dictionary(grouping: words, by: \.level)
        return grouped.keys.sorted(by: levelSort).map { level in
            let levelWords = grouped[level, default: []]
            let dueCount = levelWords.filter { ($0.reviewState?.dueDate ?? .distantPast) <= Date() }.count
            let studiedCount = levelWords.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
            let masteredCount = levelWords.filter { ($0.reviewState?.repetitions ?? 0) >= 3 }.count
            let achievement = achievements.first(where: { $0.level == level })
            return LevelSummary(level: level, total: levelWords.count, due: dueCount, studied: studiedCount, mastered: masteredCount, achievement: achievement)
        }
    }

    private func levelSort(_ lhs: String, _ rhs: String) -> Bool {
        let leftValue = Int(lhs.replacingOccurrences(of: "HSK", with: "")) ?? 0
        let rightValue = Int(rhs.replacingOccurrences(of: "HSK", with: "")) ?? 0
        return leftValue < rightValue
    }
}

struct TestLevelCardView: View {
    let summary: LevelSummary

    var body: some View {
        let levelColor = AppTheme.levelTint(for: summary.level)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Text(summary.level)
                        .font(.title2.bold())
                        .fontDesign(.serif)
                        .foregroundStyle(levelColor)

                    if summary.achievement != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("Completed")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.goldAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.goldAccent.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.goldAccent.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                }

                Spacer()

                if summary.achievement != nil {
                    Text("90%+")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.goldAccent)
                }
            }

            HStack(spacing: 16) {
                StatItem(title: "总数", value: "\(summary.total)", color: levelColor)
                StatItem(title: "最佳", value: summary.achievement != nil ? "90%+" : "–", color: AppTheme.goldAccent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(levelColor.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: levelColor.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}
