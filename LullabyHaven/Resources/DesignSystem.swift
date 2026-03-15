//
//  DesignSystem.swift
//  LullabyHaven
//
//  App-wide design tokens: colors, fonts, spacing
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Background (dark/light adaptive via UIColor)
    static let lhBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#0d1117")
            : UIColor(hex: "#f5f5f7")
    })

    // Cards
    static let lhCard = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#1c2130")
            : UIColor.white
    })

    // Accent (soft lavender-blue)
    static let lhAccent = Color(hex: "#6e9ef5")

    // Text
    static let lhPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(hex: "#1a1a2e")
    })

    static let lhSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(hex: "#8a9bb5")
            : UIColor(hex: "#6b7280")
    })

    // Gold for premium
    static let lhGold = Color(hex: "#f5c842")
}

// MARK: - UIColor Hex Initializer
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.hasPrefix("#") ? String(hex.dropFirst()) : hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Typography
extension Font {
    static let lhTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let lhHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let lhBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let lhCaption = Font.system(size: 12, weight: .regular, design: .rounded)
}

// MARK: - Spacing
enum LHSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radius
enum LHRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 999
}

// MARK: - View Modifiers
struct LHCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.lhCard)
            .clipShape(RoundedRectangle(cornerRadius: LHRadius.lg))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func lhCard() -> some View {
        modifier(LHCardStyle())
    }
}

// MARK: - Gradient Backgrounds
extension LinearGradient {
    static let lhNight = LinearGradient(
        colors: [Color(hex: "#0d1117"), Color(hex: "#1a2744")],
        startPoint: .top, endPoint: .bottom
    )
}
