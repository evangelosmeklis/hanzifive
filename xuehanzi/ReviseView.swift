import SwiftUI
import SwiftData

enum ReviseSortMode: String, CaseIterable {
    case difficulty = "Difficulty"
    case level = "Level"
    case recent = "Recent"
}

struct ReviseView: View {
    @Query private var words: [Word]
    @State private var sortMode: ReviseSortMode = .difficulty

    // MARK: - Filtered words that need revision
    private var reviseWords: [Word] {
        words.filter { word in
            guard let rs = word.reviewState, rs.lastReviewed != nil else { return false }
            return rs.ease < 2.0 || (rs.repetitions == 0 && rs.lastScore < 3)
        }
    }

    private var sortedWords: [Word] {
        switch sortMode {
        case .difficulty:
            return reviseWords.sorted { ($0.reviewState?.ease ?? 2.5) < ($1.reviewState?.ease ?? 2.5) }
        case .level:
            return reviseWords.sorted {
                let l0 = Int($0.level.replacingOccurrences(of: "HSK", with: "")) ?? 0
                let l1 = Int($1.level.replacingOccurrences(of: "HSK", with: "")) ?? 0
                if l0 != l1 { return l0 < l1 }
                return ($0.reviewState?.ease ?? 2.5) < ($1.reviewState?.ease ?? 2.5)
            }
        case .recent:
            return reviseWords.sorted {
                ($0.reviewState?.lastReviewed ?? .distantPast) > ($1.reviewState?.lastReviewed ?? .distantPast)
            }
        }
    }

    private var levelsAffected: Int {
        Set(reviseWords.map(\.level)).count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if reviseWords.isEmpty {
                    emptyState
                } else {
                    statsBar
                    sortPicker
                    wordList
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("复习")
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .foregroundStyle(AppTheme.primaryText)

                    Text("Revise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.06), lineWidth: 1)
                        )

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }

            // Imperial gradient bar
            RoundedRectangle(cornerRadius: 2)
                .fill(AppTheme.imperialGradient)
                .frame(height: 4)
        }
        .padding(.top, 12)
    }

    // MARK: - Stats Bar
    private var statsBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.danger.opacity(0.12))
                        .frame(width: 34, height: 34)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.danger)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(reviseWords.count)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("to revise")
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

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.info.opacity(0.12))
                        .frame(width: 34, height: 34)

                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.info)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(levelsAffected)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(levelsAffected == 1 ? "level" : "levels")
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

    // MARK: - Sort Picker
    private var sortPicker: some View {
        Picker("Sort", selection: $sortMode) {
            ForEach(ReviseSortMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Word List
    private var wordList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sortedWords, id: \.id) { word in
                ReviseWordRow(word: word)
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
}
