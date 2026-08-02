import Foundation
import HotwireNative

@MainActor
final class ThemeBridgeComponent: BridgeComponent {
    override nonisolated class var name: String { "theme" }

    override func onReceive(message: Message) {
        guard message.event == Event.sync.rawValue,
              let payload: Payload = message.data(),
              !payload.owner.isEmpty else {
            return
        }

        ThemeSyncCenter.post(
            ServerTheme(owner: payload.owner, preference: payload.preference)
        )
    }
}

private extension ThemeBridgeComponent {
    enum Event: String {
        case sync
    }

    struct Payload: Decodable {
        let owner: String
        let preference: ThemePreference
    }
}

enum ThemeSyncCenter {
    static let didReceiveServerTheme = Notification.Name("Console.didReceiveServerTheme")

    @MainActor
    static func post(_ theme: ServerTheme) {
        NotificationCenter.default.post(name: didReceiveServerTheme, object: theme)
    }

    static func theme(from notification: Notification) -> ServerTheme? {
        notification.object as? ServerTheme
    }
}
