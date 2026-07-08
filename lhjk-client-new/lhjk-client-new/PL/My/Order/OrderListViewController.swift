import UIKit
import SnapKit

/// 全部订单列表 — 容器 VC
///
/// 管理横向滚动 Tab 栏 + 10 个 OrderTabViewController 子 VC。
/// 每个子 VC 拥有独立的 TableView 和数据缓存，仅首次加载时请求 API。
final class OrderListViewController: BaseViewController {

    // MARK: - Tab 定义

    private struct TabItem {
        let title: String
        let status: Int?       // nil = 全部
    }

    private let tabs: [TabItem] = [
        TabItem(title: "全部",       status: nil),
        TabItem(title: "待付款",     status: 1),
        TabItem(title: "待发货",     status: 2),
        TabItem(title: "待收货",     status: 3),
        TabItem(title: "使用中",     status: 4),
        TabItem(title: "已完成",     status: 5),
        TabItem(title: "退款/售后",  status: 6),
        TabItem(title: "已逾期",     status: 7),
        TabItem(title: "已取消",     status: 8),
        TabItem(title: "退款审核中", status: 9),
    ]

    // MARK: - State

    private var selectedTabIndex = 0
    private var childVCs: [OrderTabViewController] = []
    private var needsInitialScroll = false

    private let initialTab: String?

    init(initialTab: String? = nil) {
        self.initialTab = initialTab
        super.init(nibName: nil, bundle: nil)
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
        cv.register(OrderTabCell.self, forCellWithReuseIdentifier: OrderTabCell.reuseId)
        return cv
    }()

    private let containerView = UIView()

    // MARK: - Lifecycle

    // 禁止自动转发，手动管理子 VC 生命周期
    override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的订单"

        // 解析初始 Tab
        let tabMapping: [String: Int] = [
            "pending_payment": 1, "pending_ship": 2, "pending_receive": 3,
            "in_progress": 4, "completed": 5, "refund": 6,
            "overdue": 7, "cancelled": 8, "refund_review": 9,
        ]
        if let tab = initialTab, let idx = tabMapping[tab] {
            selectedTabIndex = idx
            needsInitialScroll = true
        }

        buildChildVCs()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        // Tab 栏容器
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

        // 子 VC 容器
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // 首次 layout 后滚动到初始 Tab
        if needsInitialScroll {
            needsInitialScroll = false
            tabCollectionView.scrollToItem(at: IndexPath(item: selectedTabIndex, section: 0), at: .centeredHorizontally, animated: false)
            tabCollectionView.layoutIfNeeded()
        }

        // 确保当前选中的子 VC 已添加（首次 layout 后）
        if currentChildVC == nil {
            showChildVC(at: selectedTabIndex)
        }
    }

    // MARK: - Child VC Management

    private func buildChildVCs() {
        childVCs = tabs.map { tab in
            OrderTabViewController(status: tab.status)
        }
    }

    /// 当前正在显示的子 VC（用于 appearance 管理）
    private var currentChildVC: OrderTabViewController?

    /// 显示指定索引的子 VC，手动触发生命周期
    private func showChildVC(at index: Int) {
        guard index >= 0, index < childVCs.count else { return }
        let isVisible = isViewLoaded && view.window != nil

        // 旧子 VC：viewWillDisappear + viewDidDisappear
        if let old = currentChildVC, isVisible {
            old.beginAppearanceTransition(false, animated: false)
            old.endAppearanceTransition()
        }

        // 移除旧子 VC
        for vc in children {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            vc.didMove(toParent: nil)
        }

        // 添加新子 VC
        let child = childVCs[index]
        child.willMove(toParent: self)
        addChild(child)
        containerView.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        child.didMove(toParent: self)
        currentChildVC = child

        // 新子 VC：viewWillAppear + viewDidAppear
        if isVisible {
            child.beginAppearanceTransition(true, animated: false)
            child.endAppearanceTransition()
        }
    }

    // 父 VC appearance 变化时，转发给当前子 VC
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

    // MARK: - Actions

    private func selectTab(at index: Int) {
        guard index != selectedTabIndex else { return }
        selectedTabIndex = index

        // 1. 更新 Cell 外观
        tabCollectionView.reloadData()

        // 2. 滚动 Tab 到可见区域
        tabCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)

        // 3. 切换子 VC
        showChildVC(at: index)
    }
}

// MARK: - UICollectionViewDataSource

extension OrderListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OrderTabCell.reuseId, for: indexPath) as? OrderTabCell else {
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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = tabs[indexPath.item].title
        let width = title.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.fdCaptionSemibold],
            context: nil
        ).width + 16 // 左右各 8pt padding
        return CGSize(width: ceil(width), height: 30)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

// MARK: - Tab Cell

private final class OrderTabCell: UICollectionViewCell {

    static let reuseId = "OrderTabCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaptionSemibold
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .fdPrimary : .fdSubtext
    }
}
