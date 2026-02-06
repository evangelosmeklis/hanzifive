import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var words: [Word]
    @Query private var achievements: [LevelAchievement]
    @State private var showingSettings = false

    // Streak tracking
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                statsRow
                dailyProgressCard
                levelsSectionHeader

                ForEach(levelSummaries) { summary in
                    LevelCardView(summary: summary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            resetDailyProgressIfNeeded()
            updateStreak()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)

                Text("学汉字")
                    .font(.system(size: 34, weight: .black, design: .serif))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.06), lineWidth: 1)
                        )

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Streak card
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.streakColor.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Text("🔥")
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(currentStreak)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Day Streak")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )

            // Words learned card
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.success.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.success)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(totalStudied)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Learned")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )

            Spacer()
        }
    }

    // MARK: - Daily Progress Card
    private var dailyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Daily Goal")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                if dailyProgress >= 1.0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Complete!")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppTheme.success))
                }
            }

            HStack(spacing: 20) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.10), lineWidth: 7)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: dailyProgress)
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(cardsStudiedToday)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.accent)
                        Text("/\(dailyGoal)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Today's Progress")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(Int(dailyProgress * 100))% of daily goal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accent.opacity(0.10))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accent)
                                .frame(width: max(geometry.size.width * dailyProgress, 0), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Button {
                        showingSettings = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption2)
                            Text("Edit Goal")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(AppTheme.accent.opacity(0.10))
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Levels Section Header
    private var levelsSectionHeader: some View {
        HStack {
            Text("HSK Levels")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            Text("\(totalStudied) learned")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 4)
    }

    // MARK: - Computed Properties
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

    private var totalStudied: Int {
        words.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
    }

    private var dailyProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(cardsStudiedToday) / Double(dailyGoal))
    }

    private func levelSort(_ lhs: String, _ rhs: String) -> Bool {
        let leftValue = Int(lhs.replacingOccurrences(of: "HSK", with: "")) ?? 0
        let rightValue = Int(rhs.replacingOccurrences(of: "HSK", with: "")) ?? 0
        return leftValue < rightValue
    }

    private func resetDailyProgressIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        if lastCardStudyDate != todayString {
            cardsStudiedToday = 0
            lastCardStudyDate = todayString
        }
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard !lastStudyDateString.isEmpty else { return }
        guard let lastDate = dateFormatter.date(from: lastStudyDateString) else { return }
        let lastDateStart = Calendar.current.startOfDay(for: lastDate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0
        if daysSince > 1 {
            currentStreak = 0
        }
    }
}

// MARK: - Level Card View
struct LevelCardView: View {
    let summary: LevelSummary

    private var isCompleted: Bool {
        summary.achievement != nil && (summary.achievement?.accuracy ?? 0) >= 0.9
    }

    private var levelColor: Color {
        AppTheme.levelTint(for: summary.level)
    }

    private var progress: Double {
        guard summary.total > 0 else { return 0 }
        return Double(summary.studied) / Double(summary.total)
    }

    private var levelIcon: String {
        let levelNum = Int(summary.level.replacingOccurrences(of: "HSK", with: "")) ?? 1
        switch levelNum {
        case 1: return "一"
        case 2: return "二"
        case 3: return "三"
        case 4: return "四"
        case 5: return "五"
        case 6: return "六"
        default: return "书"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top: level info
            HStack(spacing: 14) {
                // Level badge
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isCompleted ?
                            LinearGradient(colors: [AppTheme.goldAccent, AppTheme.goldAccent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [levelColor, levelColor.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)

                    if isCompleted {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    } else {
                        Text(levelIcon)
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(summary.level)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)

                        Text("\(summary.total) words")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        Spacer()

                        if isCompleted {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("Mastered")
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.goldAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(AppTheme.goldAccent.opacity(0.12))
                            )
                        } else if summary.studied >= summary.total {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Completed Learning")
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppTheme.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(AppTheme.success.opacity(0.12))
                            )
                        } else {
                            let remaining = summary.total - summary.studied
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 5, height: 5)
                                Text("\(remaining) to finish study")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.accent)
                        }
                    }

                    // Progress info
                    HStack(spacing: 4) {
                        Text("\(summary.studied)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(levelColor)
                        Text("of \(summary.total) learned")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(levelColor.opacity(0.12))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    isCompleted ?
                                    LinearGradient(colors: [AppTheme.goldAccent, AppTheme.goldAccent.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [levelColor, levelColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: max(geometry.size.width * progress, 0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                NavigationLink {
                    StudySessionView(level: summary.level)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text("Study")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(levelColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(levelColor.opacity(0.10))
                    )
                }
                .buttonStyle(BounceButtonStyle())

                NavigationLink {
                    TestSessionView(level: summary.level)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .font(.caption)
                        Text("Test")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(levelColor)
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0

    @State private var selectedGoal: Int = 10

    let goalOptions = [5, 10, 15, 20, 30, 50]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.08))
                                .frame(width: 72, height: 72)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Text("Settings")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    .padding(.top, 20)

                    // Daily Goal Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Goal")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                            }

                            Spacer()

                            Text("\(selectedGoal) cards")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Text("How many cards do you want to study each day?")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(goalOptions, id: \.self) { goal in
                                Button {
                                    selectedGoal = goal
                                } label: {
                                    VStack(spacing: 4) {
                                        Text("\(goal)")
                                            .font(.title3.weight(.bold))
                                        Text("cards")
                                            .font(.caption)
                                    }
                                    .foregroundStyle(selectedGoal == goal ? .white : AppTheme.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(selectedGoal == goal ? AppTheme.accent : AppTheme.accent.opacity(0.08))
                                    )
                                }
                                .buttonStyle(BounceButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    )

                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Stats")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)

                        HStack(spacing: 16) {
                            StatCard(icon: "flame.fill", value: "\(currentStreak)", label: "Day Streak", color: AppTheme.streakColor)
                            StatCard(icon: "checkmark.circle.fill", value: "\(cardsStudiedToday)", label: "Today", color: AppTheme.success)
                        }

                        HStack(spacing: 16) {
                            StatCard(icon: "target", value: "\(dailyGoal)", label: "Goal", color: AppTheme.accent)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    )
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dailyGoal = selectedGoal
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .onAppear {
                selectedGoal = dailyGoal
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
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
                .font(.title3.weight(.bold))
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Legacy components
struct StatsBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
}

struct FloatingOrbsBackground: View {
    var body: some View {
        EmptyView()
    }
}

struct MiniStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
