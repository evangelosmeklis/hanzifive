import SwiftUI

// MARK: - Flashcard View
struct FlashcardView: View {
    let hanzi: String
    let pinyin: String
    let meaning: String
    let isRevealed: Bool
    
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(spacing: 24) {
            // Chinese Character - Large with glow effect
            ZStack {
                // Background glow
                Text(hanzi)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundStyle(AppTheme.accent.opacity(0.2))
                    .blur(radius: 20)
                
                // Main character with gradient
                Text(hanzi)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppTheme.accent,
                                AppTheme.hotPink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            if isRevealed {
                VStack(spacing: 18) {
                    // Pinyin with pill style
                    Text(pinyin)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.goldAccent.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.goldAccent.opacity(0.5), lineWidth: 2)
                                )
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
                // Tap to reveal hint with animation
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.accent)
                            .symbolEffect(.pulse)
                    }
                    
                    Text("Tap to reveal")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    
                    Text("点击揭示")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.7))
                }
                .padding(.top, 20)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 320)
        .background(
            ZStack {
                // Base card
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white)
                
                // Shimmer effect
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.5),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .mask(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.accent.opacity(0.3),
                            AppTheme.hotPink.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
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
                    colors: [color.opacity(0.4), color.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .ignoresSafeArea()
                
                // Icon with animation
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(color, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                    
                    // Inner circle
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: isCorrect ? "checkmark" : "xmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(color)
                }
                .scaleEffect(isCorrect ? 1.0 : 1.0)
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
        case 0: // Circle
            path.addEllipse(in: rect)
        case 1: // Rectangle
            path.addRect(rect)
        case 2: // Star
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            for i in 0..<5 {
                let angle = (Double(i) * 72 - 90) * .pi / 180
                let point = CGPoint(
                    x: center.x + CGFloat(Darwin.cos(angle)) * radius,
                    y: center.y + CGFloat(Darwin.sin(angle)) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AppTheme.xpColor.opacity(0.2))
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
                // Fire background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.streakColor.opacity(0.4),
                                AppTheme.streakColor.opacity(0)
                            ],
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
                
                Text("Keep it going! 继续加油！")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .shadow(color: AppTheme.streakColor.opacity(0.3), radius: 30, x: 0, y: 15)
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
    
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
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
                .foregroundStyle(AppTheme.secondaryText)
            
            Text(placeholder)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            
            Spacer()
            
            Text("Search")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.primaryGradient)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1.5)
                )
        )
        .shadow(color: AppTheme.accent.opacity(0.1), radius: 12, x: 0, y: 4)
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(action.color.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: action.color.opacity(0.15), radius: 10, x: 0, y: 5)
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
    
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Highlighted stat
                VStack(spacing: 4) {
                    Text(highlight)
                        .font(.title.weight(.black))
                        .foregroundStyle(.white)
                    Text("Goal")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.25))
                )
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.primaryGradient)
                
                // Animated glow overlay
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(glowOpacity * 0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .shadow(color: AppTheme.accent.opacity(0.5), radius: 24, x: 0, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
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
                // Glow effect
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 90, height: 90)
                    .blur(radius: 15)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                
                // Badge circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                Text(icon)
                    .font(.system(size: 36))
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
