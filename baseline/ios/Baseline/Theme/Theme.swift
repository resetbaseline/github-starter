import SwiftUI
import UIKit

// MARK: - Design system (dark only). All visual constants for the Baseline iOS app.

enum Theme {

    // MARK: Colors (hex per spec)

    enum Colors {
        /// #0D0D0D — app background, tab bar background
        static let background = Color(rgb: 0x0D0D0D)
        /// #7C5CBF — accent, logo placeholder, CTAs
        static let accent = Color(rgb: 0x7C5CBF)
        /// #111111 — cards / elevated surfaces
        static let surface = Color(rgb: 0x111111)
        /// #1E1E1E — borders, dividers, tab bar top hairline
        static let border = Color(rgb: 0x1E1E1E)
        /// #FFFFFF — primary text
        static let textPrimary = Color(rgb: 0xFFFFFF)
        /// #888888 — secondary text
        static let textSecondary = Color(rgb: 0x888888)
        /// #444444 — muted / disabled
        static let textMuted = Color(rgb: 0x444444)
    }

    // MARK: Layout

    enum Radius {
        /// Cards and large rounded containers
        static let card: CGFloat = 16
    }

    /// 8pt grid — use multiples for consistent rhythm.
    enum Spacing {
        static let unit: CGFloat = 8
        static let xs: CGFloat = unit * 1      // 8
        static let sm: CGFloat = unit * 2      // 16
        static let md: CGFloat = unit * 3      // 24
        static let lg: CGFloat = unit * 4      // 32
        static let xl: CGFloat = unit * 6      // 48
    }

    enum TabBar {
        /// Spec: 83pt total tab bar height (includes safe area on notched phones when using system tab bar).
        static let height: CGFloat = 83
        static let background = Colors.background
        static let topBorderColor = Colors.border
        /// 0.5pt top border
        static let topBorderWidth: CGFloat = 0.5

        // UIKit appearance (sRGB matches `Colors` hex values).
        static let backgroundUIColor = UIColor(red: 13 / 255, green: 13 / 255, blue: 13 / 255, alpha: 1)
        static let accentUIColor = UIColor(red: 124 / 255, green: 92 / 255, blue: 191 / 255, alpha: 1)
        static let unselectedItemUIColor = UIColor(red: 136 / 255, green: 136 / 255, blue: 136 / 255, alpha: 1)
        static let primaryLabelUIColor = UIColor.white
    }

    // MARK: Typography (SF Pro Display; headings light/thin, body regular)

    enum Typography {
        private static let display = "SF Pro Display"

        static func largeTitle() -> Font {
            .custom(display, size: 34).weight(.thin)
        }

        static func title1() -> Font {
            .custom(display, size: 28).weight(.light)
        }

        static func title2() -> Font {
            .custom(display, size: 22).weight(.light)
        }

        static func title3() -> Font {
            .custom(display, size: 20).weight(.light)
        }

        static func headline() -> Font {
            .custom(display, size: 17).weight(.regular)
        }

        static func body() -> Font {
            .custom(display, size: 17).weight(.regular)
        }

        static func callout() -> Font {
            .custom(display, size: 16).weight(.regular)
        }

        static func subheadline() -> Font {
            .custom(display, size: 15).weight(.regular)
        }

        static func footnote() -> Font {
            .custom(display, size: 13).weight(.regular)
        }

        static func caption1() -> Font {
            .custom(display, size: 12).weight(.regular)
        }

        static func caption2() -> Font {
            .custom(display, size: 11).weight(.regular)
        }
    }

    // MARK: Animation (ease-out; screen 280ms, reveals 400ms)

    enum Animation {
        static let screenTransitionDuration: Double = 0.28
        static let revealDuration: Double = 0.40

        /// Screen transitions (navigation / auth state changes)
        static var screenTransition: SwiftUI.Animation {
            .easeOut(duration: screenTransitionDuration)
        }

        /// Content reveals (cards, results)
        static var reveal: SwiftUI.Animation {
            .easeOut(duration: revealDuration)
        }

        /// Default interactive ease-out (buttons, small UI)
        static var interactive: SwiftUI.Animation {
            .easeOut(duration: 0.22)
        }
    }

    // MARK: Haptics (goal completion, timer start/stop, day result reveal)

    enum Haptics {
        static func goalCompleted() {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.success)
        }

        static func timerStart() {
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.impactOccurred()
        }

        static func timerStop() {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }

        static func dayResultReveal() {
            let g = UINotificationFeedbackGenerator()
            g.notificationOccurred(.warning)
        }

        static func lightImpact() {
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
        }
    }

    // MARK: Logo (placeholder — filled circle in accent)

    enum Logo {
        static let diameter: CGFloat = 44
        static let color = Colors.accent
    }
}

// MARK: - Color + hex

extension Color {
    /// sRGB from 24-bit hex `0xRRGGBB`.
    init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
