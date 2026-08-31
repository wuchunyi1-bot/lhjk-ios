import Foundation
import UIKit
import UserNotifications

/// 「开启消息通知弹窗」频控与系统授权读取 — 对齐注册登录 PRD §5.7
final class NotificationPromptService {

    static let shared = NotificationPromptService()

    private enum StorageKey {
        static let lastDismissAt = "fd_notification_prompt_last_dismiss_at"
        static let lastDismissAction = "fd_notification_prompt_last_action"
        static let lastDismissAuthorized = "fd_notification_prompt_last_authorized"
    }

    enum PromptAction: String {
        case enable
        case skip
    }

    enum LoginPromptDecision {
        /// 系统已授权，跳过弹窗
        case skipAlreadyAuthorized
        /// 频控冷却或未命中展示条件
        case skipCooldown
        /// 展示 App 内引导弹窗
        case show
    }

    private let cooldownDays = 30
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - System authorization

    func isSystemNotificationAuthorized() async -> Bool {
        let settings = await notificationSettings()
        return isAuthorized(settings.authorizationStatus)
    }

    func refreshSystemNotificationStatus() async -> Bool {
        await isSystemNotificationAuthorized()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }

    /// 弹出系统授权框（仅 `.notDetermined`）；已授权时注册 APNs。返回请求后的真实授权状态。
    func requestSystemAuthorization() async -> Bool {
        let settings = await notificationSettings()
        if settings.authorizationStatus != .notDetermined {
            let authorized = isAuthorized(settings.authorizationStatus)
            if authorized {
                await registerForRemoteNotificationsOnMainActor()
            }
            return authorized
        }

        let granted = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                continuation.resume(returning: granted)
            }
        }

        if granted {
            await registerForRemoteNotificationsOnMainActor()
            return true
        }
        return await isSystemNotificationAuthorized()
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Login prompt

    /// 登录/注册成功后判断是否展示「开启消息通知弹窗」
    func loginPromptDecision() async -> LoginPromptDecision {
        let settings = await notificationSettings()
        let authorized = isAuthorized(settings.authorizationStatus)
        if authorized {
            return .skipAlreadyAuthorized
        }
        if isWithinCooldown() {
            return .skipCooldown
        }
        return .show
    }

    /// 关闭弹窗时记录操作与当时的系统真实授权状态（用于 30 天频控与埋点）
    func recordPromptClosed(action: PromptAction, systemAuthorized: Bool) {
        defaults.set(Date().timeIntervalSince1970, forKey: StorageKey.lastDismissAt)
        defaults.set(action.rawValue, forKey: StorageKey.lastDismissAction)
        defaults.set(systemAuthorized, forKey: StorageKey.lastDismissAuthorized)
        print(
            "[NotificationPrompt] closed action=\(action.rawValue) "
                + "systemAuthorized=\(systemAuthorized)"
        )
    }

    func registerForRemoteNotificationsIfNeeded() {
        Task {
            guard await isSystemNotificationAuthorized() else { return }
            await registerForRemoteNotificationsOnMainActor()
        }
    }

    // MARK: - Private

    private func registerForRemoteNotificationsOnMainActor() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    private func notificationSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }

    private func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional || status == .ephemeral
    }

    private func isWithinCooldown() -> Bool {
        let last = defaults.double(forKey: StorageKey.lastDismissAt)
        guard last > 0 else { return false }
        let elapsed = Date().timeIntervalSince1970 - last
        return elapsed < Double(cooldownDays) * 24 * 60 * 60
    }
}
