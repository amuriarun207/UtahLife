import SwiftUI
import UIKit

public enum UtahColor {
    public static let accent = dynamic(
        light: UIColor(red: 0.11, green: 0.34, blue: 0.42, alpha: 1),
        dark: UIColor(red: 0.62, green: 0.83, blue: 0.86, alpha: 1)
    )
    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    public static let background = Color(uiColor: .systemBackground)
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    public static let surface = dynamic(
        light: UIColor(red: 1, green: 1, blue: 1, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.16, blue: 0.18, alpha: 1)
    )
    public static let elevatedSurface = dynamic(
        light: UIColor(red: 0.96, green: 0.97, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.18, green: 0.20, blue: 0.22, alpha: 1)
    )
    public static let separator = Color(uiColor: .separator)
    public static let chipBackground = dynamic(
        light: UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.24, blue: 0.26, alpha: 1)
    )
    public static let success = dynamic(
        light: UIColor(red: 0.12, green: 0.42, blue: 0.28, alpha: 1),
        dark: UIColor(red: 0.55, green: 0.82, blue: 0.64, alpha: 1)
    )
    public static let warning = dynamic(
        light: UIColor(red: 0.55, green: 0.36, blue: 0.05, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.76, blue: 0.38, alpha: 1)
    )
    public static let critical = dynamic(
        light: UIColor(red: 0.62, green: 0.16, blue: 0.16, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.55, blue: 0.52, alpha: 1)
    )
    public static let info = dynamic(
        light: UIColor(red: 0.13, green: 0.32, blue: 0.52, alpha: 1),
        dark: UIColor(red: 0.62, green: 0.78, blue: 0.95, alpha: 1)
    )
    public static let onAccent = Color.white

    public static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

public enum Spacing {
    public static let xSmall: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let xLarge: CGFloat = 24
    public static let xxLarge: CGFloat = 32
}

public enum CornerRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let card: CGFloat = 20
}

public enum UtahFont {
    public static let largeTitle = Font.largeTitle.weight(.semibold)
    public static let title = Font.title2.weight(.semibold)
    public static let headline = Font.headline
    public static let body = Font.body
    public static let callout = Font.callout
    public static let caption = Font.caption
    public static let metric = Font.system(.largeTitle, design: .rounded).weight(.semibold)
}

public enum StatusTone {
    case success
    case warning
    case critical
    case info
    case neutral

    public var foreground: Color {
        switch self {
        case .success: return UtahColor.success
        case .warning: return UtahColor.warning
        case .critical: return UtahColor.critical
        case .info: return UtahColor.info
        case .neutral: return UtahColor.secondaryText
        }
    }
}
