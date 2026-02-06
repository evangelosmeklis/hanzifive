import SwiftUI
import SwiftData

enum ReviseTab: String, CaseIterable {
    case recent = "Recent"
    case frequent = "Frequent"
}

struct ReviseView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var words: [Word]
    @State private var selectedTab: ReviseTab = .recent
    @State private var removedWordIDs: Set<UUID> = []

    // MARK: - Filtered words that need revision
    private var reviseWords: [Word] {
        words.filter { word in
            guard !removedWordIDs.contains(word.id) else { return false }
            guard let rs = word.reviewState, rs.lastReviewed != nil else { return false }
            return rs.ease < 2.0 || (rs.repetitions == 0 && rs.lastScore < 3)
        }
    }

    private var sortedWords: [Word] {
        switch selectedTab {
        case .recent:
            return reviseWords.sorted {
                ($0.reviewState?.lastReviewed ?? .distantPast) > ($1.reviewState?.lastReviewed ?? .distantPast)
            }
        case .frequent:
            return reviseWords.sorted {
                ($0.reviewState?.ease ?? 2.5) < ($1.reviewState?.ease ?? 2.5)
            }
        }
    }

    private var levelsAffected: Int {
        Set(reviseWords.map(\.level)).count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero banner
                heroBanner

                VStack(spacing: 20) {
                    // Stats strip
                    statsStrip
                        .padding(.top, -28)

                    if reviseWords.isEmpty {
                        emptyState
                    } else {
                        tabPicker

                        // Swipe hint
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 10, weight: .medium))
                            Text("Swipe left on a word to remove it")
                                .font(.caption)
                        }
                        .foregroundStyle(AppTheme.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        wordList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
    }

    // MARK: - Hero Banner
    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.18, blue: 0.40),
                    Color(red: 0.32, green: 0.28, blue: 0.58),
                    Color(red: 0.52, green: 0.36, blue: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 230, y: -30)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 120, height: 120)
                .offset(x: -20, y: 80)

            VStack(alignment: .leading, spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("复习")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    Text("Revise & Strengthen")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }

                // Summary
                if reviseWords.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                        Text("All caught up!")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                        Text("\(reviseWords.count) words need attention")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }

                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .clipShape(
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
        )
    }

    // MARK: - Stats Strip
    private var statsStrip: some View {
        HStack(spacing: 10) {
            // Words to revise
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.danger.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.danger)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(reviseWords.count)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("To Revise")
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

            // Levels affected
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.info.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.info)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(levelsAffected)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(levelsAffected == 1 ? "Level" : "Levels")
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

            // Hardest ease
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.warning.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.warning)
                }
                VStack(alignment: .leading, spacing: 0) {
                    let avgEase = reviseWords.isEmpty ? 0.0 : reviseWords.reduce(0.0) { $0 + ($1.reviewState?.ease ?? 2.5) } / Double(reviseWords.count)
                    Text(String(format: "%.1f", avgEase))
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Avg Ease")
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

    // MARK: - Tab Picker
    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(ReviseTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Word List
    private var wordList: some View {
        LazyVStack(spacing: 10) {
            ForEach(sortedWords, id: \.id) { word in
                ReviseWordRow(word: word, showMistakeRate: selectedTab == .frequent) {
                    removeFromRevise(word)
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.10))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.success)
            }

            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("No words need extra revision right now.\nKeep studying to maintain your progress.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Remove from Revise
    private func removeFromRevise(_ word: Word) {
        withAnimation(.spring(response: 0.3)) {
            removedWordIDs.insert(word.id)
        }
        // Reset ease above the revise threshold so it won't reappear
        if let rs = word.reviewState {
            rs.ease = 2.5
            if rs.repetitions == 0 {
                rs.repetitions = 1
            }
        }
    }
}
