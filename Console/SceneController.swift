import HotwireNative
import UIKit
import WebKit

@MainActor
final class SceneController: UIResponder {
    var window: UIWindow?

    private static let sessionCookieName = "session_id"

    private var isAuthenticating = false
    private var isPresentingAuthentication = false
    private let themeSynchronizer = AppThemeSynchronizer()
    private let themeInvalidator = NavigatorThemeInvalidator()
    private lazy var tabBarController = HotwireTabBarController(
        navigatorDelegate: self,
        lazyLoadTabs: true
    )

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveServerTheme(_:)),
            name: ThemeSyncCenter.didReceiveServerTheme,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didRequestOpenPushNotification),
            name: PushNotificationNavigationCenter.didRequestOpen,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didReceiveServerTheme(_ notification: Notification) {
        guard let window,
              let theme = ThemeSyncCenter.theme(from: notification),
              themeSynchronizer.synchronize(theme, to: window) else {
            return
        }

        let navigators = AppTabs.all.compactMap { tabBarController.navigator(for: $0) }
        themeInvalidator.invalidate(
            navigators,
            activeNavigator: tabBarController.activeNavigator
        )
    }

    @objc private func didRequestOpenPushNotification() {
        openPendingPushNotificationIfNeeded()
    }

    private func openPendingPushNotificationIfNeeded() {
        guard window != nil,
              let url = PushNotificationNavigationCenter.takePendingURL() else {
            return
        }

        tabBarController.activeNavigator.route(url)
    }

    private func completeAuthenticationIfNeeded() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else {
                return
            }

            let hasSessionCookie = cookies.contains(where: self.isSessionCookie)

            DispatchQueue.main.async {
                guard hasSessionCookie else {
                    self.isPresentingAuthentication = true
                    return
                }

                self.isPresentingAuthentication = false
                self.resetTabs()
            }
        }
    }

    private func isSessionCookie(_ cookie: HTTPCookie) -> Bool {
        guard cookie.name == Self.sessionCookieName,
              let host = AppEnvironment.baseURL.host else {
            return false
        }

        let cookieDomain = cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return host == cookieDomain || host.hasSuffix(".\(cookieDomain)")
    }

    private func resetTabs() {
        if let window {
            themeSynchronizer.reset(to: window)
        }
        themeInvalidator.reset()

        AppTabs.all.compactMap { tabBarController.navigator(for: $0) }.forEach { navigator in
            navigator.session.clearSnapshotCache()
            navigator.modalSession.clearSnapshotCache()
            navigator.clearAll(animated: false)
        }

        tabBarController.selectedIndex = 0
        tabBarController.load(AppTabs.all)
    }

    private func promptForAuthentication(force: Bool = false) {
        if force {
            isPresentingAuthentication = false
        }

        guard !isPresentingAuthentication else {
            return
        }

        isPresentingAuthentication = true
        resetTabs()
        tabBarController.activeNavigator.route(AppEnvironment.loginURL)
    }

    private func authenticationPageDidLoad() {
        promptForAuthentication()
    }

    private func present(errorMessage: String) {
        let alert = UIAlertController(title: "오류", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        tabBarController.activeNavigator.present(alert, animated: true)
    }
}

extension SceneController: UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        window = UIWindow(windowScene: windowScene)
        guard let window else {
            return
        }

        themeSynchronizer.applyMirroredTheme(to: window)
        window.backgroundColor = AppTheme.background
        window.tintColor = AppTheme.accent
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        tabBarController.delegate = self
        tabBarController.load(AppTabs.all)
        openPendingPushNotificationIfNeeded()
    }
}

extension SceneController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        refreshSelectedTabIfNeeded()
    }

    @available(iOS 18.0, *)
    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelectTab selectedTab: UITab,
        previousTab: UITab?
    ) {
        refreshSelectedTabIfNeeded()
    }

    private func refreshSelectedTabIfNeeded() {
        let navigator = tabBarController.activeNavigator
        navigator.start()
        themeInvalidator.refreshIfNeeded(navigator)
    }
}

extension SceneController: @preconcurrency NavigatorDelegate {
    func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
        guard proposal.url.path == AppEnvironment.appSettingsURL.path else {
            return .accept
        }

        return .acceptCustom(
            AppSettingsViewController { url in
                navigator.route(url)
            }
        )
    }

    func visitableDidFailRequest(
        _ visitable: Visitable,
        error: HotwireNativeError,
        retryHandler: RetryBlock?
    ) {
        switch error {
        case .http(.client(.unauthorized)):
            promptForAuthentication(force: true)
        default:
            if let errorPresenter = visitable as? ErrorPresenter {
                errorPresenter.presentError(error, retryHandler: retryHandler)
            } else {
                present(errorMessage: error.localizedDescription)
            }
        }
    }

    func formSubmissionDidStart(to url: URL) {
        if url.path == AppEnvironment.loginURL.path {
            isAuthenticating = true
        }
    }

    func requestDidFinish(at url: URL) {
        if isAuthenticating {
            isAuthenticating = false
            completeAuthenticationIfNeeded()
        } else if url.path == AppEnvironment.loginURL.path {
            authenticationPageDidLoad()
        }
    }
}
