import UIKit
import Combine

/// 根 TabBar 控制器 — 集成 5 大业务模块入口
final class RootTabBarController: UITabBarController {

    private var messageNav: BaseNavigationController?
    private var cancellables = Set<AnyCancellable>()
    private var didScheduleServiceHubPreload = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureAppearance()
        setupBadgeSubscription()
        scheduleServiceHubPreloadIfNeeded()
    }

    /// 冷启动 / 登录进主界面后延迟预拉服务 Hub 静态层（无 TTL；与 SceneDelegate 登录态路径共用）
    private func scheduleServiceHubPreloadIfNeeded() {
        guard !didScheduleServiceHubPreload else { return }
        didScheduleServiceHubPreload = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            print("[RootTab] service hub preloadStatic → start")
            await AppContainer.shared.serviceHubCacheService.preloadStatic()
            print("[RootTab] service hub preloadStatic → done hasLoaded=\(AppContainer.shared.serviceHubCacheService.hasLoadedStatic)")
        }
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
        let msgNav = BaseNavigationController(rootViewController: messageVC)
        msgNav.tabBarItem = UITabBarItem(
            title: "消息",
            image: UIImage(systemName: "message"),
            selectedImage: UIImage(systemName: "message.fill")
        )
        messageNav = msgNav

        // 我的
        let myVC = MyViewController()
        let myNav = BaseNavigationController(rootViewController: myVC)
        myNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeNav, healthNav, serviceNav, msgNav, myNav]
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Badge

    private func setupBadgeSubscription() {
        IMService.shared.totalUnreadCountDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] totalUnread in
                self?.updateMessageBadge(totalUnread)
            }
            .store(in: &cancellables)
    }

    private func updateMessageBadge(_ totalUnread: Int) {
        if totalUnread > 0 {
            let text = totalUnread > 99 ? "99+" : "\(totalUnread)"
            messageNav?.tabBarItem.badgeValue = text
        } else {
            messageNav?.tabBarItem.badgeValue = nil
        }
    }
}
