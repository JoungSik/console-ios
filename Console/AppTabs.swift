import HotwireNative
import UIKit

enum AppTabs {
    private static let home = HotwireTab(
        id: "home",
        title: "홈",
        image: UIImage(systemName: "house"),
        selectedImage: UIImage(systemName: "house.fill"),
        url: AppEnvironment.baseURL
    )

    private static let journal = HotwireTab(
        id: "journal",
        title: "저널",
        image: UIImage(systemName: "book.closed"),
        selectedImage: UIImage(systemName: "book.closed.fill"),
        url: AppEnvironment.journalURL
    )

    private static let todo = HotwireTab(
        id: "todo",
        title: "할 일",
        image: UIImage(systemName: "checkmark.circle"),
        selectedImage: UIImage(systemName: "checkmark.circle.fill"),
        url: AppEnvironment.todoURL
    )

    private static let settings = HotwireTab(
        id: "settings",
        title: "설정",
        image: UIImage(systemName: "gearshape"),
        selectedImage: UIImage(systemName: "gearshape.fill"),
        url: AppEnvironment.appSettingsURL
    )

    static let all = [home, journal, todo, settings]
}
