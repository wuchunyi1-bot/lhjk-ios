import UIKit

/// 基础导航控制器 — 统一配置导航栏外观，自动处理 TabBar 显隐
class BaseNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 当导航栈深度 >= 1 时（即 push 的是二级及以上页面），自动隐藏 TabBar
        if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }
}
