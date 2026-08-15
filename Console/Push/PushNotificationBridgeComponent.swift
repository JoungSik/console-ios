import HotwireNative

@MainActor
final class PushNotificationBridgeComponent: BridgeComponent {
    override nonisolated class var name: String { "push-notification" }

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else {
            return
        }

        Task {
            let response: PushNotificationResponse

            switch event {
            case .connect:
                response = await PushNotificationManager.shared.currentState()
            case .subscribe:
                response = await PushNotificationManager.shared.subscribe()
            case .unsubscribe:
                response = await PushNotificationManager.shared.unsubscribe()
            }

            _ = try? await reply(with: message.replacing(data: response))
        }
    }
}

private extension PushNotificationBridgeComponent {
    enum Event: String {
        case connect
        case subscribe
        case unsubscribe
    }
}
