import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        // 产品 UI 仅适配浅色；系统暗黑会导致 TabBar / 系统控件反色异常
        window?.overrideUserInterfaceStyle = .light

        SessionExpiryCoordinator.shared.presentExpiredUI = { message, onRelogin in
            SessionExpiryPresenter.present(message: message, onRelogin: onRelogin)
        }
        SessionExpiryCoordinator.shared.install()

        presentSplash()
    }

    // MARK: - Root Routing

    private func presentSplash() {
        let splash = SplashViewController()
        splash.onFinish = { [weak self] in
            self?.transitionToMainInterface()
        }
        window?.rootViewController = splash
        window?.makeKeyAndVisible()
    }

    private func transitionToMainInterface() {
        let nextRoot = makeMainRootViewController()
        guard let window else { return }

        UIView.transition(
            with: window,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = nextRoot
            }
        )

        if UserDefaults.standard.string(forKey: "auth_access_token") != nil {
            restoreIMConnection()
            bootstrapLoggedInSession()
        }
    }

    private func makeMainRootViewController() -> UIViewController {
        let hasToken = UserDefaults.standard.string(forKey: "auth_access_token") != nil
        if hasToken {
            return RootTabBarController()
        }
        return LoginViewController()
    }

    private func bootstrapLoggedInSession() {
        Task {
            await DictionaryCacheService.shared.sync()
            _ = await UserManager.shared.fetchUserInfo()
            _ = await UserManager.shared.fetchDefaultArchive()
            _ = await UserManager.shared.fetchArchiveCompletion()
            let needOnboarding = UserManager.shared.checkNeedOnboarding()

            await MainActor.run {
                if needOnboarding {
                    print("[SceneDelegate] archiveComplete incomplete → presenting onboarding")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        Router.shared.present("/onboarding")
                    }
                } else {
                    print("[SceneDelegate] onboarding skip; profile & archive fetch done")
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // 系统释放 scene 时调用（资源清理）
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 应用从非活跃状态变为活跃状态
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // 应用即将从活跃状态变为非活跃状态（如来电打断）
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // 热启动：融云 SDK 内部自动维持/恢复长连接，无需 App 侧干预
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 应用进入后台，保存状态、释放资源
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = WeChatSDKManager.shared.handleOpenURL(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if WeChatSDKManager.shared.handleUniversalLink(userActivity) {
            return
        }
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let webpageURL = userActivity.webpageURL else {
            return
        }
        print("Received Universal Link: \(webpageURL.absoluteString)")
    }
    

    // MARK: - IM Connection

    /// 冷启动恢复 IM 连接：有本地 token 则直接连接，没有则重新获取
    private func restoreIMConnection() {
        let rc = RongCloudManager.shared

        if rc.currentToken != nil {
            print("[SceneDelegate] IM cold start → reconnect with stored token")
            rc.reconnect()
        } else {
            print("[SceneDelegate] IM cold start → token missing, fetching...")
            rc.fetchTokenAndConnect()
        }
    }
}
