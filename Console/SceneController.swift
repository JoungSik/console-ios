import HotwireNative
import UIKit

final class SceneController: UIResponder {
    var window: UIWindow?

    private lazy var navigator = Navigator(
        configuration: .init(
            name: "Console",
            startLocation: AppEnvironment.baseURL
        )
    )
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
        window?.rootViewController = navigator.rootViewController
        window?.makeKeyAndVisible()
        navigator.start()
    }
}
