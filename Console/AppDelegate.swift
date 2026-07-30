import HotwireNative
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAppearance()
        configureHotwire()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureAppearance() {
        UINavigationBar.appearance().scrollEdgeAppearance = .init()
    }

    private func configureHotwire() {
        guard let localPathConfigurationURL = Bundle.main.url(
            forResource: "path-configuration",
            withExtension: "json"
        ) else {
            preconditionFailure("Missing path-configuration.json")
        }

        Hotwire.loadPathConfiguration(from: [
            .file(localPathConfigurationURL),
            .server(AppEnvironment.pathConfigurationURL)
        ])
        Hotwire.config.applicationUserAgentPrefix = AppEnvironment.userAgentPrefix
        Hotwire.config.backButtonDisplayMode = .minimal
        Hotwire.config.animateReplaceActions = true

#if DEBUG
        Hotwire.config.debugLoggingEnabled = true
#endif
    }
}
