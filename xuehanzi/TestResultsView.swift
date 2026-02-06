import SwiftUI

struct TestResultsView: View {
    let level: String
    let accuracy: Double
    let xpEarned: Int
    var part: Int? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -10
    @State private var progressValue: Double = 0
    @State private var showBadge = false

    private var displayTitle: String {
        if let part = part {
            return "\(level) Part \(part)"
        }
        return level
    }

    var body: some View {
        ZStack {
            AnimatedGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    resultCard
                    statsSection
                    doneButton
                }
                .padding(24)
            }

            if showConfetti && accuracy >= 0.9 {
                ConfettiView()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                rotation = 0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                progressValue = accuracy
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showBadge = true
                showConfetti = true
            }
        }
    }

    // MARK: - Result Card
    private var resultCard: some View {
        VStack(spacing: 24) {
            // Level header
            HStack {
                Text(displayTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.levelTint(for: level))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.levelTint(for: level).opacity(0.12))
                    )

                Spacer()

                Text("Test Complete")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            // Animated score ring
            ZStack {
                Circle()
                    .stroke(AppTheme.stroke, lineWidth: 12)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(
                        accuracy >= 0.9 ? AppTheme.successGradient :
                        accuracy >= 0.7 ? LinearGradient(colors: [AppTheme.warning, AppTheme.warning.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [AppTheme.danger, AppTheme.danger.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(accuracy * 100))%")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            accuracy >= 0.9 ? AppTheme.success :
                            accuracy >= 0.7 ? AppTheme.warning :
                            AppTheme.danger
                        )

                    Text("正确率")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .scaleEffect(scale)

            // Result message
            VStack(spacing: 8) {
                if accuracy >= 0.9 {
                    HStack(spacing: 8) {
                        Text("🌟")
                            .font(.title)
                        Text("Excellent!")
                            .font(.title2.weight(.black))
                            .foregroundStyle(AppTheme.success)
                        Text("🌟")
                            .font(.title)
                    }
                    .scaleEffect(showBadge ? 1.0 : 0.5)
                    .opacity(showBadge ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showBadge)

                    Text("太棒了！你掌握了这个级别！")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                } else if accuracy >= 0.7 {
                    Text("Good Progress! 继续加油！")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.warning)

                    Text("You're getting there - keep practicing!")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Text("Keep Trying! 再接再厉！")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.accent)

                    Text("Practice makes perfect - you've got this!")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .multilineTextAlignment(.center)

            // Achievement badge (if passed)
            if accuracy >= 0.9 {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.goldAccent.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.goldAccent)
                    }
                    .rotationEffect(.degrees(rotation))

                    VStack(alignment: .leading, spacing: 2) {
                        if part != nil {
                            Text("Part Complete!")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.goldAccent)
                            Text("\(displayTitle) Passed - Complete both parts to master \(level)!")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            Text("Level Mastered!")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.goldAccent)
                            Text("\(level) Achievement Unlocked")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.goldAccent.opacity(0.08))
                )
                .scaleEffect(showBadge ? 1.0 : 0.8)
                .opacity(showBadge ? 1.0 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: showBadge)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
        .warmShadow(0.12)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            // XP Earned
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.xpColor.opacity(0.10))
                        .frame(width: 46, height: 46)

                    Image(systemName: "bolt.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.xpColor)
                }

                Text("+\(xpEarned)")
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.xpColor)

                Text("XP Earned")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            )
            .warmShadow(0.06)

            // Accuracy Grade
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(gradeColor.opacity(0.10))
                        .frame(width: 46, height: 46)

                    Text(gradeEmoji)
                        .font(.title3)
                }

                Text(gradeLetter)
                    .font(.headline.weight(.black))
                    .foregroundStyle(gradeColor)

                Text("Grade")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            )
            .warmShadow(0.06)

            // Speed
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.purple.opacity(0.10))
                        .frame(width: 46, height: 46)

                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.purple)
                }

                Text("Great")
                    .font(.headline.weight(.black))
                    .foregroundStyle(AppTheme.purple)

                Text("Speed")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            )
            .warmShadow(0.06)
        }
    }

    // MARK: - Done Button
    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text("Continue")
                    .font(.headline.weight(.bold))

                Image(systemName: "arrow.right")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.accent)
            )
            .warmShadow(0.12)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Helper Properties
    private var gradeColor: Color {
        if accuracy >= 0.9 { return AppTheme.success }
        if accuracy >= 0.8 { return AppTheme.success }
        if accuracy >= 0.7 { return AppTheme.warning }
        if accuracy >= 0.6 { return AppTheme.coral }
        return AppTheme.danger
    }

    private var gradeLetter: String {
        if accuracy >= 0.95 { return "S" }
        if accuracy >= 0.9 { return "A" }
        if accuracy >= 0.8 { return "B" }
        if accuracy >= 0.7 { return "C" }
        if accuracy >= 0.6 { return "D" }
        return "F"
    }

    private var gradeEmoji: String {
        if accuracy >= 0.95 { return "👑" }
        if accuracy >= 0.9 { return "⭐" }
        if accuracy >= 0.8 { return "🎯" }
        if accuracy >= 0.7 { return "💪" }
        if accuracy >= 0.6 { return "📚" }
        return "💪"
    }
}

#Preview("Full Test") {
    NavigationStack {
        TestResultsView(level: "HSK1", accuracy: 0.92, xpEarned: 150)
    }
}

#Preview("Part Test") {
    NavigationStack {
        TestResultsView(level: "HSK3", accuracy: 0.95, xpEarned: 300, part: 1)
    }
}
