import Combine
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
        AppIconBadgeSync.install()

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
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[APNs] Device token: \(tokenString)")
        RongCloudManager.shared.setDeviceTokenData(deviceToken)
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

    /// 冷启动不主动弹系统授权框；仅在系统已授权时注册 APNs（引导见登录后 App 内弹窗 PRD §5.7）
    private func configurePushNotification(_ application: UIApplication) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral
            guard authorized else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
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

        AlipaySDKManager.shared.register()
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
        if AlipaySDKManager.shared.handleOpenURL(url) {
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

/// 桌面 App 图标角标与 `IMService.totalUnreadCount()` 对齐（与消息 Tab 同源）。
///
/// 推送 payload 的 `badge` 只负责后台把数字写上 SpringBoard；App 内已读不会自动改桌面角标，必须显式回写。
enum AppIconBadgeSync {
    private static var cancellable: AnyCancellable?
    /// 本进程是否已根据真实未读快照写过桌面角标（含登出归零）
    private static var hasAppliedRealCount = false

    static func install() {
        guard cancellable == nil else { return }
        cancellable = IMService.shared.totalUnreadCountDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { apply($0) }
    }

    static func apply(_ unread: Int) {
        let count = max(0, unread)
        let loaded = IMService.shared.hasLoadedConversations
        // 冷启动尚未拉会话时 total=0 是占位，不要把推送留下的桌面角标先抹掉。
        // 登出 `clear()` 同样是 0 + hasLoaded=false，但此时已经写过真实快照，必须清零。
        if count == 0 && !loaded && !hasAppliedRealCount {
            return
        }
        hasAppliedRealCount = true
        write(count)
    }

    /// 从后台回前台：用当前未读覆盖 APNs 可能留下的旧数字
    static func syncIfLoaded() {
        guard IMService.shared.hasLoadedConversations || hasAppliedRealCount else { return }
        write(max(0, IMService.shared.totalUnreadCount()))
    }

    private static func write(_ count: Int) {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count) { error in
                if error != nil {
                    DispatchQueue.main.async {
                        UIApplication.shared.applicationIconBadgeNumber = count
                    }
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}
