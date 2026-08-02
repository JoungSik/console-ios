import UIKit

enum ThemePreference: String, Codable {
    case system
    case light
    case dark

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct ServerTheme: Codable, Equatable {
    let owner: String
    let preference: ThemePreference
}

final class ThemeMirrorStore {
    private static let storageKey = "serverThemeMirror"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ServerTheme? {
        guard let encodedTheme = defaults.data(forKey: Self.storageKey) else {
            return nil
        }

        return try? JSONDecoder().decode(ServerTheme.self, from: encodedTheme)
    }

    func save(_ theme: ServerTheme) {
        guard let encodedTheme = try? JSONEncoder().encode(theme) else {
            return
        }

        defaults.set(encodedTheme, forKey: Self.storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}

@MainActor
final class AppThemeSynchronizer {
    private let mirrorStore: ThemeMirrorStore
    private var currentTheme: ServerTheme?

    init(mirrorStore: ThemeMirrorStore = ThemeMirrorStore()) {
        self.mirrorStore = mirrorStore
        currentTheme = mirrorStore.load()
    }

    func applyMirroredTheme(to window: UIWindow) {
        apply(currentTheme?.preference ?? .system, to: window)
    }

    @discardableResult
    func synchronize(_ theme: ServerTheme, to window: UIWindow) -> Bool {
        guard theme != currentTheme else {
            return false
        }

        currentTheme = theme
        mirrorStore.save(theme)
        apply(theme.preference, to: window)
        return true
    }

    func reset(to window: UIWindow) {
        currentTheme = nil
        mirrorStore.clear()
        apply(.system, to: window)
    }

    private func apply(_ preference: ThemePreference, to window: UIWindow) {
        window.overrideUserInterfaceStyle = preference.userInterfaceStyle
        window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
    }
}
