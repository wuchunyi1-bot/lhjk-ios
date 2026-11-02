import UIKit
import Combine

/// 根 TabBar 控制器 — 首页、健康、消息、我的
final class RootTabBarController: UITabBarController {

    private var messageNav: BaseNavigationController?
    private var cancellables = Set<AnyCancellable>()
    private var didScheduleHubPreload = false
    private let tabTitles: Set<String> = ["首页", "健康", "消息", "我的"]
    private let tabTitleOrder = ["首页", "健康", "消息", "我的"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        configureAppearance()
        setupBadgeSubscription()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSeniorModeChanged),
            name: UIFont.seniorModeDidChangeNotification,
            object: nil
        )
        scheduleHubPreloadIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fitTabBarTitlesIfNeeded()
    }

    /// 长辈模式字号变大后，系统底栏格子宽度不变，未选中项会被截成「...」。
    /// 只让标题在自己的格子里缩小，不换掉系统底栏。
    @objc private func onSeniorModeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.fitTabBarTitlesIfNeeded()
        }
    }

    private func fitTabBarTitlesIfNeeded() {
        fitTabTitles(in: tabBar)
    }

    private func fitTabTitles(in view: UIView) {
        if let label = view as? UILabel, let text = label.text, tabTitles.contains(text),
           !label.adjustsFontSizeToFitWidth || label.lineBreakMode != .byClipping {
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.8
            label.lineBreakMode = .byClipping
            label.numberOfLines = 1
            label.baselineAdjustment = .alignCenters
        }
        view.subviews.forEach { fitTabTitles(in: $0) }
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

        viewControllers = [homeNav, healthNav, msgNav, myNav]
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
            .font: UIFont.fdFont(ofSize: 12, weight: .regular),
        ]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = .fdPrimary
        selected.titleTextAttributes = [
            .foregroundColor: UIColor.fdPrimary,
            .font: UIFont.fdFont(ofSize: 12, weight: .medium),
        ]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.isTranslucent = false
        tabBar.tintColor = .fdPrimary
        tabBar.unselectedItemTintColor = .fdMuted

        // 24pt 自定义图标 + 标题需控制字号；布局交给系统 safe area，勿再改 item insets。
        viewControllers?.forEach { vc in
            vc.tabBarItem?.imageInsets = .zero
            vc.tabBarItem?.titlePositionAdjustment = .zero
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
        static let message = 2
        static let my = 3
    }

    /// 切到首页并打开指定页签。健康服务、富德优选都在首页里。
    static func selectHomeShelf(_ shelf: HomeShelf) {
        let switchTab = {
            guard let tabBar = findInKeyWindow() else { return }
            if tabBar.presentedViewController != nil {
                tabBar.dismiss(animated: false)
            }
            if let nav = tabBar.viewControllers?[Tab.home] as? UINavigationController,
               nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            HomeShelfStore.pending = shelf
            tabBar.selectedIndex = Tab.home
            NotificationCenter.default.post(
                name: HomeShelfStore.didRequestNotification,
                object: nil,
                userInfo: ["shelf": shelf.rawValue]
            )
        }
        if Thread.isMainThread {
            switchTab()
        } else {
            DispatchQueue.main.async(execute: switchTab)
        }
    }

    func guideHomeController() -> HomeViewController? {
        let nav = viewControllers?[Tab.home] as? UINavigationController
        return nav?.viewControllers.first as? HomeViewController
    }

    func guideHealthController() -> HealthViewController? {
        let nav = viewControllers?[Tab.health] as? UINavigationController
        return nav?.viewControllers.first as? HealthViewController
    }

    func guideSelectTab(_ index: Int) {
        selectedIndex = index
        view.layoutIfNeeded()
        tabBar.layoutIfNeeded()
    }

    func guideTabItemFrame(at index: Int, in target: UIView) -> CGRect? {
        view.layoutIfNeeded()
        tabBar.layoutIfNeeded()
        guard tabTitleOrder.indices.contains(index) else { return nil }
        if #available(iOS 26.0, *), let capsule = selectionCapsuleFrame(at: index) {
            return tabBar.convert(capsule, to: target)
        }
        if let button = tabButton(titled: tabTitleOrder[index], index: index),
           tabButton(button, isNearIndex: index) {
            return button.convert(button.bounds, to: target)
        }
        let icons = tabIconButtons()
        if icons.indices.contains(index) {
            return icons[index].convert(icons[index].bounds, to: target)
        }
        let count = CGFloat(tabTitleOrder.count)
        let width = tabBar.bounds.width / count
        let height = min(49, tabBar.bounds.height)
        let local = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        return tabBar.convert(local, to: target)
    }

    /// iOS 26 选中态是底栏里那颗胶囊，不是整颗按钮的外接椭圆。
    private func selectionCapsuleFrame(at index: Int) -> CGRect? {
        let slot = tabBar.bounds.width / CGFloat(tabTitleOrder.count)
        let expected = (CGFloat(index) + 0.5) * slot
        var pills: [CGRect] = []
        func walk(_ view: UIView) {
            let frame = view.convert(view.bounds, to: tabBar)
            let name = String(describing: type(of: view))
            let namedPill = name.localizedCaseInsensitiveContains("platter")
                || name.localizedCaseInsensitiveContains("selection")
                || name.localizedCaseInsensitiveContains("lens")
                || name.localizedCaseInsensitiveContains("highlight")
            let withinCapsule = frame.height >= 32 && frame.height <= 62
                && frame.width >= 44 && frame.width <= 120
            guard view.alpha > 0.01, !view.isHidden, !(view is UILabel), !(view is UIImageView) else {
                view.subviews.forEach(walk)
                return
            }
            if withinCapsule, namedPill || view.layer.cornerRadius >= 12,
               frame.minY >= -2,
               frame.maxY <= tabBar.bounds.height + 2,
               abs(frame.midX - expected) < slot * 0.65 {
                pills.append(frame)
            }
            view.subviews.forEach(walk)
        }
        walk(tabBar)
        let content = tabContentFrame(at: index)
        let containing = pills.filter { pill in
            guard let content else { return true }
            return pill.insetBy(dx: -4, dy: -4).contains(content)
        }
        let pool = containing.isEmpty ? pills : containing
        if let tightest = pool.min(by: { $0.width * $0.height < $1.width * $1.height }) {
            return tightest
        }
        guard let content else { return nil }
        let padded = content.insetBy(dx: -12, dy: -7)
        return padded.intersection(tabBar.bounds.insetBy(dx: 2, dy: 3))
    }

    /// 图标和标题的并集，用来在找不到系统胶囊时贴着选中内容挖。
    private func tabContentFrame(at index: Int) -> CGRect? {
        let title = tabTitleOrder[index]
        let slot = tabBar.bounds.width / CGFloat(tabTitleOrder.count)
        let expected = (CGFloat(index) + 0.5) * slot
        let label = tabTitleLabels(in: tabBar)
            .filter { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) == title && $0.alpha > 0.01 }
            .min {
                abs($0.convert($0.bounds, to: tabBar).midX - expected)
                    < abs($1.convert($1.bounds, to: tabBar).midX - expected)
            }
        let icons = tabIconViews().filter { abs($0.convert($0.bounds, to: tabBar).midX - expected) < slot * 0.65 }
        let icon = icons.min {
            abs($0.convert($0.bounds, to: tabBar).midX - expected)
                < abs($1.convert($1.bounds, to: tabBar).midX - expected)
        }
        switch (label, icon) {
        case let (label?, icon?):
            return label.convert(label.bounds, to: tabBar).union(icon.convert(icon.bounds, to: tabBar))
        case let (label?, nil):
            return label.convert(label.bounds, to: tabBar)
        case let (nil, icon?):
            return icon.convert(icon.bounds, to: tabBar)
        default:
            return nil
        }
    }

    private func tabIconViews() -> [UIImageView] {
        var icons: [UIImageView] = []
        func walk(_ view: UIView) {
            if let image = view as? UIImageView, image.bounds.width > 8, image.bounds.height > 8, image.alpha > 0.01 {
                icons.append(image)
            }
            view.subviews.forEach(walk)
        }
        walk(tabBar)
        return icons
    }

    /// 按标题找按钮。iOS 26 选中胶囊是单独一层，可能还停在上一项；优先用带图标、且横向位置靠近该格的那颗。
    private func tabButton(titled title: String, index: Int) -> UIView? {
        let candidates = tabTitleLabels(in: tabBar)
            .filter { $0.text?.trimmingCharacters(in: .whitespacesAndNewlines) == title }
            .map { tabButtonContainer(for: $0) }
            .filter { $0.bounds.width > 8 && $0.bounds.width < tabBar.bounds.width * 0.5 }
        let withIcon = candidates.filter(containsTabIcon)
        let pool = withIcon.isEmpty ? candidates : withIcon
        let expected = (CGFloat(index) + 0.5) / CGFloat(tabTitleOrder.count) * tabBar.bounds.width
        return pool.min { lhs, rhs in
            abs(lhs.convert(lhs.bounds, to: tabBar).midX - expected)
                < abs(rhs.convert(rhs.bounds, to: tabBar).midX - expected)
        }
    }

    /// 选中标题若还停在上一项，中心会偏离这一格，这时不用它。
    private func tabButton(_ button: UIView, isNearIndex index: Int) -> Bool {
        let width = tabBar.bounds.width / CGFloat(tabTitleOrder.count)
        let expected = (CGFloat(index) + 0.5) * width
        let midX = button.convert(button.bounds, to: tabBar).midX
        return abs(midX - expected) < width * 0.75
    }

    /// 按图标从左到右排。标题层还在移动时，格子以图标为准。
    private func tabIconButtons() -> [UIView] {
        var buttons: [UIView] = []
        func walk(_ view: UIView) {
            if view is UIImageView, view.bounds.width > 8, view.bounds.height > 8, view.alpha > 0.01 {
                let button = tabButtonContainer(forImage: view)
                if button.bounds.width < tabBar.bounds.width * 0.5,
                   !buttons.contains(where: { $0 === button }) {
                    buttons.append(button)
                }
            }
            view.subviews.forEach(walk)
        }
        walk(tabBar)
        return buttons.sorted {
            $0.convert($0.bounds, to: tabBar).midX < $1.convert($1.bounds, to: tabBar).midX
        }
    }

    private func tabButtonContainer(forImage image: UIView) -> UIView {
        var best: UIView = image
        var cursor: UIView = image
        while let parent = cursor.superview, parent !== tabBar {
            if parent.bounds.width >= tabBar.bounds.width * 0.5 { break }
            let iconCount = tabIconCount(in: parent)
            if iconCount > 1 { break }
            best = parent
            cursor = parent
        }
        return best
    }

    private func tabIconCount(in view: UIView) -> Int {
        var count = 0
        func walk(_ current: UIView) {
            if current is UIImageView, current.bounds.width > 8, current.bounds.height > 8 {
                count += 1
            }
            current.subviews.forEach(walk)
        }
        walk(view)
        return count
    }

    private func tabButtonContainer(for label: UILabel) -> UIView {
        var best: UIView = label
        var cursor: UIView = label
        while let parent = cursor.superview, parent !== tabBar {
            if parent.bounds.width >= tabBar.bounds.width * 0.5 { break }
            let titles = Set(
                tabTitleLabels(in: parent).compactMap {
                    $0.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            )
            if titles.count > 1 { break }
            best = parent
            cursor = parent
        }
        return best
    }

    private func containsTabIcon(_ view: UIView) -> Bool {
        if view is UIImageView, view.bounds.width > 4, view.bounds.height > 4 { return true }
        return view.subviews.contains(where: containsTabIcon)
    }

    private func tabTitleLabels(in view: UIView) -> [UILabel] {
        var result: [UILabel] = []
        func walk(_ current: UIView) {
            if let label = current as? UILabel,
               let text = label.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               tabTitles.contains(text),
               label.alpha > 0.01,
               label.bounds.width > 1,
               label.bounds.height > 1 {
                result.append(label)
            }
            current.subviews.forEach(walk)
        }
        walk(view)
        return result
    }

    /// 兼容旧调用：打开首页里的健康服务页签。
    static func selectServiceTab() {
        selectHomeShelf(.service)
    }

    /// `/messages`：切到消息 Tab 根页，不 push 新栈（避免 `hidesBottomBarWhenPushed` 藏掉底部栏）
    static func selectMessageTab() {
        let switchTab = {
            guard let tabBar = findInKeyWindow() else { return }
            if tabBar.presentedViewController != nil {
                tabBar.dismiss(animated: false)
            }
            if let nav = tabBar.viewControllers?[Tab.message] as? UINavigationController,
               nav.viewControllers.count > 1 {
                nav.popToRootViewController(animated: false)
            }
            tabBar.selectedIndex = Tab.message
        }
        if Thread.isMainThread {
            switchTab()
        } else {
            DispatchQueue.main.async(execute: switchTab)
        }
    }

    fileprivate static func findInKeyWindow() -> RootTabBarController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return find(in: window?.rootViewController)
    }

    private static func find(in root: UIViewController?) -> RootTabBarController? {
        if let tab = root as? RootTabBarController { return tab }
        if let nav = root as? UINavigationController {
            return find(in: nav.visibleViewController) ?? nav.viewControllers.compactMap { find(in: $0) }.first
        }
        if let tab = root as? UITabBarController {
            return find(in: tab.selectedViewController) ?? tab.viewControllers?.compactMap { find(in: $0) }.first
        }
        if let presented = root?.presentedViewController, let found = find(in: presented) {
            return found
        }
        return root?.children.compactMap { find(in: $0) }.first
    }
}

/// 完善资料提交成功后的新手引导。进度只留在这一次进程里。
enum NewUserGuide {
    private static var overlay: NewUserGuideOverlay?

    static func start() {
        guard overlay == nil, let tab = RootTabBarController.findInKeyWindow(), let window = tab.view.window else { return }
        if let nav = tab.viewControllers?[RootTabBarController.Tab.home] as? UINavigationController,
           nav.viewControllers.count > 1 {
            nav.popToRootViewController(animated: false)
        }
        tab.guideSelectTab(RootTabBarController.Tab.home)
        tab.guideHomeController()?.guideShow(shelf: .home)
        let view = NewUserGuideOverlay(tab: tab)
        view.frame = window.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(view)
        overlay = view
    }

    fileprivate static func finish() {
        overlay?.removeFromSuperview()
        overlay = nil
    }
}

private final class NewUserGuideOverlay: UIView {
    private enum Phase { case prompt, steps }

    private let copies = [
        "最常用的功能放在这一排。",
        "这里可以看健康服务，帮您把健康管起来。",
        "这里可以找健康产品，吃的用的都能找到。",
        "这里可以看健康知识，帮您把身体养好。",
        "这里可以记体征，帮您管好自己的健康。",
        "完善健康档案，给您定制专属健康服务。",
    ]

    private weak var tab: RootTabBarController?
    private let dimLayer = CAShapeLayer()
    private struct GuideHole {
        enum Shape {
            /// 内容区：圆角矩形，不描边
            case rounded
            /// 底栏：iOS 26 及以上椭圆，更早系统圆角矩形。都不描边。
            case tabItem
        }

        var rect: CGRect
        var shape: Shape
    }

    private var holeViews: [UIView] = []
    private var holes: [GuideHole] = []
    private var arrowTarget: CGRect = .zero
    private var phase: Phase = .prompt
    private var step = 1
    private var measureToken = 0

    private let promptCard = NewUserGuidePromptCard()
    private let card = UIView()
    private let stepLabel = UILabel()
    private let copyLabel = UILabel()
    private let nextButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
    private let arrow = GuideArrowView()
    private let toastLabel = UILabel()

    init(tab: RootTabBarController) {
        self.tab = tab
        super.init(frame: .zero)
        backgroundColor = .clear
        dimLayer.fillRule = .evenOdd
        dimLayer.fillColor = UIColor(red: 23 / 255, green: 32 / 255, blue: 51 / 255, alpha: 0.55).cgColor
        layer.addSublayer(dimLayer)

        promptCard.onEnable = { [weak self] in self?.enableSenior() }
        promptCard.onSkip = { [weak self] in self?.beginSteps(senior: false) }
        addSubview(promptCard)

        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.isHidden = true
        addSubview(arrow)
        addSubview(card)

        stepLabel.font = .fdFont(ofSize: 13, weight: .regular)
        stepLabel.textColor = .fdSubtext
        copyLabel.font = .fdFont(ofSize: 16, weight: .medium)
        copyLabel.textColor = .fdText
        copyLabel.numberOfLines = 0
        nextButton.backgroundColor = .fdPrimary
        nextButton.layer.cornerRadius = 22
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        nextButton.addTarget(self, action: #selector(tapNext), for: .touchUpInside)
        card.addSubview(stepLabel)
        card.addSubview(copyLabel)
        card.addSubview(nextButton)

        skipButton.setTitle("跳过", for: .normal)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .medium)
        skipButton.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        skipButton.layer.cornerRadius = 16
        skipButton.clipsToBounds = true
        skipButton.isHidden = true
        skipButton.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)
        addSubview(skipButton)

        toastLabel.font = .fdFont(ofSize: 14, weight: .medium)
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 8
        toastLabel.clipsToBounds = true
        toastLabel.isHidden = true
        addSubview(toastLabel)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remeasure),
            name: UIFont.seniorModeDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func layoutSubviews() {
        super.layoutSubviews()
        redrawDim()
        let top = safeAreaInsets.top + 8
        skipButton.frame = CGRect(x: bounds.width - 16 - 64, y: top, width: 64, height: 32)
        if phase == .prompt {
            let width = min(340, bounds.width - 32)
            let height: CGFloat = 196
            promptCard.frame = CGRect(x: (bounds.width - width) / 2, y: (bounds.height - height) / 2, width: width, height: height)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { true }

    private func enableSenior() {
        UIFont.isSeniorMode = true
        showToast("已开启长辈模式")
        beginSteps(senior: true)
    }

    private func beginSteps(senior: Bool) {
        if !senior { UIFont.isSeniorMode = false }
        phase = .steps
        step = 1
        promptCard.isHidden = true
        card.isHidden = false
        skipButton.isHidden = false
        tab?.guideSelectTab(RootTabBarController.Tab.home)
        tab?.guideHomeController()?.guideShow(shelf: .home)
        applyStepCopy()
        scheduleMeasure()
    }

    @objc private func tapNext() {
        guard let tab else { return }
        switch step {
        case 1:
            tab.guideSelectTab(RootTabBarController.Tab.home)
            tab.guideHomeController()?.guideShow(shelf: .service)
            step = 2
        case 2:
            tab.guideHomeController()?.guideShow(shelf: .mall)
            step = 3
        case 3:
            tab.guideHomeController()?.guideShow(shelf: .articles)
            step = 4
        case 4:
            tab.guideHomeController()?.guideShow(shelf: .home)
            tab.guideSelectTab(RootTabBarController.Tab.health)
            tab.guideHealthController()?.guideScrollToVitals()
            step = 5
        case 5:
            if UIFont.isSeniorMode {
                tab.guideHealthController()?.guideScrollToArchive()
            } else {
                tab.guideHealthController()?.guideScrollToArchiveCard()
            }
            step = 6
        default:
            let health = tab.guideHealthController()
            NewUserGuide.finish()
            health?.guideOpenArchiveEntry()
            return
        }
        applyStepCopy()
        scheduleMeasure()
    }

    @objc private func tapSkip() {
        tab?.guideSelectTab(RootTabBarController.Tab.home)
        tab?.guideHomeController()?.guideShow(shelf: .home)
        NewUserGuide.finish()
    }

    @objc private func remeasure() {
        guard phase == .steps else { return }
        scheduleMeasure()
    }

    private func applyStepCopy() {
        stepLabel.text = "第 \(step) 步，共 6 步"
        copyLabel.text = copies[step - 1]
        nextButton.setTitle(step == 6 ? "去完善" : "下一步", for: .normal)
    }

    private func scheduleMeasure() {
        measureToken += 1
        let token = measureToken
        let fire = { [weak self] in
            guard let self, token == self.measureToken, self.phase == .steps else { return }
            self.measure()
        }
        for delay in [0.0, 0.08, 0.25, 0.5, 0.85] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: fire)
        }
        tab?.transitionCoordinator?.animate(alongsideTransition: nil) { _ in
            fire()
        }
    }

    private func measure() {
        guard let tab else { return }
        var holes: [GuideHole] = []
        var focus = CGRect.zero
        func addContent(_ rect: CGRect) {
            let frame = rect.intersection(bounds).integral
            guard frame.width > 2, frame.height > 2 else { return }
            holes.append(GuideHole(rect: frame, shape: .rounded))
        }
        func addTab(_ rect: CGRect) {
            let frame = rect.intersection(bounds).integral
            guard frame.width > 2, frame.height > 2 else { return }
            holes.append(GuideHole(rect: frame, shape: .tabItem))
        }
        switch step {
        case 1:
            if let shelf = tab.guideHomeController()?.guideShelfButtonFrame(.home, in: self) {
                addContent(shelf.insetBy(dx: -6, dy: -4))
            }
            if let quick = tab.guideHomeController()?.guideQuickActionsFrame(in: self) {
                addContent(quick)
                focus = quick
            }
            if let home = tab.guideTabItemFrame(at: RootTabBarController.Tab.home, in: self) {
                addTab(home)
                if focus == .zero { focus = home }
            }
        case 2, 3, 4:
            let shelf: HomeShelf = step == 2 ? .service : (step == 3 ? .mall : .articles)
            if let button = tab.guideHomeController()?.guideShelfButtonFrame(shelf, in: self) {
                addContent(button.insetBy(dx: -6, dy: -4))
                focus = button
            }
            if let content = tab.guideHomeController()?.guideContentFrame(in: self) {
                addContent(content)
            }
            if let home = tab.guideTabItemFrame(at: RootTabBarController.Tab.home, in: self) {
                addTab(home)
            }
        case 5:
            let tabBarTop = tab.tabBar.convert(tab.tabBar.bounds, to: self).minY
            if let top = tab.guideHealthController()?.guideVitalsBodyTop(in: self), tabBarTop > top + 4 {
                let hole = CGRect(x: 0, y: top, width: bounds.width, height: tabBarTop - top)
                addContent(hole)
                focus = CGRect(x: bounds.midX - 8, y: top, width: 16, height: 12)
            }
            if let health = tab.guideTabItemFrame(at: RootTabBarController.Tab.health, in: self) {
                addTab(health)
                if focus == .zero { focus = health }
            }
        default:
            if UIFont.isSeniorMode {
                if let archive = tab.guideHealthController()?.guideArchiveItemFrame(in: self) {
                    addContent(archive.insetBy(dx: -6, dy: -4))
                    focus = archive
                }
            } else if let card = tab.guideHealthController()?.guideArchiveCardFrame(in: self) {
                addContent(card)
                focus = card
            }
            if let health = tab.guideTabItemFrame(at: RootTabBarController.Tab.health, in: self) {
                addTab(health)
                if focus == .zero { focus = health }
            }
        }
        self.holes = holes
        arrowTarget = focus
        placeCard()
        redrawDim()
        rebuildRings()
        bringSubviewToFront(arrow)
        bringSubviewToFront(card)
        bringSubviewToFront(skipButton)
        bringSubviewToFront(toastLabel)
    }

    private func placeCard() {
        let rounded = holes.filter { $0.shape == .rounded }
        let contentHole = rounded.max { $0.rect.height < $1.rect.height }
        let shelfHole = rounded.filter { $0.rect.height < 80 }.min { $0.rect.minY < $1.rect.minY }

        if (2...4).contains(step), let contentHole {
            let ceiling = max(safeAreaInsets.top + 8, (shelfHole?.rect.maxY ?? safeAreaInsets.top + 44) + 10)
            let floor = contentHole.rect.minY - 10
            let placed = cardThatFits(ceiling: ceiling, floor: floor, pinToFloor: false)
            let anchorX = shelfHole?.rect.midX ?? bounds.midX
            layoutCard(placed, arrowOnTop: true, anchorX: anchorX)
            return
        }

        if step == 5, let contentHole {
            let floor = contentHole.rect.minY - 14
            let minTop = safeAreaInsets.top + 48
            let placed = cardThatFits(ceiling: minTop, floor: floor, pinToFloor: true)
            layoutCard(placed, arrowOnTop: false, anchorX: contentHole.rect.midX)
            return
        }

        copyLabel.numberOfLines = 0
        copyLabel.adjustsFontSizeToFitWidth = false
        copyLabel.minimumScaleFactor = 1
        copyLabel.lineBreakMode = .byWordWrapping
        let cardWidth = min(300, bounds.width - 32)
        let textHeight = copyLabel.sizeThatFits(CGSize(width: cardWidth - 32, height: 80)).height
        let cardHeight = 16 + 18 + 8 + textHeight + 16 + 44 + 16
        let belowTop = arrowTarget.maxY + 18
        var top = belowTop
        var arrowOnTop = true
        if belowTop + cardHeight > bounds.height - 24 {
            top = max(safeAreaInsets.top + 52, arrowTarget.minY - 18 - cardHeight)
            arrowOnTop = false
        }
        let left = min(max(16, arrowTarget.midX - cardWidth / 2), bounds.width - 16 - cardWidth)
        layoutCard(
            CardPlacement(left: left, top: top, width: cardWidth, textHeight: textHeight, height: cardHeight, compact: false),
            arrowOnTop: arrowOnTop,
            anchorX: arrowTarget.midX
        )
    }

    private struct CardPlacement {
        var left: CGFloat
        var top: CGFloat
        var width: CGFloat
        var textHeight: CGFloat
        var height: CGFloat
        var compact: Bool
    }

    /// 说明卡放在 ceiling 和 floor 之间，底边不超过 floor。两行放不下时加宽，正文改成一行。
    private func cardThatFits(ceiling: CGFloat, floor: CGFloat, pinToFloor: Bool) -> CardPlacement {
        let gap = floor - ceiling
        var width = min(320, bounds.width - 32)
        var compact = false
        var textHeight = fittedTextHeight(width: width, compact: false)
        var height = cardHeight(textHeight: textHeight, compact: false)
        if height > gap {
            compact = true
            width = bounds.width - 24
            textHeight = fittedTextHeight(width: width, compact: true)
            height = cardHeight(textHeight: textHeight, compact: true)
        }
        var top = pinToFloor ? floor - height : ceiling + max(0, (gap - height) / 2)
        if top < ceiling, ceiling + height <= floor {
            top = ceiling
        }
        if top + height > floor {
            top = floor - height
        }
        let left = max(12, (bounds.width - width) / 2)
        return CardPlacement(left: left, top: top, width: width, textHeight: textHeight, height: height, compact: compact)
    }

    private func fittedTextHeight(width: CGFloat, compact: Bool) -> CGFloat {
        copyLabel.numberOfLines = compact ? 1 : 0
        copyLabel.lineBreakMode = compact ? .byTruncatingTail : .byWordWrapping
        copyLabel.adjustsFontSizeToFitWidth = compact
        copyLabel.minimumScaleFactor = compact ? 0.85 : 1
        if compact { return ceil(copyLabel.font.lineHeight) }
        return copyLabel.sizeThatFits(CGSize(width: width - 32, height: 80)).height
    }

    private func cardHeight(textHeight: CGFloat, compact: Bool) -> CGFloat {
        if compact { return 12 + 16 + 4 + textHeight + 8 + 36 + 12 }
        return 16 + 18 + 8 + textHeight + 16 + 44 + 16
    }

    private func layoutCard(_ placed: CardPlacement, arrowOnTop: Bool, anchorX: CGFloat) {
        let pad: CGFloat = placed.compact ? 14 : 16
        let buttonHeight: CGFloat = placed.compact ? 36 : 44
        card.frame = CGRect(x: placed.left, y: placed.top, width: placed.width, height: placed.height)
        stepLabel.frame = CGRect(x: pad, y: placed.compact ? 12 : 16, width: placed.width - pad * 2, height: placed.compact ? 16 : 18)
        let textY = stepLabel.frame.maxY + (placed.compact ? 4 : 8)
        copyLabel.frame = CGRect(x: pad, y: textY, width: placed.width - pad * 2, height: placed.textHeight)
        nextButton.layer.cornerRadius = buttonHeight / 2
        nextButton.frame = CGRect(x: pad, y: placed.height - (placed.compact ? 12 : 16) - buttonHeight, width: placed.width - pad * 2, height: buttonHeight)
        arrow.isHidden = arrowTarget == .zero
        arrow.pointsUp = arrowOnTop
        let arrowX = min(max(card.frame.minX + 24, anchorX - 7), card.frame.maxX - 38)
        arrow.frame = arrowOnTop
            ? CGRect(x: arrowX, y: card.frame.minY - 7, width: 14, height: 8)
            : CGRect(x: arrowX, y: card.frame.maxY - 1, width: 14, height: 8)
        bringSubviewToFront(arrow)
        bringSubviewToFront(card)
        bringSubviewToFront(skipButton)
        bringSubviewToFront(toastLabel)
    }

    private func redrawDim() {
        let path = UIBezierPath(rect: bounds)
        if phase == .steps {
            for hole in holes where hole.rect.width > 2 && hole.rect.height > 2 {
                path.append(holePath(hole))
            }
        }
        dimLayer.frame = bounds
        dimLayer.path = path.cgPath
    }

    private func holePath(_ hole: GuideHole) -> UIBezierPath {
        switch hole.shape {
        case .rounded:
            return UIBezierPath(roundedRect: hole.rect, cornerRadius: 12)
        case .tabItem:
            if #available(iOS 26.0, *) {
                let radius = min(hole.rect.width, hole.rect.height) / 2
                return UIBezierPath(roundedRect: hole.rect, cornerRadius: radius)
            }
            return UIBezierPath(roundedRect: hole.rect, cornerRadius: 12)
        }
    }

    private func rebuildRings() {
        holeViews.forEach { $0.removeFromSuperview() }
        holeViews.removeAll()
    }

    private func showToast(_ text: String) {
        toastLabel.text = text
        let width = toastLabel.sizeThatFits(CGSize(width: 240, height: 36)).width + 28
        toastLabel.frame = CGRect(x: (bounds.width - width) / 2, y: bounds.midY - 80, width: width, height: 36)
        toastLabel.isHidden = false
        bringSubviewToFront(toastLabel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.toastLabel.isHidden = true
        }
    }
}

private final class NewUserGuidePromptCard: UIView {
    var onEnable: (() -> Void)?
    var onSkip: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16

        let preview = UILabel()
        preview.numberOfLines = 0
        preview.textAlignment = .center
        preview.text = "富德联好健康\n首页  健康服务\n康养小屋  预约体检\n就医协助  激活兑换"
        preview.font = .fdFont(ofSize: 11, weight: .regular)
        preview.textColor = .fdText
        preview.backgroundColor = UIColor(hexString: "#F7F4F2")
        preview.layer.cornerRadius = 12
        preview.clipsToBounds = true

        let line1 = makeLine("字大、图标大")
        let line2 = makeLine("使用更简单")
        let enable = UIButton(type: .custom)
        enable.setTitle("开启长辈模式", for: .normal)
        enable.setTitleColor(.white, for: .normal)
        enable.titleLabel?.font = .fdFont(ofSize: 16, weight: .medium)
        enable.backgroundColor = .fdPrimary
        enable.layer.cornerRadius = 22
        enable.addTarget(self, action: #selector(tapEnable), for: .touchUpInside)
        let later = UIButton(type: .system)
        later.setTitle("暂不开启", for: .normal)
        later.setTitleColor(.fdSubtext, for: .normal)
        later.titleLabel?.font = .fdFont(ofSize: 14, weight: .regular)
        later.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)

        addSubview(preview)
        addSubview(line1)
        addSubview(line2)
        addSubview(enable)
        addSubview(later)
        preview.frame = CGRect(x: 16, y: 20, width: 132, height: 156)
        line1.frame = CGRect(x: 160, y: 28, width: 160, height: 22)
        line2.frame = CGRect(x: 160, y: 54, width: 160, height: 22)
        enable.frame = CGRect(x: 160, y: 92, width: 156, height: 44)
        later.frame = CGRect(x: 160, y: 144, width: 156, height: 28)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let enable = subviews.compactMap({ $0 as? UIButton }).first(where: { $0.currentTitle == "开启长辈模式" }) else { return }
        let contentWidth = bounds.width - 160 - 16
        enable.frame.size.width = contentWidth
        for view in subviews where view !== enable && view.frame.minX > 140 {
            view.frame.size.width = contentWidth
        }
    }

    private func makeLine(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = "●  " + text
        label.font = .fdFont(ofSize: 15, weight: .medium)
        label.textColor = .fdText
        return label
    }

    @objc private func tapEnable() { onEnable?() }
    @objc private func tapSkip() { onSkip?() }
}

/// 说明卡尖角。工程里没有引导箭头切图，按原型画白三角。
private final class GuideArrowView: UIView {
    var pointsUp = false {
        didSet { setNeedsLayout() }
    }

    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        shape.fillColor = UIColor.white.cgColor
        layer.addSublayer(shape)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        if pointsUp {
            path.move(to: CGPoint(x: bounds.midX, y: 0))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
        } else {
            path.move(to: CGPoint(x: bounds.minX, y: 0))
            path.addLine(to: CGPoint(x: bounds.maxX, y: 0))
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
        }
        path.close()
        shape.frame = bounds
        shape.path = path.cgPath
    }
}
