import HotwireNative
import UIKit

@MainActor
final class NavigatorThemeInvalidator {
    private var pendingNavigatorIdentifiers = Set<ObjectIdentifier>()

    func invalidate(_ navigators: [Navigator], activeNavigator: Navigator) {
        for navigator in navigators {
            invalidate(navigator)

            if navigator !== activeNavigator, hasLoadedContent(navigator) {
                pendingNavigatorIdentifiers.insert(ObjectIdentifier(navigator))
            }
        }
    }

    func refreshIfNeeded(_ navigator: Navigator) {
        let identifier = ObjectIdentifier(navigator)
        guard pendingNavigatorIdentifiers.remove(identifier) != nil else {
            return
        }

        navigator.reload()
    }

    func reset() {
        pendingNavigatorIdentifiers.removeAll()
    }

    private func invalidate(_ navigator: Navigator) {
        invalidate(navigator.session)
        invalidate(navigator.modalSession)
        clearScreenshots(in: navigator.rootViewController)
        clearScreenshots(in: navigator.modalRootViewController)
    }

    private func invalidate(_ session: Session) {
        session.clearSnapshotCache()

        guard session.topmostVisitable != nil else {
            return
        }

        session.markSnapshotCacheAsStale()
    }

    private func hasLoadedContent(_ navigator: Navigator) -> Bool {
        navigator.rootViewController.topViewController is Visitable ||
            navigator.modalRootViewController.topViewController is Visitable
    }

    private func clearScreenshots(in navigationController: UINavigationController) {
        navigationController.viewControllers
            .compactMap { $0 as? Visitable }
            .map(\.visitableView)
            .forEach { visitableView in
                visitableView.hideScreenshot()
                visitableView.clearScreenshot()
            }
    }
}
