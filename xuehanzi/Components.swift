import SwiftUI

// MARK: - Flashcard View
struct FlashcardView: View {
    let hanzi: String
    let pinyin: String
    let meaning: String
    let isRevealed: Bool

    var body: some View {
        VStack(spacing: 28) {
            // Chinese Character - Large with ink-inspired gradient
            ZStack {
                // Soft glow behind character
                Text(hanzi)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.characterPrimary.opacity(0.15))
                    .blur(radius: 30)

                // Main character
                Text(hanzi)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.characterGradient)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            if isRevealed {
                VStack(spacing: 16) {
                    // Pinyin pill
                    Text(pinyin)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.characterPrimary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(AppTheme.characterPrimary.opacity(0.08))
                        )
                        .transition(.scale.combined(with: .opacity))

                    // Meaning
                    Text(meaning)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRevealed)
            } else {
                // Tap to reveal hint
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.characterPrimary.opacity(0.06))
                            .frame(width: 56, height: 56)

                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.characterPrimary.opacity(0.5))
                            .symbolEffect(.pulse)
                    }

                    Text("Tap to reveal")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                .padding(.top, 16)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
        .warmShadow(0.10)
    }
}

// MARK: - Feedback Overlay View
struct FeedbackOverlayView: View {
    let color: Color
    let isVisible: Bool
    let isCorrect: Bool

    @State private var scale: CGFloat = 0.5

    var body: some View {
        if isVisible {
            ZStack {
                // Radial gradient background
                RadialGradient(
                    colors: [color.opacity(0.35), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()

                // Icon with animation
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .scaleEffect(scale)
                        .opacity(2 - scale)

                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 90, height: 90)

                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(color)
                }
            }
            .transition(.opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 1.5
                }
            }
        }
    }
}

// MARK: - Celebration Burst View
struct CelebrationBurstView: View {
    @State private var animate = false

    let colors = AppTheme.celebrationColors

    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(colors[index % colors.count])
                    .frame(width: 8, height: 40)
                    .offset(y: animate ? -180 : -40)
                    .rotationEffect(.degrees(Double(index) * 22.5))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0.3 : 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false
    @State private var pieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiShape(piece: piece)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .rotationEffect(.degrees(animate ? piece.rotation + 360 : piece.rotation))
                        .position(x: piece.x * proxy.size.width, y: animate ? proxy.size.height + 50 : -50)
                        .animation(
                            .easeIn(duration: piece.duration)
                            .delay(piece.delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                if pieces.isEmpty {
                    pieces = ConfettiPiece.make(count: 40)
                }
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiShape: Shape {
    let piece: ConfettiPiece

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch piece.shapeType {
        case 0:
            path.addEllipse(in: rect)
        case 1:
            path.addRect(rect)
        case 2:
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            for i in 0..<5 {
                let angle = (Double(i) * 72 - 90) * .pi / 180
                let point = CGPoint(
                    x: center.x + CGFloat(Darwin.cos(angle)) * radius,
                    y: center.y + CGFloat(Darwin.sin(angle)) * radius
                )
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        default:
            path.addEllipse(in: rect)
        }
        return path
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let delay: Double
    let duration: Double
    let color: Color
    let rotation: Double
    let size: CGFloat
    let shapeType: Int

    static func make(count: Int) -> [ConfettiPiece] {
        (0..<count).map { index in
            ConfettiPiece(
                x: CGFloat.random(in: 0.05...0.95),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 1.5...2.5),
                color: AppTheme.celebrationColors[index % AppTheme.celebrationColors.count],
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 8...16),
                shapeType: Int.random(in: 0...2)
            )
        }
    }
}

// MARK: - XP Popup View
struct XPPopupView: View {
    let amount: Int
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        HStack(spacing: 4) {
            Text("+\(amount)")
                .font(.headline.weight(.black))
            Text("XP")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(AppTheme.xpColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AppTheme.xpColor.opacity(0.12))
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                offset = -60
                opacity = 0
            }
        }
    }
}

// MARK: - Streak Celebration View
struct StreakCelebrationView: View {
    let streak: Int
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -10

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.streakColor.opacity(0.3), AppTheme.streakColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Text("🔥")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(rotation))
            }
            .scaleEffect(scale)

            VStack(spacing: 4) {
                Text("\(streak) Day Streak!")
                    .font(.title.weight(.black))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Keep it going!")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .warmShadow(0.12)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
        }
    }
}

// MARK: - Grade Button
struct GradeButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color)
                )
                .warmShadow(0.12)
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.tertiaryText)

            Text(placeholder)
                .font(.subheadline)
                .foregroundStyle(AppTheme.tertiaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.background)
        )
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let action: QuickAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(action.title)
                .font(.headline.bold())
                .foregroundStyle(AppTheme.primaryText)
            if let subtitle = action.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .warmShadow(0.06)
        )
    }
}

// MARK: - Quick Action Model
struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let color: Color

    init(title: String, subtitle: String? = nil, color: Color) {
        self.title = title
        self.subtitle = subtitle
        self.color = color
    }
}

// MARK: - Quick Action Grid
struct QuickActionGrid: View {
    let actions: [QuickAction]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            ForEach(actions) { action in
                QuickActionCard(action: action)
            }
        }
    }
}

// MARK: - Banner Card View
struct BannerCardView: View {
    let title: String
    let subtitle: String
    let highlight: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(highlight)
                        .font(.title.weight(.black))
                        .foregroundStyle(.white)
                    Text("Goal")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.primaryGradient)
        )
        .warmShadow(0.15)
    }
}

// MARK: - Reward Badge View
struct RewardBadgeView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 85, height: 85)
                    .blur(radius: 12)
                    .scaleEffect(isAnimating ? 1.15 : 1.0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 66, height: 66)

                Text(icon)
                    .font(.system(size: 34))
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
