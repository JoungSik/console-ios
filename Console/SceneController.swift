import HotwireNative
import UIKit

final class SceneController: UIResponder {
    var window: UIWindow?

    private var isPresentingAuthentication = false
    private lazy var tabBarController = HotwireTabBarController(
        navigatorDelegate: self,
        lazyLoadTabs: true
    )

    private func promptForAuthentication(from visitable: Visitable) {
        guard !isPresentingAuthentication,
              visitable.currentVisitableURL.path != AppEnvironment.loginURL.path else {
            present(errorMessage: "로그인 화면을 불러올 수 없습니다.")
            return
        }

        isPresentingAuthentication = true
        tabBarController.activeNavigator.pop(animated: false)
        tabBarController.activeNavigator.route(AppEnvironment.loginURL)
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
            promptForAuthentication(from: visitable)
        default:
            if let errorPresenter = visitable as? ErrorPresenter {
                errorPresenter.presentError(error, retryHandler: retryHandler)
            } else {
                present(errorMessage: error.localizedDescription)
            }
        }
    }

    func requestDidFinish(at url: URL) {
        isPresentingAuthentication = url.path == AppEnvironment.loginURL.path
    }
}
