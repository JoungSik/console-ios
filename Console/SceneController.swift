import HotwireNative
import UIKit
import WebKit

final class SceneController: UIResponder {
    var window: UIWindow?

    private static let sessionCookieName = "session_id"

    private var isAuthenticating = false
    private var isPresentingAuthentication = false
    private lazy var tabBarController = HotwireTabBarController(
        navigatorDelegate: self,
        lazyLoadTabs: true
    )

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
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        tabBarController.load(AppTabs.all)
    }
}

extension SceneController: NavigatorDelegate {
    func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
        guard proposal.url.path == AppEnvironment.appSettingsURL.path else {
            return .accept
        }

        return .acceptCustom(
            AppSettingsViewController {
                navigator.route(AppEnvironment.accountURL)
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
