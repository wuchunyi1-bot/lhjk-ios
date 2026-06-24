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
        window?.rootViewController = RootTabBarController()
        window?.makeKeyAndVisible()

        // 已登录但未完成完善信息 → 强制展示 onboarding
        checkOnboardingRequired()

        // 已登录且已完善信息 → 预加载用户信息
        let hasToken = UserDefaults.standard.string(forKey: "auth_access_token") != nil
        let onboarded = UserDefaults.standard.bool(forKey: "fd_onboarded")
        if hasToken && onboarded {
            Task { await UserManager.shared.fetchUserInfo() }
        }
    }

    /// 检查本地登录态：有 token 但未完成完善信息 → 弹出 onboarding
    private func checkOnboardingRequired() {
        let hasToken = UserDefaults.standard.string(forKey: "auth_access_token") != nil
        let onboarded = UserDefaults.standard.bool(forKey: "fd_onboarded")
        guard hasToken && !onboarded else { return }
        print("[SceneDelegate] hasToken=true onboarded=false → presenting onboarding")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Router.shared.present("/onboarding")
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
        // 应用从后台进入前台
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // 应用进入后台，保存状态、释放资源
    }
}
