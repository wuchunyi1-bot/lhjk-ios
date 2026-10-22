import UIKit
import Combine

/// 根 TabBar 控制器 — 首页、健康、消息、我的
final class RootTabBarController: UITabBarController {

    private var messageNav: BaseNavigationController?
    private var cancellables = Set<AnyCancellable>()
    private var didScheduleHubPreload = false
    private let tabTitles: Set<String> = ["首页", "健康", "消息", "我的"]

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
    }

    func guideTabItemFrame(at index: Int, in target: UIView) -> CGRect? {
        view.layoutIfNeeded()
        tabBar.layoutIfNeeded()
        let buttons = tabBar.subviews
            .filter { String(describing: type(of: $0)).contains("TabBarButton") }
            .sorted { $0.frame.minX < $1.frame.minX }
        if buttons.indices.contains(index) {
            return buttons[index].convert(buttons[index].bounds, to: target)
        }
        let count = max(viewControllers?.count ?? 1, 1)
        let width = tabBar.bounds.width / CGFloat(count)
        let height = min(49, tabBar.bounds.height)
        let local = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
        return tabBar.convert(local, to: target)
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
    private var holeViews: [UIView] = []
    private var holes: [CGRect] = []
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
    private let arrow = UIView()
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
        skipButton.setTitleColor(.fdText, for: .normal)
        skipButton.titleLabel?.font = .fdFont(ofSize: 15, weight: .medium)
        skipButton.backgroundColor = .white
        skipButton.layer.cornerRadius = 16
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
            tab.guideSelectTab(RootTabBarController.Tab.health)
            tab.guideHealthController()?.guideScrollToVitals()
            step = 5
        case 5:
            tab.guideHealthController()?.guideScrollToArchive()
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
        for delay in [0.0, 0.08, 0.2, 0.45] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, token == self.measureToken, self.phase == .steps else { return }
                self.measure()
            }
        }
    }

    private func measure() {
        guard let tab else { return }
        var rects: [CGRect] = []
        var focus = CGRect.zero
        switch step {
        case 1:
            if let quick = tab.guideHomeController()?.guideQuickActionsFrame(in: self) {
                rects.append(quick)
                focus = quick
            }
            if let home = tab.guideTabItemFrame(at: RootTabBarController.Tab.home, in: self) {
                rects.append(home)
                if focus == .zero { focus = home }
            }
        case 2, 3, 4:
            let shelf: HomeShelf = step == 2 ? .service : (step == 3 ? .mall : .articles)
            if let button = tab.guideHomeController()?.guideShelfButtonFrame(shelf, in: self) {
                rects.append(button.insetBy(dx: -6, dy: -4))
                focus = button
            }
            if let content = tab.guideHomeController()?.guideContentFrame(in: self) {
                rects.append(content)
            }
            if let home = tab.guideTabItemFrame(at: RootTabBarController.Tab.home, in: self) {
                rects.append(home)
            }
        case 5:
            if let vitals = tab.guideHealthController()?.guideVitalsFrame(in: self) {
                rects.append(vitals)
                focus = vitals
            }
            if let health = tab.guideTabItemFrame(at: RootTabBarController.Tab.health, in: self) {
                rects.append(health)
                if focus == .zero { focus = health }
            }
        default:
            if let archive = tab.guideHealthController()?.guideArchiveItemFrame(in: self) {
                rects.append(archive.insetBy(dx: -6, dy: -4))
                focus = archive
            }
            if let health = tab.guideTabItemFrame(at: RootTabBarController.Tab.health, in: self) {
                rects.append(health)
                if focus == .zero { focus = health }
            }
        }
        holes = rects.map { $0.intersection(bounds).integral }
        arrowTarget = focus
        placeCard()
        redrawDim()
        rebuildRings()
    }

    private func placeCard() {
        let cardWidth = min(300, bounds.width - 32)
        let textHeight = copyLabel.sizeThatFits(CGSize(width: cardWidth - 32, height: 80)).height
        let cardHeight = 16 + 18 + 8 + textHeight + 16 + 44 + 16
        let belowTop = arrowTarget.maxY + 18
        let aboveTop = arrowTarget.minY - 18 - cardHeight
        var top = belowTop
        var below = true
        if (2...4).contains(step) || belowTop + cardHeight > bounds.height - 24 {
            top = max(safeAreaInsets.top + 52, aboveTop)
            below = false
        }
        let tabTop = holes.map(\.minY).max() ?? bounds.height
        if top + cardHeight > tabTop - 8, tabTop > cardHeight + 80 {
            top = max(safeAreaInsets.top + 52, tabTop - 8 - cardHeight)
            below = top > arrowTarget.minY
        }
        let left = min(max(16, arrowTarget.midX - cardWidth / 2), bounds.width - 16 - cardWidth)
        card.frame = CGRect(x: left, y: top, width: cardWidth, height: cardHeight)
        stepLabel.frame = CGRect(x: 16, y: 16, width: cardWidth - 32, height: 18)
        copyLabel.frame = CGRect(x: 16, y: 42, width: cardWidth - 32, height: textHeight)
        nextButton.frame = CGRect(x: 16, y: cardHeight - 16 - 44, width: cardWidth - 32, height: 44)
        arrow.isHidden = arrowTarget == .zero
        arrow.backgroundColor = .white
        let arrowX = min(max(card.frame.minX + 24, arrowTarget.midX - 8), card.frame.maxX - 40)
        arrow.frame = below
            ? CGRect(x: arrowX, y: card.frame.minY - 8, width: 16, height: 10)
            : CGRect(x: arrowX, y: card.frame.maxY - 2, width: 16, height: 10)
        bringSubviewToFront(card)
        bringSubviewToFront(skipButton)
        bringSubviewToFront(toastLabel)
    }

    private func redrawDim() {
        let path = UIBezierPath(rect: bounds)
        if phase == .steps {
            for hole in holes where hole.width > 2 && hole.height > 2 {
                path.append(UIBezierPath(roundedRect: hole, cornerRadius: 12))
            }
        }
        dimLayer.frame = bounds
        dimLayer.path = path.cgPath
    }

    private func rebuildRings() {
        holeViews.forEach { $0.removeFromSuperview() }
        holeViews.removeAll()
        guard phase == .steps else { return }
        for hole in holes where hole.width > 2 {
            let ring = UIView(frame: hole)
            ring.isUserInteractionEnabled = false
            ring.layer.cornerRadius = 12
            ring.layer.borderWidth = 2
            ring.layer.borderColor = UIColor.fdPrimary.cgColor
            ring.backgroundColor = .clear
            addSubview(ring)
            holeViews.append(ring)
        }
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
