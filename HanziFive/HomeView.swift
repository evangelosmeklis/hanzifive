import SwiftUI
import SwiftData
import UserNotifications

struct HomeView: View {
    @Query private var words: [Word]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingSettings = false
    @State private var showingHelp = false

    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""
    @AppStorage("uniqueWordsPerLevel") private var uniqueWordsPerLevel: Bool = false
    @AppStorage("reverseCompletedLevels") private var reverseCompletedLevels: String = ""

    private var reverseCompletedSet: Set<String> {
        Set(reverseCompletedLevels.split(separator: ",").map(String.init))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero banner
                heroBanner

                VStack(spacing: 20) {
                    // Quick stats strip
                    quickStatsStrip
                        .padding(.top, -28) // overlap into banner

                    // Quick action icon grid
                    quickActionGrid

                    // Level cards
                    levelsSectionHeader

                    ForEach(levelSummaries) { summary in
                        LevelCardView(summary: summary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
                .maxReadableWidth(720)
            }
        }
        .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
        .onAppear {
            resetDailyProgressIfNeeded()
            updateStreak()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        else if hour < 17 { return "Good afternoon" }
        else { return "Good evening" }
    }

    // MARK: - Hero Banner (Meituan-style gradient header)
    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            // Bold gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.30, blue: 0.18),
                    Color(red: 0.92, green: 0.42, blue: 0.15),
                    Color(red: 0.95, green: 0.55, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 220, y: -40)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 140, height: 140)
                .offset(x: -30, y: 100)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))

                        Text("汉字5")
                            .font(.system(size: 32, weight: .black, design: .serif))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button {
                            showingHelp = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.20))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "questionmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.20))
                                    .frame(width: 40, height: 40)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                // Daily progress inline
                HStack(spacing: 16) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.20), lineWidth: 5)
                            .frame(width: 56, height: 56)

                        Circle()
                            .trim(from: 0, to: dailyProgress)
                            .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(cardsStudiedToday)")
                                .font(.headline.weight(.black))
                                .foregroundStyle(.white)
                            Text("/\(dailyGoal)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("Daily Goal")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)

                            if dailyProgress >= 1.0 {
                                Text("DONE")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(Color(red: 0.88, green: 0.30, blue: 0.18))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(.white)
                                    )
                            }
                        }

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.20))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white)
                                    .frame(width: max(geo.size.width * dailyProgress, 0), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(Int(dailyProgress * 100))% complete today")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .padding(.bottom, 36) // space for overlapping stats strip
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .clipShape(
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
        )
    }

    // MARK: - Quick Stats Strip (floating pills overlapping banner)
    private var quickStatsStrip: some View {
        HStack(spacing: 10) {
            // Streak
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.warning.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image("usefire")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(currentStreak)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Day Streak")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )

            // Learned
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.success.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image("useflashcards")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(totalStudied)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Learned")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )

            // Total words
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.info.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image("usehanzi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(totalUniqueWords)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Total")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Quick Action Grid (Chinese super-app icon grid)
    private var quickActionGrid: some View {
        let columnCount = horizontalSizeClass == .regular ? 6 : 4
        let columns = Array(repeating: GridItem(.flexible()), count: columnCount)

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(levelSummaries.prefix(6)) { summary in
                NavigationLink {
                    StudySessionView(level: summary.level)
                } label: {
                    VStack(spacing: 8) {
                        if levelHasIcon(summary.level) {
                            Image(levelIconName(summary.level))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.levelTint(for: summary.level),
                                                AppTheme.levelTint(for: summary.level).opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Text(summary.level)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(summary.level)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                }
                .buttonStyle(BounceButtonStyle())
            }

            // Random practice icon
            NavigationLink {
                RandomPracticeView()
            } label: {
                VStack(spacing: 8) {
                    Image("random1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("Random")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }

    // MARK: - Levels Section Header
    private var levelsSectionHeader: some View {
        HStack {
            Text("HSK Levels")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            Text("\(totalStudied) learned")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers
    private func levelHasIcon(_ level: String) -> Bool {
        let num = Int(level.replacingOccurrences(of: "HSK", with: "")) ?? 0
        return num >= 1 && num <= 3
    }

    private func levelIconName(_ level: String) -> String {
        let num = Int(level.replacingOccurrences(of: "HSK", with: "")) ?? 1
        return "hsk\(num)"
    }

    // MARK: - Computed Properties
    private var levelSummaries: [LevelSummary] {
        let grouped = Dictionary(grouping: words, by: \.level)
        let sortedLevels = grouped.keys.sorted(by: levelSort)

        if uniqueWordsPerLevel {
            // Unique mode: each level shows only its own words
            return sortedLevels.map { level in
                let levelWords = grouped[level, default: []]
                let dueCount = levelWords.filter { ($0.reviewState?.dueDate ?? .distantPast) <= Date() }.count
                let studiedCount = levelWords.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
                let masteredCount = levelWords.filter { ($0.reviewState?.repetitions ?? 0) >= 3 }.count
                return LevelSummary(level: level, total: levelWords.count, due: dueCount, studied: studiedCount, mastered: masteredCount, isReverseCompleted: reverseCompletedSet.contains(level))
            }
        } else {
            // Cumulative mode: each level includes all lower levels' words
            var accumulated: [Word] = []
            return sortedLevels.map { level in
                accumulated += grouped[level, default: []]
                let dueCount = accumulated.filter { ($0.reviewState?.dueDate ?? .distantPast) <= Date() }.count
                let studiedCount = accumulated.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
                let masteredCount = accumulated.filter { ($0.reviewState?.repetitions ?? 0) >= 3 }.count
                return LevelSummary(level: level, total: accumulated.count, due: dueCount, studied: studiedCount, mastered: masteredCount, isReverseCompleted: reverseCompletedSet.contains(level))
            }
        }
    }

    private var totalStudied: Int {
        words.filter { ($0.reviewState?.repetitions ?? 0) >= 1 }.count
    }

    private var totalUniqueWords: Int {
        Set(words.map(\.hanzi)).count
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

    private var levelColor: Color {
        AppTheme.levelTint(for: summary.level)
    }

    private var progress: Double {
        guard summary.total > 0 else { return 0 }
        return Double(summary.studied) / Double(summary.total)
    }

    private var hasLevelIcon: Bool {
        let num = Int(summary.level.replacingOccurrences(of: "HSK", with: "")) ?? 0
        return num >= 1 && num <= 3
    }

    private var levelIconName: String {
        let num = Int(summary.level.replacingOccurrences(of: "HSK", with: "")) ?? 1
        return "hsk\(num)"
    }

    var body: some View {
        NavigationLink {
            StudySessionView(level: summary.level)
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    // Level icon (60x60)
                    if hasLevelIcon {
                        Image(levelIconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(colors: [levelColor, levelColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 60, height: 60)

                            Text(summary.level)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(summary.level)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)

                            Spacer()

                            // Status badge
                            if summary.isCompleted && summary.isReverseCompleted {
                                HStack(spacing: 3) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 8))
                                    Text("Mastered")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.purple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(AppTheme.purple.opacity(0.12))
                                )
                            } else if summary.isCompleted {
                                HStack(spacing: 3) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 8))
                                    Text("Completed")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.goldAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(AppTheme.goldAccent.opacity(0.12))
                                )
                            } else {
                                let remaining = summary.total - summary.studied
                                Text("\(remaining) left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.danger)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(AppTheme.danger.opacity(0.10))
                                    )
                            }
                        }

                        // Progress bar (8pt height)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(levelColor.opacity(0.12))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        summary.isCompleted && summary.isReverseCompleted ?
                                        LinearGradient(colors: [AppTheme.accent, AppTheme.amber, AppTheme.success, AppTheme.purple], startPoint: .leading, endPoint: .trailing) :
                                        summary.isCompleted ?
                                        LinearGradient(colors: [AppTheme.goldAccent, AppTheme.goldAccent.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [levelColor, levelColor.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: max(geometry.size.width * progress, 0), height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Stats row
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(summary.studied)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(levelColor)
                                Text("of \(summary.total) learned")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            if !summary.isCompleted {
                                let remaining = summary.total - summary.studied
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.tertiaryText)
                                HStack(spacing: 2) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 8))
                                    Text("\(remaining) to finish")
                                        .font(.caption2.weight(.medium))
                                }
                                .foregroundStyle(AppTheme.coral)
                            }

                            Spacer()

                            // Tap hint
                            HStack(spacing: 2) {
                                Text("Tap to study")
                                    .font(.system(size: 9, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 7, weight: .semibold))
                            }
                            .foregroundStyle(AppTheme.tertiaryText)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
                    .shadow(color: summary.isCompleted ? .clear : .black.opacity(0.05), radius: 6, y: 2)
            )
            .modifier(ConditionalShimmer(isActive: summary.isCompleted, isRainbow: summary.isReverseCompleted))
        }
        .buttonStyle(BounceButtonStyle())
        .overlay(alignment: .topTrailing) {
            // Study in Reverse banner for completed levels
            if summary.isCompleted && !summary.isReverseCompleted {
                NavigationLink {
                    StudySessionView(level: summary.level, startInReverse: true)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Study in Reverse")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.purple)
                    )
                    .shadow(color: AppTheme.purple.opacity(0.3), radius: 6, y: 2)
                }
                .offset(y: -12)
                .padding(.trailing, 8)
            }
        }
    }
}

// MARK: - Conditional Shimmer Modifier
struct ConditionalShimmer: ViewModifier {
    let isActive: Bool
    var isRainbow: Bool = false

    func body(content: Content) -> some View {
        if isActive && isRainbow {
            content.shimmeringRainbowBorder(cornerRadius: 18)
        } else if isActive {
            content.shimmeringGoldBorder(cornerRadius: 18)
        } else {
            content
        }
    }
}

// MARK: - Study Reminder Model
struct StudyReminder: Codable, Identifiable {
    var id: UUID = UUID()
    var time: Date
    var isEnabled: Bool
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("uniqueWordsPerLevel") private var uniqueWordsPerLevel: Bool = false

    @State private var reminders: [StudyReminder] = []
    @State private var notificationsAuthorized = false

    let goalOptions = [5, 10, 15, 20, 30, 50]
    private let defaultTimes: [(Int, Int)] = [(9, 0), (13, 0), (19, 0)]

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

                    // Daily Goal - Dropdown
                    dailyGoalSection

                    // Study Reminders
                    remindersSection

                    // Word Display Mode
                    wordModeSection
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveReminders()
                        scheduleNotifications()
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .onAppear {
                loadReminders()
                checkNotificationAuth()
            }
        }
    }

    // MARK: - Daily Goal Section
    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)

                Text("Daily Goal")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Menu {
                    ForEach(goalOptions, id: \.self) { goal in
                        Button {
                            dailyGoal = goal
                        } label: {
                            if dailyGoal == goal {
                                Label("\(goal) cards", systemImage: "checkmark")
                            } else {
                                Text("\(goal) cards")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("\(dailyGoal) cards")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.10))
                    )
                }
            }

            Text("How many cards do you want to study each day?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }

    // MARK: - Reminders Section
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.streakColor)

                Text("Study Reminders")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                if reminders.count < 3 {
                    Button {
                        addReminder()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Add")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(AppTheme.accent.opacity(0.10))
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }

            Text("Get daily reminders to keep your streak going.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)

            if reminders.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.title2)
                            .foregroundStyle(AppTheme.tertiaryText)
                        Text("No reminders set")
                            .font(.caption)
                            .foregroundStyle(AppTheme.tertiaryText)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(Array(reminders.enumerated()), id: \.element.id) { index, _ in
                    HStack(spacing: 12) {
                        Toggle("", isOn: $reminders[index].isEnabled)
                            .labelsHidden()
                            .tint(AppTheme.accent)

                        DatePicker(
                            "",
                            selection: $reminders[index].time,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()

                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                removeReminder(at: index)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.danger.opacity(0.7))
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(reminders[index].isEnabled ? AppTheme.streakColor.opacity(0.06) : Color.gray.opacity(0.06))
                    )
                }
            }

            if !notificationsAuthorized && !reminders.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.warning)
                    Text("Enable notifications in Settings to receive reminders.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.warning.opacity(0.08))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }

    // MARK: - Word Mode Section
    private var wordModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "textformat.size.zh")
                    .font(.title3)
                    .foregroundStyle(AppTheme.info)

                Text("Word Display")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Toggle(isOn: $uniqueWordsPerLevel) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unique words per level")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)

                    Text(uniqueWordsPerLevel
                         ? "Each level shows only its own new words."
                         : "Higher levels include words from previous levels.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .tint(AppTheme.accent)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        )
    }

    // MARK: - Reminder Helpers
    private func addReminder() {
        guard reminders.count < 3 else { return }
        let defaultTime = defaultTimes[reminders.count]
        let date = Calendar.current.date(from: DateComponents(hour: defaultTime.0, minute: defaultTime.1)) ?? Date()
        withAnimation(.spring(response: 0.3)) {
            reminders.append(StudyReminder(time: date, isEnabled: true))
        }
        requestNotificationPermission()
    }

    private func removeReminder(at index: Int) {
        reminders.remove(at: index)
    }

    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "studyReminders"),
           let decoded = try? JSONDecoder().decode([StudyReminder].self, from: data) {
            reminders = decoded
        }
    }

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "studyReminders")
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for (index, reminder) in reminders.enumerated() where reminder.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Time to Study!"
            content.body = "Keep your streak going — practice your Chinese characters today."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: reminder.time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "studyReminder-\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsAuthorized = granted
            }
        }
    }

    private func checkNotificationAuth() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
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

// MARK: - Help View
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("汉字5")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundStyle(AppTheme.accent)

                        Text("Learn Chinese Characters")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.top, 20)

                    // What is this app
                    helpSection(
                        icon: "character.book.closed.fill",
                        color: AppTheme.accent,
                        title: "What is HanziFive?",
                        text: "HanziFive helps you learn Chinese characters (hanzi) from the HSK curriculum using spaced repetition. Cards you struggle with appear more often, while cards you know well are shown less frequently."
                    )

                    // How to study
                    helpSection(
                        icon: "hand.draw.fill",
                        color: AppTheme.success,
                        title: "How to Study",
                        text: "Tap any HSK level to start studying. You'll see the Chinese character first — try to recall its meaning and pinyin. Tap the card to reveal the answer, then swipe right if you got it correct or left if you got it wrong."
                    )

                    // Reverse mode
                    helpSection(
                        icon: "arrow.left.arrow.right",
                        color: AppTheme.purple,
                        title: "Reverse Mode",
                        text: "After completing a level, a \"Reverse\" button appears on the card. In reverse mode you see the meaning and pinyin first, then try to recall the character. Complete both modes to earn the rainbow border!"
                    )

                    // Spaced repetition
                    helpSection(
                        icon: "brain.head.profile.fill",
                        color: AppTheme.info,
                        title: "Spaced Repetition",
                        text: "The app uses the SM2 algorithm to schedule reviews. Words you get wrong are shown again sooner. Words you consistently get right are spaced out over days, helping you build long-term memory."
                    )

                    // HSK Levels
                    helpSection(
                        icon: "stairs",
                        color: AppTheme.amber,
                        title: "HSK Levels",
                        text: "HSK (Hanyu Shuiping Kaoshi) is the standard Chinese proficiency test. Each level builds on the previous one. HSK1 has the most common characters, with higher levels adding more."
                    )

                    // Badges
                    helpSection(
                        icon: "crown.fill",
                        color: AppTheme.goldAccent,
                        title: "Achievements",
                        text: "Complete all cards in a level to earn a gold shimmering border. Master both normal and reverse mode to upgrade to a rainbow border and \"Mastered\" badge."
                    )
                }
                .padding(20)
            }
            .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }

    private func helpSection(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
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
