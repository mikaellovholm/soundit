import SwiftUI

// MARK: - Blaxploitation Color Palette

enum SoundItColors {
    // Primary backgrounds
    static let midnight = Color(hex: 0x1A1118)
    static let cocoa = Color(hex: 0x2E1E28)
    static let leather = Color(hex: 0x5C3A2E)

    // Accent colors
    static let coffyRed = Color(hex: 0xD4371C)
    static let mustardGold = Color(hex: 0xE8A917)
    static let shaftPurple = Color(hex: 0x6B4FA0)
    static let foxyOrange = Color(hex: 0xE86A2C)

    // Text colors
    static let cream = Color(hex: 0xF5E6D3)
    static let smoke = Color(hex: 0xA89585)
    static let hotWhite = Color(hex: 0xFFF8F0)

    // Status
    static let success = Color(hex: 0x4A9E5C)
    static let error = coffyRed
    static let processing = mustardGold
    static let info = shaftPurple
}

// MARK: - Gradients

enum SoundItGradients {
    static let posterFade = LinearGradient(
        colors: [SoundItColors.midnight, SoundItColors.cocoa],
        startPoint: .top,
        endPoint: .bottom
    )

    static let heat = LinearGradient(
        colors: [SoundItColors.coffyRed, SoundItColors.foxyOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let goldRush = LinearGradient(
        colors: [SoundItColors.mustardGold, SoundItColors.foxyOrange],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Typography

enum SoundItFont {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .black)
    }

    static func headline(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium)
    }

    static func button(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold)
    }
}

// MARK: - Spacing

enum SoundItSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum SoundItRadius {
    static let badge: CGFloat = 6
    static let button: CGFloat = 10
    static let card: CGFloat = 12
}

// MARK: - View Modifiers

struct SoundItCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SoundItColors.cocoa)
            .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: SoundItRadius.card)
                    .stroke(SoundItColors.leather, lineWidth: 1)
            )
    }
}

struct SoundItPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoundItFont.button())
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(SoundItColors.hotWhite)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(SoundItGradients.heat)
            .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SoundItSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SoundItFont.button())
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(SoundItColors.cream)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(SoundItColors.leather)
            .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.button))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SoundItStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(SoundItFont.caption(11))
            .fontWeight(.bold)
            .tracking(0.5)
            .foregroundStyle(color)
            .padding(.horizontal, SoundItSpacing.xs)
            .padding(.vertical, SoundItSpacing.xxs)
            .background(color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: SoundItRadius.badge))
    }
}

// MARK: - View Extensions

extension View {
    func soundItCard() -> some View {
        modifier(SoundItCardStyle())
    }

    func soundItBackground() -> some View {
        self.background(SoundItGradients.posterFade.ignoresSafeArea())
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
