import UIKit

enum AppTheme {
    static let background = color(named: "AppBackground")
    static let surface = color(named: "AppSurface")
    static let border = color(named: "AppBorder")
    static let primaryText = color(named: "AppPrimaryText")
    static let secondaryText = color(named: "AppSecondaryText")
    static let accent = color(named: "AccentColor")

    private static func color(named name: String) -> UIColor {
        guard let color = UIColor(named: name) else {
            preconditionFailure("Missing color asset: \(name)")
        }

        return color
    }
}
