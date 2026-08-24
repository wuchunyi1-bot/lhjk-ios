import UIKit
import Combine

/// 根 TabBar 控制器 — 集成 5 大业务模块入口
final class RootTabBarController: UITabBarController {

    private var messageNav: BaseNavigationController?
    private var cancellables = Set<AnyCancellable>()
    private var didScheduleHubPreload = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureAppearance()
        setupBadgeSubscription()
        scheduleHubPreloadIfNeeded()
    }

    /// 冷启动 / 登录进主界面后延迟预拉服务 Hub 与健康 Hub（无 TTL；与 SceneDelegate 登录态路径共用）
    private func scheduleHubPreloadIfNeeded() {
        guard !didScheduleHubPreload else { return }
        didScheduleHubPreload = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            print("[RootTab] columnContent preloadColdStart → start")
            await AppContainer.shared.columnContentCacheService.preloadColdStart()
            print("[RootTab] columnContent preloadColdStart → done")

            print("[RootTab] service hub preloadStatic → start")
            await AppContainer.shared.serviceHubCacheService.preloadStatic()
            let hubLoaded = await AppContainer.shared.serviceHubCacheService.hasLoadedStatic
            print("[RootTab] service hub preloadStatic → done hasLoaded=\(hubLoaded)")

            print("[RootTab] health hub preload → start")
            let healthHub = await AppContainer.shared.healthPageCacheService.preload()
            let cardCount = healthHub?.monitorCards.count ?? 0
            let healthLoaded = await AppContainer.shared.healthPageCacheService.hasLoaded
            print("[RootTab] health hub preload → done hasLoaded=\(healthLoaded) cards=\(cardCount)")
        }
    }

    private func setupViewControllers() {
        // 首页
        let homeVC = HomeViewController()
        let homeNav = BaseNavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(named: "tab_home_normal")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_home_selected")?.withRenderingMode(.alwaysOriginal)
        )

        // 健康
        let healthVC = HealthViewController()
        let healthNav = BaseNavigationController(rootViewController: healthVC)
        healthNav.tabBarItem = UITabBarItem(
            title: "健康",
            image: UIImage(named: "tab_health_normal")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_health_selected")?.withRenderingMode(.alwaysOriginal)
        )

        // 服务
        let serviceVC = ServiceViewController()
        let serviceNav = BaseNavigationController(rootViewController: serviceVC)
        serviceNav.tabBarItem = UITabBarItem(
            title: "服务",
            image: UIImage(named: "tab_service_normal")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_service_selected")?.withRenderingMode(.alwaysOriginal)
        )

        // 消息
        let messageVC = MessagesViewController()
        let msgNav = BaseNavigationController(rootViewController: messageVC)
        msgNav.tabBarItem = UITabBarItem(
            title: "消息",
            image: UIImage(named: "tab_message_normal")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_message_selected")?.withRenderingMode(.alwaysOriginal)
        )
        messageNav = msgNav

        // 我的
        let myVC = MyViewController()
        let myNav = BaseNavigationController(rootViewController: myVC)
        myNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(named: "tab_my_normal")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "tab_my_selected")?.withRenderingMode(.alwaysOriginal)
        )

        viewControllers = [homeNav, healthNav, serviceNav, msgNav, myNav]
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .fdSurface
        appearance.shadowColor = .fdBorder

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = .fdMuted
        normal.titleTextAttributes = [
            .foregroundColor: UIColor.fdMuted,
            .font: UIFont.fdFont(ofSize: 14, weight: .regular),
        ]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = .fdPrimary
        selected.titleTextAttributes = [
            .foregroundColor: UIColor.fdPrimary,
            .font: UIFont.fdFont(ofSize: 14, weight: .medium),
        ]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = false
        tabBar.tintColor = .fdPrimary
        tabBar.unselectedItemTintColor = .fdMuted
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTabBarItemsForHomeIndicator()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        adjustTabBarItemsForHomeIndicator()
    }

    /// iPhone X 等带 Home Indicator 机型：上移图标与标题，避免与底部横条重叠。
    private func adjustTabBarItemsForHomeIndicator() {
        let bottomInset = view.safeAreaInsets.bottom
        let titleOffset = bottomInset > 0 ? UIOffset(horizontal: 0, vertical: -6) : .zero
        let imageInsets = bottomInset > 0
            ? UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
            : .zero

        viewControllers?.forEach { vc in
            guard let item = vc.tabBarItem else { return }
            if item.titlePositionAdjustment != titleOffset {
                item.titlePositionAdjustment = titleOffset
            }
            if item.imageInsets != imageInsets {
                item.imageInsets = imageInsets
            }
        }
    }

    // MARK: - Badge

    private func setupBadgeSubscription() {
        updateMessageBadge(IMService.shared.totalUnreadCount())
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

// MARK: - Tab Indices

extension RootTabBarController {
    enum Tab {
        static let home = 0
        static let health = 1
        static let service = 2
        static let message = 3
        static let my = 4
    }
}
