import SwiftUI

enum AppTheme {
    // MARK: - Core Colors (Bright & Engaging)
    
    // Primary mint/teal accent - vibrant
    static let mint = Color(red: 0.15, green: 0.80, blue: 0.70)
    static let mintLight = Color(red: 0.85, green: 0.96, blue: 0.94)
    
    // Secondary colors - bright and engaging
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.38)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.20)
    static let purple = Color(red: 0.65, green: 0.45, blue: 0.98)
    
    // Bright character colors for flashcards
    static let characterPrimary = Color(red: 0.15, green: 0.55, blue: 0.98)
    static let characterSecondary = Color(red: 0.50, green: 0.30, blue: 0.98)
    
    // Backgrounds - clean white/light gray
    static let background = Color(red: 0.975, green: 0.975, blue: 0.98)
    static let surface = Color.white
    static let card = Color.white
    static let stroke = Color(red: 0.90, green: 0.90, blue: 0.92)
    
    // Text colors
    static let primaryText = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let secondaryText = Color(red: 0.50, green: 0.50, blue: 0.55)
    static let tertiaryText = Color(red: 0.70, green: 0.70, blue: 0.72)
    
    // Legacy aliases
    static let primaryOrange = coral
    static let hotPink = coral
    static let sunshineYellow = amber
    static let electricBlue = mint
    static let mintGreen = mint
    static let lavenderPurple = purple
    static let accentText = mint
    
    // Primary accent - mint
    static let accent = mint
    static let accentSoft = mintLight
    
    // Success - bright vibrant green
    static let success = Color(red: 0.15, green: 0.82, blue: 0.50)
    static let successStrong = Color(red: 0.10, green: 0.72, blue: 0.45)
    
    // Danger - bright vibrant red
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)
    static let dangerStrong = Color(red: 0.95, green: 0.25, blue: 0.25)
    
    // Warning - bright amber
    static let warning = Color(red: 1.0, green: 0.70, blue: 0.20)
    
    // Info - bright blue
    static let info = Color(red: 0.30, green: 0.60, blue: 0.98)
    
    // Gold for achievements - richer
    static var goldAccent: Color {
        Color(red: 1.0, green: 0.75, blue: 0.20)
    }
    
    // MARK: - Celebration Colors - bright and vibrant
    static let celebrationColors: [Color] = [
        Color(red: 0.30, green: 0.85, blue: 0.78),   // Bright mint
        Color(red: 1.0, green: 0.50, blue: 0.45),    // Bright coral
        Color(red: 1.0, green: 0.80, blue: 0.25),    // Bright gold
        Color(red: 0.70, green: 0.50, blue: 1.0),    // Bright purple
        Color(red: 0.35, green: 0.70, blue: 1.0),    // Bright blue
        Color(red: 1.0, green: 0.60, blue: 0.80),    // Bright pink
    ]
    
    // MARK: - Bubble/Decoration Colors - Subtle but colorful
    static let bubbleColors: [Color] = [
        mintLight,
        Color(red: 1.0, green: 0.92, blue: 0.90),    // Soft coral tint
        Color(red: 1.0, green: 0.96, blue: 0.85),    // Soft amber tint
        Color(red: 0.92, green: 0.90, blue: 1.0),    // Soft purple tint
    ]
    
    // MARK: - Level Colors - Bright & Engaging
    static let levelColors: [Color] = [
        Color(red: 0.20, green: 0.78, blue: 0.68),   // HSK1 - Bright Teal
        Color(red: 1.0, green: 0.60, blue: 0.25),    // HSK2 - Bright Orange
        Color(red: 0.35, green: 0.60, blue: 0.95),   // HSK3 - Bright Blue
        Color(red: 1.0, green: 0.50, blue: 0.62),    // HSK4 - Bright Pink
        Color(red: 0.60, green: 0.45, blue: 0.95),   // HSK5 - Bright Purple
        Color(red: 0.25, green: 0.72, blue: 0.80),   // HSK6 - Bright Cyan
    ]
    
    static func levelTint(for level: String) -> Color {
        let index = max(0, (Int(level.replacingOccurrences(of: "HSK", with: "")) ?? 1) - 1)
        return levelColors[min(index, levelColors.count - 1)]
    }
    
    // MARK: - Gradients
    
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [mint, mint.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var imperialGradient: LinearGradient {
        primaryGradient
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
            colors: [goldAccent, goldAccent.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var rainbowGradient: LinearGradient {
        LinearGradient(
            colors: [mint, amber, coral, purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - XP & Gamification Colors - Bright & Engaging
    static let xpColor = Color(red: 0.25, green: 0.65, blue: 1.0)
    static let streakColor = Color(red: 1.0, green: 0.45, blue: 0.22)
    static let levelUpColor = Color(red: 0.70, green: 0.40, blue: 1.0)
}

// MARK: - Custom Button Style
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Pressable Card Style
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glow Effect Modifier
struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 4)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
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
