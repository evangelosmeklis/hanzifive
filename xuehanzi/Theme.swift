import SwiftUI

enum AppTheme {
    // MARK: - Core Colors (Clean & Minimal like the reference)
    
    // Primary mint/teal accent (matching the reference app)
    static let mint = Color(red: 0.45, green: 0.80, blue: 0.75)
    static let mintLight = Color(red: 0.85, green: 0.95, blue: 0.93)
    
    // Secondary colors
    static let coral = Color(red: 0.95, green: 0.45, blue: 0.45)
    static let amber = Color(red: 0.95, green: 0.75, blue: 0.35)
    static let purple = Color(red: 0.65, green: 0.55, blue: 0.85)
    
    // Backgrounds - clean white/light gray
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let surface = Color.white
    static let card = Color.white
    static let stroke = Color(red: 0.92, green: 0.92, blue: 0.94)
    
    // Text colors
    static let primaryText = Color(red: 0.12, green: 0.12, blue: 0.15)
    static let secondaryText = Color(red: 0.55, green: 0.55, blue: 0.60)
    static let tertiaryText = Color(red: 0.75, green: 0.75, blue: 0.78)
    
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
    
    // Success - mint green
    static let success = Color(red: 0.35, green: 0.78, blue: 0.65)
    static let successStrong = Color(red: 0.30, green: 0.70, blue: 0.58)
    
    // Danger - soft red
    static let danger = Color(red: 0.92, green: 0.45, blue: 0.45)
    static let dangerStrong = Color(red: 0.85, green: 0.35, blue: 0.35)
    
    // Warning - amber
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.35)
    
    // Info - blue
    static let info = Color(red: 0.45, green: 0.65, blue: 0.90)
    
    // Gold for achievements
    static var goldAccent: Color {
        Color(red: 0.90, green: 0.72, blue: 0.30)
    }
    
    // MARK: - Celebration Colors
    static let celebrationColors: [Color] = [
        mint, coral, amber, purple, info
    ]
    
    // MARK: - Bubble/Decoration Colors
    static let bubbleColors: [Color] = [
        mintLight,
        Color(red: 0.95, green: 0.92, blue: 0.92),
        Color(red: 0.95, green: 0.95, blue: 0.88),
        Color(red: 0.92, green: 0.92, blue: 0.98),
    ]
    
    // MARK: - Level Colors
    static let levelColors: [Color] = [
        Color(red: 0.45, green: 0.80, blue: 0.75),   // HSK1 - Mint/Teal
        Color(red: 0.95, green: 0.70, blue: 0.45),   // HSK2 - Orange
        Color(red: 0.55, green: 0.70, blue: 0.90),   // HSK3 - Blue
        Color(red: 0.90, green: 0.65, blue: 0.75),   // HSK4 - Pink
        Color(red: 0.70, green: 0.60, blue: 0.85),   // HSK5 - Purple
        Color(red: 0.50, green: 0.75, blue: 0.70),   // HSK6 - Teal
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
    
    // MARK: - XP & Gamification Colors
    static let xpColor = info
    static let streakColor = coral
    static let levelUpColor = purple
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
