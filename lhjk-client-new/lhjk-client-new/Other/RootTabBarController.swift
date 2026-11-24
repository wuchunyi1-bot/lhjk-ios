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
        "最常用的功能放在这一排 !",
        "这里可以看健康服务，帮您把健康管起来",
        "这里可以找健康产品，吃的用的都能找到",
        "这里可以看健康知识，帮您把身体养好",
        "这里可以记体征，帮您管好自己的健康",
        "完善健康档案，给您定制专属健康服务",
    ]

    private weak var tab: RootTabBarController?
    private let dimLayer = CAShapeLayer()
    private let holeStroke = CAShapeLayer()
    private let connector = CAShapeLayer()
    private let connectorDot = UIView()
    private struct GuideHole {
        enum Shape {
            /// 内容区：圆角矩形
            case rounded
            /// 顶部页签：椭圆，只包住文字
            case capsule
            /// 底栏：iOS 26 及以上椭圆，更早系统圆角矩形。都不描边。
            case tabItem
        }

        var rect: CGRect
        var shape: Shape
        /// 孔的下沿做一段模糊，设计稿里内容区底部是虚化的。
        var fadesBottom = false
    }

    private var holeViews: [UIView] = []
    private var fadeViews: [UIView] = []
    private var holes: [GuideHole] = []
    private var arrowTarget: CGRect = .zero
    private var phase: Phase = .prompt
    private var step = 1
    private var measureToken = 0

    private let promptCard = NewUserGuidePromptCard()
    private let card = UIView()
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
        holeStroke.fillColor = UIColor.clear.cgColor
        holeStroke.strokeColor = UIColor.fdPrimary.cgColor
        holeStroke.lineWidth = 1.5
        layer.addSublayer(holeStroke)
        connector.fillColor = UIColor.clear.cgColor
        connector.strokeColor = UIColor.fdPrimary.cgColor
        connector.lineWidth = 1.5
        connector.lineCap = .round
        layer.addSublayer(connector)
        connectorDot.backgroundColor = .fdPrimary
        connectorDot.isHidden = true
        connectorDot.isUserInteractionEnabled = false

        promptCard.onEnable = { [weak self] in self?.enableSenior() }
        promptCard.onSkip = { [weak self] in self?.beginSteps(senior: false) }
        addSubview(promptCard)

        card.backgroundColor = UIColor(hexString: "#FFEAE3")
        card.layer.cornerRadius = 8
        card.isHidden = true
        addSubview(connectorDot)
        addSubview(arrow)
        addSubview(card)

        copyLabel.font = .fdFont(ofSize: 14, weight: .medium)
        copyLabel.textColor = .fdPrimary
        copyLabel.numberOfLines = 2
        nextButton.backgroundColor = .fdPrimary
        nextButton.layer.cornerRadius = 13
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        nextButton.addTarget(self, action: #selector(tapNext), for: .touchUpInside)
        card.addSubview(copyLabel)
        card.addSubview(nextButton)

        skipButton.setTitle("跳过", for: .normal)
        skipButton.setTitleColor(.fdPrimary, for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        skipButton.backgroundColor = .clear
        skipButton.layer.cornerRadius = 13
        skipButton.layer.borderWidth = 0.5
        skipButton.layer.borderColor = UIColor.fdPrimary.cgColor
        skipButton.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)
        card.addSubview(skipButton)

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
        if phase == .prompt {
            let width = min(319, bounds.width - 32)
            let height = width * (297.0 / 319.0)
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
        copyLabel.text = copies[step - 1]
        nextButton.setTitle(step == 6 ? "去完善（6/6）" : "下一步（\(step)/6）", for: .normal)
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
        func addContent(_ rect: CGRect, fadesBottom: Bool = false) {
            let frame = rect.intersection(bounds).integral
            guard frame.width > 2, frame.height > 2 else { return }
            holes.append(GuideHole(rect: frame, shape: .rounded, fadesBottom: fadesBottom))
        }
        func addCapsule(_ rect: CGRect) {
            let frame = rect.intersection(bounds).integral
            guard frame.width > 2, frame.height > 2 else { return }
            holes.append(GuideHole(rect: frame, shape: .capsule))
        }
        func addTab(_ rect: CGRect) {
            let frame = rect.intersection(bounds).integral
            guard frame.width > 2, frame.height > 2 else { return }
            holes.append(GuideHole(rect: frame, shape: .tabItem))
        }
        switch step {
        case 1:
            if let shelf = tab.guideHomeController()?.guideShelfButtonFrame(.home, in: self) {
                addCapsule(shelf)
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
                addCapsule(button)
                focus = button
            }
            if var content = tab.guideHomeController()?.guideContentFrame(in: self) {
                let side: CGFloat = 8
                if content.width > bounds.width - side * 2 {
                    content.origin.x = side
                    content.size.width = bounds.width - side * 2
                }
                let tabBarTop = tab.tabBar.convert(tab.tabBar.bounds, to: self).minY
                if content.maxY > tabBarTop - 8 {
                    content.size.height = max(40, tabBarTop - 8 - content.minY)
                }
                addContent(content, fadesBottom: true)
            }
            if let home = tab.guideTabItemFrame(at: RootTabBarController.Tab.home, in: self) {
                addTab(home)
            }
        case 5:
            let tabBarTop = tab.tabBar.convert(tab.tabBar.bounds, to: self).minY
            if var card = tab.guideHealthController()?.guideVitalsCardFrame(in: self) {
                if card.maxY > tabBarTop - 8 {
                    card.size.height = max(40, tabBarTop - 8 - card.minY)
                }
                addContent(card, fadesBottom: true)
                focus = card
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
        rebuildFades()
        bringSubviewToFront(connectorDot)
        bringSubviewToFront(arrow)
        bringSubviewToFront(card)
        bringSubviewToFront(toastLabel)
    }

    private func placeCard() {
        let rounded = holes.filter { $0.shape == .rounded }
        let contentHole = rounded.max { $0.rect.height < $1.rect.height }
        let shelfHole = holes.filter { $0.shape == .capsule }.min { $0.rect.minX < $1.rect.minX }

        if (2...4).contains(step), let contentHole {
            let ceiling = max(safeAreaInsets.top + 8, (shelfHole?.rect.maxY ?? safeAreaInsets.top + 44) + 16)
            let floor = contentHole.rect.minY - 14
            let anchorX = shelfHole?.rect.midX ?? bounds.midX
            let placed = cardThatFits(ceiling: ceiling, floor: floor, pinToFloor: false, anchorX: anchorX)
            layoutCard(placed, arrowOnTop: true, anchorX: anchorX, dotY: shelfHole?.rect.maxY ?? contentHole.rect.minY)
            return
        }

        if step == 5 || step == 6, let contentHole {
            let floor = contentHole.rect.minY - 16
            let minTop = safeAreaInsets.top + (step == 5 ? 48 : 8)
            let placed = cardThatFits(ceiling: minTop, floor: floor, pinToFloor: true, anchorX: contentHole.rect.midX)
            layoutCard(placed, arrowOnTop: false, anchorX: contentHole.rect.midX, dotY: contentHole.rect.minY)
            return
        }

        let metrics = cardMetrics(maxWidth: bounds.width - 24)
        let belowTop = arrowTarget.maxY + 18
        var top = belowTop
        var arrowOnTop = true
        var dotY = arrowTarget.maxY
        if belowTop + metrics.height > bounds.height - 24 {
            top = max(safeAreaInsets.top + 52, arrowTarget.minY - 18 - metrics.height)
            arrowOnTop = false
            dotY = arrowTarget.minY
        }
        let left = min(max(12, arrowTarget.midX - metrics.width / 2), bounds.width - 12 - metrics.width)
        layoutCard(
            CardPlacement(left: left, top: top, width: metrics.width, textHeight: metrics.textHeight, height: metrics.height, nextWidth: metrics.nextWidth, skipWidth: metrics.skipWidth),
            arrowOnTop: arrowOnTop,
            anchorX: arrowTarget.midX,
            dotY: dotY
        )
    }

    private struct CardPlacement {
        var left: CGFloat
        var top: CGFloat
        var width: CGFloat
        var textHeight: CGFloat
        var height: CGFloat
        var nextWidth: CGFloat
        var skipWidth: CGFloat
    }

    /// 说明卡放在 ceiling 和 floor 之间。水平位置跟着锚点，贴边时整张卡收回屏幕内。
    private func cardThatFits(ceiling: CGFloat, floor: CGFloat, pinToFloor: Bool, anchorX: CGFloat) -> CardPlacement {
        let gap = max(0, floor - ceiling)
        var metrics = cardMetrics(maxWidth: min(bounds.width - 24, max(174, gap > 0 ? bounds.width - 24 : 174)))
        if metrics.height > gap, gap > 0 {
            metrics = cardMetrics(maxWidth: bounds.width - 24)
        }
        var top = pinToFloor ? floor - metrics.height : ceiling
        if top < ceiling, ceiling + metrics.height <= floor {
            top = ceiling
        }
        if top + metrics.height > floor {
            top = floor - metrics.height
        }
        let left = min(max(12, anchorX - metrics.width / 2), bounds.width - 12 - metrics.width)
        return CardPlacement(
            left: left,
            top: top,
            width: metrics.width,
            textHeight: metrics.textHeight,
            height: metrics.height,
            nextWidth: metrics.nextWidth,
            skipWidth: metrics.skipWidth
        )
    }

    private func cardMetrics(maxWidth: CGFloat) -> (width: CGFloat, textHeight: CGFloat, height: CGFloat, nextWidth: CGFloat, skipWidth: CGFloat) {
        copyLabel.font = .fdFont(ofSize: 14, weight: .medium)
        copyLabel.numberOfLines = 2
        copyLabel.lineBreakMode = .byTruncatingTail
        nextButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        skipButton.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        let nextText = nextButton.titleLabel?.sizeThatFits(CGSize(width: 160, height: 26)).width ?? 76
        let skipText = skipButton.titleLabel?.sizeThatFits(CGSize(width: 80, height: 26)).width ?? 24
        let nextWidth = max(86, ceil(nextText) + 16)
        let skipWidth = max(56, ceil(skipText) + 32)
        let buttons = nextWidth + 12 + skipWidth
        let textLimit = max(80, maxWidth - 20)
        let textSize = copyLabel.sizeThatFits(CGSize(width: textLimit, height: 48))
        let width = min(maxWidth, max(ceil(textSize.width), buttons) + 20)
        let fitted = copyLabel.sizeThatFits(CGSize(width: width - 20, height: 48))
        let textHeight = ceil(fitted.height)
        let height = 10 + textHeight + 6 + 26 + 10
        return (width, textHeight, height, nextWidth, skipWidth)
    }

    private func layoutCard(_ placed: CardPlacement, arrowOnTop: Bool, anchorX: CGFloat, dotY: CGFloat) {
        card.frame = CGRect(x: placed.left, y: placed.top, width: placed.width, height: placed.height)
        copyLabel.frame = CGRect(x: 10, y: 10, width: placed.width - 20, height: placed.textHeight)
        let buttonY = placed.height - 10 - 26
        nextButton.layer.cornerRadius = 13
        skipButton.layer.cornerRadius = 13
        nextButton.frame = CGRect(x: 10, y: buttonY, width: placed.nextWidth, height: 26)
        skipButton.frame = CGRect(x: nextButton.frame.maxX + 12, y: buttonY, width: placed.skipWidth, height: 26)
        let showArrow = arrowTarget != .zero
        arrow.isHidden = !showArrow
        connectorDot.isHidden = !showArrow
        arrow.pointsUp = arrowOnTop
        let arrowX = min(max(card.frame.minX + 18, anchorX - 8), card.frame.maxX - 34)
        arrow.frame = arrowOnTop
            ? CGRect(x: arrowX, y: card.frame.minY - 7, width: 16, height: 8)
            : CGRect(x: arrowX, y: card.frame.maxY - 1, width: 16, height: 8)
        guard showArrow else {
            connector.path = nil
            return
        }
        let dotSide: CGFloat = 8
        connectorDot.layer.cornerRadius = dotSide / 2
        connectorDot.frame = CGRect(x: anchorX - dotSide / 2, y: dotY - dotSide / 2, width: dotSide, height: dotSide)
        let line = UIBezierPath()
        if arrowOnTop {
            line.move(to: CGPoint(x: anchorX, y: connectorDot.frame.maxY))
            line.addLine(to: CGPoint(x: arrow.frame.midX, y: arrow.frame.minY))
        } else {
            line.move(to: CGPoint(x: arrow.frame.midX, y: arrow.frame.maxY))
            line.addLine(to: CGPoint(x: anchorX, y: connectorDot.frame.minY))
        }
        connector.frame = bounds
        connector.path = line.cgPath
        bringSubviewToFront(connectorDot)
        bringSubviewToFront(arrow)
        bringSubviewToFront(card)
        bringSubviewToFront(toastLabel)
    }

    private func redrawDim() {
        let path = UIBezierPath(rect: bounds)
        let stroke = UIBezierPath()
        if phase == .steps {
            for hole in holes where hole.rect.width > 2 && hole.rect.height > 2 {
                let holePath = holePath(hole)
                path.append(holePath)
                if hole.shape == .rounded, hole.rect.height >= 60 {
                    stroke.append(holePath)
                }
            }
        } else {
            connector.path = nil
            connectorDot.isHidden = true
        }
        dimLayer.frame = bounds
        dimLayer.path = path.cgPath
        holeStroke.frame = bounds
        holeStroke.path = stroke.cgPath
    }

    private func holePath(_ hole: GuideHole) -> UIBezierPath {
        switch hole.shape {
        case .rounded:
            return UIBezierPath(roundedRect: hole.rect, cornerRadius: 16)
        case .capsule:
            let radius = min(hole.rect.width, hole.rect.height) / 2
            return UIBezierPath(roundedRect: hole.rect, cornerRadius: radius)
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

    /// 内容孔下沿虚化。模糊从透明过渡到实，只盖住孔内靠下的一段。
    private func rebuildFades() {
        fadeViews.forEach { $0.removeFromSuperview() }
        fadeViews.removeAll()
        guard phase == .steps else { return }
        for hole in holes where hole.fadesBottom && hole.rect.height > 80 {
            let blurHeight = min(96, max(64, hole.rect.height * 0.28))
            let clip = UIView(frame: hole.rect.insetBy(dx: 2, dy: 2))
            clip.isUserInteractionEnabled = false
            clip.backgroundColor = .clear
            clip.layer.cornerRadius = 14
            clip.clipsToBounds = true

            let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
            effect.isUserInteractionEnabled = false
            effect.frame = CGRect(
                x: 0,
                y: clip.bounds.height - blurHeight,
                width: clip.bounds.width,
                height: blurHeight
            )
            let mask = CAGradientLayer()
            mask.frame = effect.bounds
            mask.colors = [
                UIColor.clear.cgColor,
                UIColor.white.withAlphaComponent(0.95).cgColor,
            ]
            mask.locations = [0, 0.72]
            mask.startPoint = CGPoint(x: 0.5, y: 0)
            mask.endPoint = CGPoint(x: 0.5, y: 1)
            effect.layer.mask = mask
            clip.addSubview(effect)
            insertSubview(clip, at: 0)
            fadeViews.append(clip)
        }
        bringSubviewToFront(connectorDot)
        bringSubviewToFront(arrow)
        bringSubviewToFront(card)
        bringSubviewToFront(toastLabel)
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

    private let panel = UIView()
    private let gradient = CAGradientLayer()
    private let illustration = UIImageView(image: UIImage(named: "guide_logo"))
    private let line1 = UILabel()
    private let line2 = UILabel()
    private let starLeft = GuideSparkleView()
    private let starRight = GuideSparkleView()
    private let later = UIButton(type: .custom)
    private let enable = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        panel.layer.cornerRadius = 16
        panel.clipsToBounds = true
        gradient.colors = [
            UIColor(hexString: "#FFF9EB").cgColor,
            UIColor.white.cgColor,
        ]
        gradient.locations = [0, 0.459]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        panel.layer.addSublayer(gradient)

        illustration.contentMode = .scaleAspectFit

        let brown = UIColor(hexString: "#9E3A09")
        for label in [line1, line2] {
            label.font = .fdFont(ofSize: 16, weight: .medium)
            label.textColor = brown
            label.textAlignment = .center
        }
        line1.text = "字大、图标大"
        line2.text = "使用更简单"

        later.setTitle("暂不开启", for: .normal)
        later.setTitleColor(.fdPrimary, for: .normal)
        later.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        later.layer.cornerRadius = 20
        later.layer.borderWidth = 1
        later.layer.borderColor = UIColor.fdPrimary.cgColor
        later.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)

        enable.setTitle("开启长辈模式", for: .normal)
        enable.setTitleColor(.white, for: .normal)
        enable.titleLabel?.font = .fdFont(ofSize: 14, weight: .medium)
        enable.backgroundColor = .fdPrimary
        enable.layer.cornerRadius = 20
        enable.addTarget(self, action: #selector(tapEnable), for: .touchUpInside)

        addSubview(panel)
        addSubview(illustration)
        addSubview(starLeft)
        addSubview(starRight)
        addSubview(line1)
        addSubview(line2)
        addSubview(later)
        addSubview(enable)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = bounds.width / 319
        let imageSide = 176 * scale
        illustration.frame = CGRect(x: (bounds.width - imageSide) / 2, y: 0, width: imageSide, height: imageSide)
        let panelTop = 56 * scale
        panel.frame = CGRect(x: 0, y: panelTop, width: bounds.width, height: 241 * scale)
        panel.layer.cornerRadius = 16 * scale
        gradient.frame = panel.bounds

        line1.font = .fdFont(ofSize: 16 * scale, weight: .medium)
        line2.font = .fdFont(ofSize: 16 * scale, weight: .medium)
        let textWidth = line1.sizeThatFits(CGSize(width: bounds.width, height: 24 * scale)).width
        let lineHeight = 24 * scale
        let lineTop = panelTop + 107 * scale
        line1.frame = CGRect(x: (bounds.width - textWidth) / 2, y: lineTop, width: textWidth, height: lineHeight)
        line2.frame = CGRect(x: 16 * scale, y: line1.frame.maxY + scale, width: bounds.width - 32 * scale, height: lineHeight)
        let starSide = 16 * scale
        starLeft.frame = CGRect(x: line1.frame.minX - 4 * scale - starSide, y: lineTop + 4 * scale, width: starSide, height: starSide)
        starRight.frame = CGRect(x: line1.frame.maxX + 4 * scale, y: starLeft.frame.minY, width: starSide, height: starSide)

        let buttonTop = panelTop + 181 * scale
        let inset = 16 * scale
        let gap = 7 * scale
        let buttonWidth = (bounds.width - inset * 2 - gap) / 2
        let buttonHeight = 40 * scale
        later.frame = CGRect(x: inset, y: buttonTop, width: buttonWidth, height: buttonHeight)
        enable.frame = CGRect(x: later.frame.maxX + gap, y: buttonTop, width: buttonWidth, height: buttonHeight)
        later.layer.cornerRadius = buttonHeight / 2
        enable.layer.cornerRadius = buttonHeight / 2
        later.titleLabel?.font = .fdFont(ofSize: 14 * scale, weight: .medium)
        enable.titleLabel?.font = .fdFont(ofSize: 14 * scale, weight: .medium)
    }

    @objc private func tapEnable() { onEnable?() }
    @objc private func tapSkip() { onSkip?() }
}

private final class GuideSparkleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outer = min(bounds.width, bounds.height) / 2
        let inner = outer * 0.38
        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.close()
        UIColor.fdPrimary.setFill()
        path.fill()
    }
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
        shape.fillColor = UIColor(hexString: "#FFEAE3").cgColor
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
