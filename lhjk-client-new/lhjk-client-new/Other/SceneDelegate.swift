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
