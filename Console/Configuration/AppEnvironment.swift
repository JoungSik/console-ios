import Foundation

enum AppEnvironment {
    static let name = requiredConfigurationValue(forKey: "ConsoleEnvironment")
    static let baseURL = requiredURL(forKey: "ConsoleBaseURL")
    static let journalURL = baseURL.appendingPathComponent("posts")
    static let todoURL = baseURL.appendingPathComponent("todos")
    static let loginURL = baseURL.appendingPathComponent("session/new")
    static let accountURL = baseURL.appendingPathComponent("mypage/user")
    static let pluginsURL = baseURL.appendingPathComponent("mypage/plugins")
    static let pushNotificationsURL = baseURL.appendingPathComponent("mypage/push_notifications")
    static let privacyURL = baseURL.appendingPathComponent("privacy")
    static let appSettingsURL = baseURL.appendingPathComponent("hotwire-native/app-settings")
    static let pathConfigurationURL = baseURL.appendingPathComponent("hotwire-native/path-configuration.json")

    static var userAgentPrefix: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        return "Console/\(version);"
    }

    private static func requiredConfigurationValue(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty else {
            preconditionFailure("Missing configuration value: \(key)")
        }

        return value
    }

    private static func requiredURL(forKey key: String) -> URL {
        let value = requiredConfigurationValue(forKey: key)

        guard let url = URL(string: value), url.scheme != nil, url.host != nil else {
            preconditionFailure("Invalid URL configuration: \(key)")
        }

        return url
    }
}
