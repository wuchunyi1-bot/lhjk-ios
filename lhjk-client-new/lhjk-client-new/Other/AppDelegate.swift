import UIKit
import UserNotifications

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 在 `UIApplicationMain` 之前尽早写入语言偏好，供系统相机/相册等控件读取。
    private static let localeBootstrap: Void = {
        let defaults = UserDefaults.standard
        defaults.set(["zh-Hans"], forKey: "AppleLanguages")
        defaults.set("zh-Hans", forKey: "AppleLocale")
        defaults.synchronize()
    }()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = Self.localeBootstrap
        configureAppLocale()
        // MARK: - SDK 初始化
        configureWindow()
        configurePushNotification(application)
        configureDatabase()
        configureThirdPartySDKs()
        configureRoutes()

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

    /// 系统控件（日期选择器 Cancel/Done、权限弹窗、相机等）优先使用简体中文。
    private func configureAppLocale() {
        let defaults = UserDefaults.standard
        defaults.set(["zh-Hans"], forKey: "AppleLanguages")
        defaults.set("zh-Hans", forKey: "AppleLocale")
        defaults.synchronize()
    }

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
        // 融云 IM SDK
        RongCloudManager.shared.initialize(appKey: "k51hidwqkor2b")
        RongCloudMessageDelegate.shared.register()

        // 微信 Open SDK（登录 / 分享 / 支付统一入口；AppID 见 WeChatConfig）
        WeChatSDKManager.shared.register()

        // TODO: 支付宝 SDK 注册
    }

    // MARK: - URL / Universal Link（微信回调兜底；Scene 生命周期优先走 SceneDelegate）

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if WeChatSDKManager.shared.handleOpenURL(url) {
            return true
        }
        return false
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if WeChatSDKManager.shared.handleUniversalLink(userActivity) {
            return true
        }
        return false
    }

    private func configureRoutes() {
        RouteSetup.registerAll()
    }
}
