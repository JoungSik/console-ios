import HotwireNative
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureAppearance()
        PushNotificationManager.shared.configure()
        configureHotwire()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    private func configureAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = AppTheme.background
        navigationBarAppearance.shadowColor = .clear
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: AppTheme.primaryText]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: AppTheme.primaryText]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.tintColor = AppTheme.accent
        navigationBar.standardAppearance = navigationBarAppearance
        navigationBar.compactAppearance = navigationBarAppearance
        navigationBar.scrollEdgeAppearance = navigationBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = AppTheme.surface
        tabBarAppearance.shadowColor = AppTheme.border
        configureTabBarItemAppearance(tabBarAppearance.stackedLayoutAppearance)
        configureTabBarItemAppearance(tabBarAppearance.inlineLayoutAppearance)
        configureTabBarItemAppearance(tabBarAppearance.compactInlineLayoutAppearance)

        let tabBar = UITabBar.appearance()
        tabBar.tintColor = AppTheme.accent
        tabBar.unselectedItemTintColor = AppTheme.secondaryText
        tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = tabBarAppearance
        }
    }

    private func configureTabBarItemAppearance(_ appearance: UITabBarItemAppearance) {
        appearance.normal.iconColor = AppTheme.secondaryText
        appearance.normal.titleTextAttributes = [.foregroundColor: AppTheme.secondaryText]
        appearance.selected.iconColor = AppTheme.accent
        appearance.selected.titleTextAttributes = [.foregroundColor: AppTheme.accent]
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
        Hotwire.config.defaultViewController = { url in
            AppWebViewController(url: url)
        }
        Hotwire.registerBridgeComponents([
            ThemeBridgeComponent.self,
            PushNotificationBridgeComponent.self
        ])

#if DEBUG
        Hotwire.config.debugLoggingEnabled = true
#endif
    }
}
