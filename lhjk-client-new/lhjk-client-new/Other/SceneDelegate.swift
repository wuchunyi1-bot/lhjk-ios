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

        let hasToken = UserDefaults.standard.string(forKey: "auth_access_token") != nil

        if hasToken {
            // 已登录 → 主界面
            window?.rootViewController = RootTabBarController()
            window?.makeKeyAndVisible()

            // 冷启动：恢复 IM 连接
            restoreIMConnection()

            // 服务 Hub 静态预拉由 RootTabBarController 延迟触发（覆盖冷启动与登录 setRoot）

            // 两套数据并行、互不依赖：
            // 1) 本地 loginUserInfo → Onboarding 门禁
            // 2) 网络 getCurrentUserBaseInfo → App 业务 currentUser
            Task {
                async let profile: SUsers? = UserManager.shared.fetchUserInfo()
                let needOnboarding = UserManager.shared.checkNeedOnboarding()
                _ = await profile

                await MainActor.run {
                    if needOnboarding {
                        print("[SceneDelegate] loginUserInfo incomplete → presenting onboarding")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            Router.shared.present("/onboarding")
                        }
                    } else {
                        print("[SceneDelegate] onboarding skip; profile fetch done")
                    }
                }
            }
        } else {
            // 未登录 → 登录页
            window?.rootViewController = LoginViewController()
            window?.makeKeyAndVisible()
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
