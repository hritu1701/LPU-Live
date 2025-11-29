import SwiftUI
import Combine

struct DesignSystem {
    struct Colors {
        static let primary = Color(hex: "d97642") // Orange
        static let secondary = Color(hex: "2a2a2a") // Dark Gray
        static let backgroundDark = Color(hex: "1a1a1a")
        static let backgroundLight = Color(hex: "f5f5f5")
        static let cardDark = Color(hex: "2a2a2a")
        static let cardLight = Color.white
        static let textDark = Color.white
        static let textLight = Color.black
        static let textSecondaryDark = Color.gray
        static let textSecondaryLight = Color.gray
    }
    
    struct Fonts {
        static func header(_ size: CGFloat = 24) -> Font {
            return .system(size: size, weight: .bold, design: .rounded)
        }
        
        static func body(_ size: CGFloat = 16) -> Font {
            return .system(size: size, weight: .regular, design: .default)
        }
        
        static func caption() -> Font {
            return .system(size: 12, weight: .regular, design: .default)
        }
    }
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
}

class ThemeManager: ObservableObject {
    // No longer manually managed, relies on system appearance
    
    var background: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "1a1a1a") : UIColor(hex: "f5f5f5")
        })
    }
    
    var card: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "2a2a2a") : UIColor.white
        })
    }
    
    var text: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        })
    }
    
    var textSecondary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.lightGray : UIColor.gray
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
