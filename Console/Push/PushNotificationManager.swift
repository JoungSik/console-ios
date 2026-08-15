import FirebaseCore
import FirebaseInstallations
import FirebaseMessaging
import os
import UIKit
import UserNotifications

@MainActor
final class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    private static let installationIDKey = "Console.pushNotificationInstallationID"

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Console",
        category: "PushNotification"
    )
    private var remoteRegistrationContinuation: CheckedContinuation<Void, Error>?

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self

        guard let configurationURL = Bundle.main.url(
            forResource: "GoogleService-Info",
            withExtension: "plist"
        ), let options = FirebaseOptions(contentsOfFile: configurationURL.path) else {
            logger.error("GoogleService-Info.plist가 없어 Firebase Messaging을 구성하지 못했습니다.")
            return
        }

        FirebaseApp.configure(options: options)
        Messaging.messaging().delegate = self

        guard storedInstallationID != nil else {
            return
        }

        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func currentState() async -> PushNotificationResponse {
        let permission = await permissionStatus()

        guard FirebaseApp.app() != nil else {
            return PushNotificationResponse(
                permission: permission,
                registered: false,
                error: .firebaseNotConfigured
            )
        }

        return PushNotificationResponse(
            firebaseInstallationId: storedInstallationID,
            permission: permission,
            registered: storedInstallationID != nil
        )
    }

    func subscribe() async -> PushNotificationResponse {
        guard FirebaseApp.app() != nil else {
            return await failureResponse(.firebaseNotConfigured)
        }

        if await permissionStatus() == .denied {
            await openNotificationSettings()
            return await failureResponse(.permissionDenied)
        }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            guard granted else {
                return await failureResponse(.permissionDenied)
            }

            try await registerForRemoteNotifications()
            Messaging.messaging().isAutoInitEnabled = true
            try await registerWithFirebaseMessaging()

            let installationID = try await firebaseInstallationID()
            storedInstallationID = installationID

            return PushNotificationResponse(
                firebaseInstallationId: installationID,
                permission: .granted,
                registered: true
            )
        } catch {
            logger.error("푸시 알림 등록 실패: \(error.localizedDescription, privacy: .public)")
            return await failureResponse(.registrationFailed)
        }
    }

    func unsubscribe() async -> PushNotificationResponse {
        guard FirebaseApp.app() != nil else {
            return await failureResponse(.firebaseNotConfigured)
        }

        Messaging.messaging().isAutoInitEnabled = false

        do {
            try await unregisterFromFirebaseMessaging()
            storedInstallationID = nil
            try await deleteFirebaseInstallation()

            return PushNotificationResponse(
                permission: await permissionStatus(),
                registered: false
            )
        } catch {
            logger.error("푸시 알림 등록 해제 실패: \(error.localizedDescription, privacy: .public)")
            return await failureResponse(.unregistrationFailed)
        }
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        remoteRegistrationContinuation?.resume()
        remoteRegistrationContinuation = nil
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        remoteRegistrationContinuation?.resume(throwing: error)
        remoteRegistrationContinuation = nil
    }

    private var storedInstallationID: String? {
        get { UserDefaults.standard.string(forKey: Self.installationIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.installationIDKey) }
    }

    private func permissionStatus() async -> PushNotificationPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .prompt
        @unknown default:
            return .prompt
        }
    }

    private func openNotificationSettings() async {
        let settingsURLString: String
        if #available(iOS 16.0, *) {
            settingsURLString = UIApplication.openNotificationSettingsURLString
        } else {
            settingsURLString = UIApplication.openSettingsURLString
        }

        guard let settingsURL = URL(string: settingsURLString) else {
            return
        }

        _ = await UIApplication.shared.open(settingsURL)
    }

    private func failureResponse(_ error: PushNotificationError) async -> PushNotificationResponse {
        PushNotificationResponse(
            firebaseInstallationId: storedInstallationID,
            permission: await permissionStatus(),
            registered: storedInstallationID != nil,
            error: error
        )
    }

    private func registerForRemoteNotifications() async throws {
        try await withCheckedThrowingContinuation { continuation in
            remoteRegistrationContinuation = continuation
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    private func firebaseInstallationID() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Installations.installations().installationID { installationID, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let installationID, !installationID.isEmpty {
                    continuation.resume(returning: installationID)
                } else {
                    continuation.resume(throwing: PushNotificationManagerError.missingInstallationID)
                }
            }
        }
    }

    private func registerWithFirebaseMessaging() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Messaging.messaging().register { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func unregisterFromFirebaseMessaging() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Messaging.messaging().unregister { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func deleteFirebaseInstallation() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Installations.installations().delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension PushNotificationManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistration installationID: String?) {
        guard let installationID, !installationID.isEmpty else {
            return
        }

        Task { @MainActor in
            guard Messaging.messaging().isAutoInitEnabled else {
                return
            }

            storedInstallationID = installationID
        }
    }

    nonisolated func messaging(_ messaging: Messaging, didUnregister installationID: String) {
        Task { @MainActor in
            guard storedInstallationID == installationID else {
                return
            }

            storedInstallationID = nil
        }
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let destinationURL = PushNotificationDestination.url(
            from: response.notification.request.content.userInfo
        ) else {
            return
        }

        await PushNotificationNavigationCenter.open(destinationURL)
    }
}

private enum PushNotificationManagerError: Error {
    case missingInstallationID
}

enum PushNotificationPermission: String, Encodable {
    case granted
    case denied
    case prompt
}

enum PushNotificationError: String, Encodable {
    case firebaseNotConfigured = "firebase_not_configured"
    case permissionDenied = "permission_denied"
    case registrationFailed = "registration_failed"
    case unregistrationFailed = "unregistration_failed"
}

struct PushNotificationResponse: Encodable {
    let firebaseInstallationId: String?
    let platform = "ios"
    let permission: PushNotificationPermission
    let registered: Bool
    let error: PushNotificationError?

    init(
        firebaseInstallationId: String? = nil,
        permission: PushNotificationPermission,
        registered: Bool,
        error: PushNotificationError? = nil
    ) {
        self.firebaseInstallationId = firebaseInstallationId
        self.permission = permission
        self.registered = registered
        self.error = error
    }
}

enum PushNotificationDestination {
    static func url(from userInfo: [AnyHashable: Any]) -> URL? {
        guard let destination = userInfo["url"] as? String,
              let url = URL(string: destination, relativeTo: AppEnvironment.baseURL)?.absoluteURL,
              url.scheme == AppEnvironment.baseURL.scheme,
              url.host == AppEnvironment.baseURL.host,
              url.port == AppEnvironment.baseURL.port else {
            return nil
        }

        return url
    }
}

@MainActor
enum PushNotificationNavigationCenter {
    static let didRequestOpen = Notification.Name("Console.didRequestOpenPushNotification")

    private static var pendingURL: URL?

    static func open(_ url: URL) {
        pendingURL = url
        NotificationCenter.default.post(name: didRequestOpen, object: nil)
    }

    static func takePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }
}
