import UIKit
import SnapKit

/// 全部订单列表 — 容器 VC
///
/// 管理横向滚动 Tab + 8 个 OrderTabViewController（对齐 funde OrderListView）。
final class OrderListViewController: BaseViewController {

    // MARK: - Tab 定义（funde 顺序）

    private struct TabItem {
        let title: String
        /// 单状态筛选；与 statusList 互斥
        let status: Int?
        /// 多状态筛选（逗号分隔 status）
        let statusList: String?
        /// 路由 / query key
        let routeKey: String
        let emptyText: String
    }

    private let tabs: [TabItem] = [
        TabItem(title: "全部", status: nil, statusList: nil, routeKey: "all", emptyText: "暂无订单"),
        TabItem(title: "待支付", status: 1, statusList: nil, routeKey: "pending_payment", emptyText: "暂无订单"),
        TabItem(title: "待发货", status: 2, statusList: nil, routeKey: "paid_pending_delivery", emptyText: "暂无订单"),
        TabItem(title: "待收货", status: 3, statusList: nil, routeKey: "pending_receipt", emptyText: "暂无待收货订单"),
        TabItem(title: "使用中", status: 4, statusList: nil, routeKey: "in_progress", emptyText: "暂无使用中订单"),
        TabItem(title: "已逾期", status: 7, statusList: nil, routeKey: "overdue", emptyText: "暂无已逾期订单"),
        TabItem(title: "退款/售后", status: 6, statusList: nil, routeKey: "after_sale", emptyText: "暂无退款/售后记录"),
        TabItem(title: "已完成", status: 5, statusList: nil, routeKey: "completed", emptyText: "暂无已完成订单"),
    ]

    // MARK: - State

    private var selectedTabIndex = 0
    private var childVCs: [OrderTabViewController] = []
    private var needsInitialScroll = false
    private var listRefreshObserver: NSObjectProtocol?

    private let initialTab: String?

    init(initialTab: String? = nil) {
        self.initialTab = initialTab
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .fdBg
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(OrderTabCell.self, forCellWithReuseIdentifier: OrderTabCell.reuseID)
        return cv
    }()

    private let containerView = UIView()

    // MARK: - Lifecycle

    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的订单"

        // funde query keys + 兼容旧 key
        let tabMapping: [String: String] = [
            "all": "all",
            "pending_payment": "pending_payment",
            "paid_pending_delivery": "paid_pending_delivery",
            "pending_ship": "paid_pending_delivery",
            "pending_receipt": "pending_receipt",
            "pending_receive": "pending_receipt",
            "pending_receipt_in_progress": "pending_receipt",
            "in_progress": "in_progress",
            "overdue": "overdue",
            "after_sale": "after_sale",
            "refund": "after_sale",
            "completed": "completed",
        ]
        if let tab = initialTab,
           let key = tabMapping[tab],
           let idx = tabs.firstIndex(where: { $0.routeKey == key }) {
            selectedTabIndex = idx
            needsInitialScroll = true
        }

        buildChildVCs()
        listRefreshObserver = NotificationCenter.default.addObserver(
            forName: .orderListNeedsRefresh,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAllTabs()
        }
    }

    deinit {
        if let listRefreshObserver {
            NotificationCenter.default.removeObserver(listRefreshObserver)
        }
    }

    private func refreshAllTabs() {
        childVCs.forEach { $0.refresh() }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        let tabContainer = UIView()
        tabContainer.backgroundColor = .fdBg
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }

        tabContainer.addSubview(tabCollectionView)
        tabCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if needsInitialScroll {
            needsInitialScroll = false
            tabCollectionView.scrollToItem(
                at: IndexPath(item: selectedTabIndex, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
            tabCollectionView.layoutIfNeeded()
        }

        if currentChildVC == nil {
            showChildVC(at: selectedTabIndex)
        }
    }

    // MARK: - Child VC Management

    private func buildChildVCs() {
        childVCs = tabs.map { tab in
            OrderTabViewController(
                status: tab.status,
                statusList: tab.statusList,
                emptyText: tab.emptyText
            )
        }
    }

    private var currentChildVC: OrderTabViewController?

    private func showChildVC(at index: Int) {
        guard index >= 0, index < childVCs.count else { return }
        let isVisible = isViewLoaded && view.window != nil

        if let old = currentChildVC, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            vc.didMove(toParent: nil)
        }

        let child = childVCs[index]
        child.willMove(toParent: self)
        addChild(child)
        containerView.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        child.didMove(toParent: self)
        currentChildVC = child

        if isVisible {
            child.beginAppearanceTransition(true, animated: false)
            child.endAppearanceTransition()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentChildVC?.beginAppearanceTransition(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentChildVC?.beginAppearanceTransition(false, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        currentChildVC?.endAppearanceTransition()
    }

    private func selectTab(at index: Int) {
        guard index != selectedTabIndex else { return }
        selectedTabIndex = index
        tabCollectionView.reloadData()
        tabCollectionView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        showChildVC(at: index)
    }
}

// MARK: - UICollectionViewDataSource

extension OrderListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderTabCell.reuseID,
            for: indexPath
        ) as? OrderTabCell else {
            return UICollectionViewCell()
        }
        cell.configure(title: tabs[indexPath.item].title, isSelected: indexPath.item == selectedTabIndex)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension OrderListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectTab(at: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension OrderListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = tabs[indexPath.item].title
        let width = title.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.fdCaptionSemibold],
            context: nil
        ).width + 16
        return CGSize(width: ceil(width), height: 30)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}
