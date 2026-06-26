import UIKit

/// 根 TabBar 控制器 — 集成 6 大业务模块入口
final class RootTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureAppearance()
    }

    private func setupViewControllers() {
        // 首页
        let homeVC = HomeViewController()
        let homeNav = BaseNavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        // 健康
        let healthVC = HealthViewController()
        let healthNav = BaseNavigationController(rootViewController: healthVC)
        healthNav.tabBarItem = UITabBarItem(
            title: "健康",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        // 服务
        let serviceVC = ServiceViewController()
        let serviceNav = BaseNavigationController(rootViewController: serviceVC)
        serviceNav.tabBarItem = UITabBarItem(
            title: "服务",
            image: UIImage(systemName: "shield"),
            selectedImage: UIImage(systemName: "shield.fill")
        )
        // 待使用服务数量角标
        let pendingCount = 2  // Mock: services.json orders.pending
        if pendingCount > 0 {
            serviceNav.tabBarItem.badgeValue = "\(pendingCount)"
        }

        // 消息
        let messageVC = MessagesViewController()
        let messageNav = BaseNavigationController(rootViewController: messageVC)
        messageNav.tabBarItem = UITabBarItem(
            title: "消息",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )

        // 我的
        let myVC = MyViewController()
        let myNav = BaseNavigationController(rootViewController: myVC)
        myNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeNav, healthNav, serviceNav, messageNav, myNav]
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
