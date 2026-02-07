import SwiftUI

enum AppTheme {
    // MARK: - Core Palette (Warm, Chinese-Inspired)

    // Primary accent - Cinnabar red (朱砂)
    static let accent = Color(red: 0.85, green: 0.28, blue: 0.20)
    static let accentSoft = Color(red: 0.85, green: 0.28, blue: 0.20).opacity(0.10)

    // Legacy aliases - point to new accent
    static let mint = accent
    static let mintLight = accentSoft
    static let mintGreen = success

    // Secondary palette
    static let coral = Color(red: 0.90, green: 0.35, blue: 0.25)
    static let amber = Color(red: 0.92, green: 0.68, blue: 0.22)
    static let purple = Color(red: 0.52, green: 0.36, blue: 0.82)

    // Character display - Deep indigo to soft purple (ink-inspired)
    static let characterPrimary = Color(red: 0.16, green: 0.18, blue: 0.40)
    static let characterSecondary = Color(red: 0.42, green: 0.28, blue: 0.68)

    // Backgrounds - Warm paper tones
    static let background = Color(red: 0.975, green: 0.968, blue: 0.955)
    static let surface = Color.white
    static let card = Color.white
    static let stroke = Color(red: 0.91, green: 0.90, blue: 0.88)

    // Text colors - Ink-inspired
    static let primaryText = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let secondaryText = Color(red: 0.46, green: 0.45, blue: 0.50)
    static let tertiaryText = Color(red: 0.70, green: 0.69, blue: 0.72)

    // Legacy aliases
    static let primaryOrange = coral
    static let hotPink = coral
    static let sunshineYellow = amber
    static let electricBlue = info
    static let lavenderPurple = purple
    static let accentText = accent

    // Status colors
    static let success = Color(red: 0.22, green: 0.70, blue: 0.45)
    static let successStrong = Color(red: 0.18, green: 0.62, blue: 0.40)
    static let danger = Color(red: 0.90, green: 0.26, blue: 0.20)
    static let dangerStrong = Color(red: 0.82, green: 0.20, blue: 0.16)
    static let warning = Color(red: 0.92, green: 0.68, blue: 0.20)
    static let info = Color(red: 0.24, green: 0.48, blue: 0.90)

    // Gold for achievements - Imperial gold (金)
    static var goldAccent: Color {
        Color(red: 0.80, green: 0.65, blue: 0.26)
    }

    // Custom decks - Teal
    static let customTeal = Color(red: 0.35, green: 0.72, blue: 0.88)

    // MARK: - Celebration Colors
    static let celebrationColors: [Color] = [
        Color(red: 0.85, green: 0.28, blue: 0.20),   // Cinnabar
        Color(red: 0.80, green: 0.65, blue: 0.26),   // Gold
        Color(red: 0.22, green: 0.70, blue: 0.45),   // Jade
        Color(red: 0.52, green: 0.36, blue: 0.82),   // Purple
        Color(red: 0.24, green: 0.48, blue: 0.90),   // Royal blue
        Color(red: 0.92, green: 0.55, blue: 0.20),   // Amber
    ]

    // MARK: - Bubble/Decoration Colors
    static let bubbleColors: [Color] = [
        accent.opacity(0.08),
        Color(red: 0.80, green: 0.65, blue: 0.26).opacity(0.08),
        Color(red: 0.22, green: 0.70, blue: 0.45).opacity(0.08),
        Color(red: 0.52, green: 0.36, blue: 0.82).opacity(0.08),
    ]

    // MARK: - Level Colors
    static let levelColors: [Color] = [
        Color(red: 0.22, green: 0.70, blue: 0.58),   // HSK1 - Jade teal
        Color(red: 0.90, green: 0.52, blue: 0.18),   // HSK2 - Warm amber
        Color(red: 0.26, green: 0.46, blue: 0.88),   // HSK3 - Royal blue
        Color(red: 0.85, green: 0.36, blue: 0.48),   // HSK4 - Rose
        Color(red: 0.55, green: 0.38, blue: 0.85),   // HSK5 - Royal purple
        Color(red: 0.20, green: 0.58, blue: 0.68),   // HSK6 - Deep teal
    ]

    static func levelTint(for level: String) -> Color {
        let index = max(0, (Int(level.replacingOccurrences(of: "HSK", with: "")) ?? 1) - 1)
        return levelColors[min(index, levelColors.count - 1)]
    }

    // MARK: - Gradients

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [accent, Color(red: 0.78, green: 0.22, blue: 0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var imperialGradient: LinearGradient {
        primaryGradient
    }

    static var characterGradient: LinearGradient {
        LinearGradient(
            colors: [characterPrimary, characterSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [success, successStrong],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldAccent, Color(red: 0.72, green: 0.56, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [accent, amber, success, purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - XP & Gamification Colors
    static let xpColor = Color(red: 0.28, green: 0.44, blue: 0.88)
    static let streakColor = Color(red: 0.92, green: 0.48, blue: 0.16)
    static let levelUpColor = Color(red: 0.55, green: 0.38, blue: 0.85)
}

// MARK: - Custom Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Pressable Card Style
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.25), radius: radius, x: 0, y: 4)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Warm Shadow Modifier
struct WarmShadow: ViewModifier {
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .shadow(color: Color(red: 0.12, green: 0.10, blue: 0.08).opacity(intensity), radius: 16, x: 0, y: 6)
    }
}

extension View {
    func warmShadow(_ intensity: Double = 0.08) -> some View {
        modifier(WarmShadow(intensity: intensity))
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsing(color: Color) -> some View {
        modifier(PulsingModifier(color: color))
    }
}

// MARK: - Shimmering Gold Border
struct ShimmeringBorder: ViewModifier {
    let cornerRadius: CGFloat
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.85, green: 0.70, blue: 0.30),
                                Color(red: 0.95, green: 0.85, blue: 0.50),
                                Color(red: 0.80, green: 0.65, blue: 0.26),
                                Color(red: 0.98, green: 0.90, blue: 0.55),
                                Color(red: 0.75, green: 0.58, blue: 0.22),
                                Color(red: 0.95, green: 0.82, blue: 0.45),
                                Color(red: 0.85, green: 0.70, blue: 0.30),
                            ]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: Color(red: 0.80, green: 0.65, blue: 0.26).opacity(0.35), radius: 12, x: 0, y: 0)
            .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.50).opacity(0.20), radius: 20, x: 0, y: 0)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func shimmeringGoldBorder(cornerRadius: CGFloat = 18) -> some View {
        modifier(ShimmeringBorder(cornerRadius: cornerRadius))
    }
}

// MARK: - Shimmering Rainbow Border
struct ShimmeringRainbowBorder: ViewModifier {
    let cornerRadius: CGFloat
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.85, green: 0.28, blue: 0.20),   // Cinnabar red
                                Color(red: 0.92, green: 0.68, blue: 0.22),   // Gold
                                Color(red: 0.22, green: 0.70, blue: 0.45),   // Jade green
                                Color(red: 0.24, green: 0.48, blue: 0.90),   // Royal blue
                                Color(red: 0.52, green: 0.36, blue: 0.82),   // Purple
                                Color(red: 0.85, green: 0.36, blue: 0.48),   // Rose
                                Color(red: 0.85, green: 0.28, blue: 0.20),   // Back to cinnabar
                            ]),
                            center: .center,
                            angle: .degrees(rotation)
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: Color(red: 0.52, green: 0.36, blue: 0.82).opacity(0.25), radius: 12, x: 0, y: 0)
            .shadow(color: Color(red: 0.22, green: 0.70, blue: 0.45).opacity(0.15), radius: 20, x: 0, y: 0)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func shimmeringRainbowBorder(cornerRadius: CGFloat = 18) -> some View {
        modifier(ShimmeringRainbowBorder(cornerRadius: cornerRadius))
    }
}
