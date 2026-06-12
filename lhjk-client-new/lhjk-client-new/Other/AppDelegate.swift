import UIKit
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // MARK: - SDK 初始化
        configureWindow()
        configurePushNotification(application)
        configureDatabase()
        configureThirdPartySDKs()

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // 清理被丢弃的 Scene 相关资源
    }

    // MARK: - Push Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // 将 deviceToken 发送至服务端，绑定推送设备
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[APNs] Device token: \(tokenString)")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[APNs] Registration failed: \(error.localizedDescription)")
    }

    // MARK: - Private Setup

    private func configureWindow() {
        // AppDelegate 不再负责 window 管理，由 SceneDelegate 负责
    }

    private func configurePushNotification(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    private func configureDatabase() {
        // TODO: 数据库初始化（FMDB）
    }

    private func configureThirdPartySDKs() {
        // TODO: 融云 SDK 初始化
        // TODO: 微信 SDK 注册
        // TODO: 支付宝 SDK 注册
    }
}
