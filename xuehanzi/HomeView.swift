import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var words: [Word]
    @Query private var achievements: [LevelAchievement]
    @State private var showingSettings = false
    
    // Streak tracking
    @AppStorage("currentStreak") private var currentStreak: Int = 0
    @AppStorage("lastStudyDate") private var lastStudyDateString: String = ""
    @AppStorage("totalXP") private var totalXP: Int = 0
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("cardsStudiedToday") private var cardsStudiedToday: Int = 0
    @AppStorage("lastCardStudyDate") private var lastCardStudyDate: String = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Streak and Stats Row
                statsRow
                
                // Daily Progress Card
                dailyProgressCard
                
                // HSK Levels Section
                levelsSectionHeader
                
                // Level Cards
                ForEach(levelSummaries) { summary in
                    LevelCardView(summary: summary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("学汉字")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Text("What would you like to study?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Stats Row (Streak & XP)
    private var statsRow: some View {
        HStack(spacing: 12) {
            // Streak
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentStreak)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.coral.opacity(0.1))
            )
            
            // XP
            HStack(spacing: 8) {
                Text("⚡")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalXP)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Total XP")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.info.opacity(0.1))
            )
            
            Spacer()
        }
    }
    
    // MARK: - Daily Progress Card
    private var dailyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Goal")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                if dailyProgress >= 1.0 {
                    Text("✓ Complete!")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.mint)
                }
            }
            
            HStack(spacing: 16) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(AppTheme.mintLight, lineWidth: 6)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: dailyProgress)
                        .stroke(AppTheme.mint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(cardsStudiedToday)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                        Text("/\(dailyGoal)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Progress")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)
                    
                    Text("\(cardsStudiedToday)/\(dailyGoal) cards studied")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.mintLight)
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.mint)
                                .frame(width: max(geometry.size.width * dailyProgress, 0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                Spacer()
            }
            
            // Edit Goal button only
            Button {
                showingSettings = true
            } label: {
                Text("Edit Goal")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.mintLight)
                    )
            }
            .buttonStyle(BounceButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Levels Section Header
    private var levelsSectionHeader: some View {
        HStack {
            Text("HSK Levels")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(.top, 8)
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
        
        // If it's a new day, reset daily progress
        if lastCardStudyDate != todayString {
            cardsStudiedToday = 0
            lastCardStudyDate = todayString
        }
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        // If no last study date, this is first time - don't set streak yet
        guard !lastStudyDateString.isEmpty else {
            return
        }
        
        // Parse the last study date
        guard let lastDate = dateFormatter.date(from: lastStudyDateString) else {
            return
        }
        
        let lastDateStart = Calendar.current.startOfDay(for: lastDate)
        let daysSince = Calendar.current.dateComponents([.day], from: lastDateStart, to: today).day ?? 0
        
        // If more than 1 day has passed, reset streak
        if daysSince > 1 {
            currentStreak = 0
        }
        // If it's the same day, do nothing (streak already counted)
        // If it's exactly 1 day later and they haven't studied today yet, streak continues from yesterday
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Top section with level info
            HStack(spacing: 16) {
                // Level badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? AppTheme.goldAccent.opacity(0.15) : levelColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    if isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.goldAccent)
                    } else {
                        Text(summary.level.replacingOccurrences(of: "HSK", with: ""))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(levelColor)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(summary.level)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        
                        if isCompleted {
                            Text("Completed")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.goldAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.goldAccent.opacity(0.15))
                                )
                        }
                        
                        Spacer()
                        
                        if summary.due > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(levelColor)
                                    .frame(width: 6, height: 6)
                                Text("\(summary.due) due")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                    }
                    
                    // Progress info
                    Text("\(summary.studied)/\(summary.total) cards learned")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(levelColor.opacity(0.15))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isCompleted ? AppTheme.goldAccent : levelColor)
                                .frame(width: max(geometry.size.width * progress, 0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                NavigationLink {
                    StudySessionView(level: summary.level)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.caption)
                        Text("Study")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(levelColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(levelColor.opacity(0.1))
                    )
                }
                .buttonStyle(BounceButtonStyle())
                
                NavigationLink {
                    TestSessionView(level: summary.level)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Test")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(levelColor)
                    )
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCompleted ? AppTheme.goldAccent.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("totalXP") private var totalXP: Int = 0
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
                                .fill(AppTheme.mintLight)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.mint)
                        }
                        
                        Text("Settings")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.primaryText)
                        
                        Text("设置")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.top, 20)
                    
                    // Daily Goal Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title3)
                                .foregroundStyle(AppTheme.mint)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Goal")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("每日目标")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Text("\(selectedGoal) cards")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.mint)
                        }
                        
                        Text("How many cards do you want to study each day?")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                        
                        // Goal Options Grid
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
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedGoal == goal ? AppTheme.mint : AppTheme.mintLight)
                                    )
                                }
                                .buttonStyle(BounceButtonStyle())
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.card)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    )
                    
                    // Stats Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Stats")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                        
                        HStack(spacing: 16) {
                            StatCard(icon: "flame.fill", value: "\(currentStreak)", label: "Day Streak", color: AppTheme.coral)
                            StatCard(icon: "bolt.fill", value: "\(totalXP)", label: "Total XP", color: AppTheme.info)
                        }
                        
                        HStack(spacing: 16) {
                            StatCard(icon: "checkmark.circle.fill", value: "\(cardsStudiedToday)", label: "Today", color: AppTheme.mint)
                            StatCard(icon: "target", value: "\(dailyGoal)", label: "Goal", color: AppTheme.amber)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.card)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
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
                    .foregroundStyle(AppTheme.mint)
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
                .foregroundStyle(AppTheme.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Legacy components kept for compatibility

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
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
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

