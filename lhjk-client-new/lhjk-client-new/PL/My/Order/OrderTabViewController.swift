import UIKit
import SnapKit

/// 订单列表子 VC — 单个 Tab 的 TableView + 数据加载
///
/// 每个 Tab 持有独立实例，具备数据缓存能力：
/// - 首次显示时请求 API
/// - 切换回已加载的 Tab 直接使用缓存，不重复请求
/// - 下拉刷新 / 外部 `refresh()` 可强制重新请求
final class OrderTabViewController: BaseViewController {

    // MARK: - Config

    /// 单状态筛选（nil 且无 statusList = 全部）
    let statusFilter: Int?
    /// 多状态筛选（逗号分隔 status）
    let statusListFilter: String?
    let emptyText: String

    // MARK: - State

    private var orders: [MOrder] = []
    private var hasLoaded = false
    private var isLoading = false
    private var isLoadingMore = false
    private var currentPage = 1
    private var hasMore = true
    private let pageSize = 10

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(OrderCardCell.self, forCellReuseIdentifier: OrderCardCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 200
        tv.refreshControl = refreshControl
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .fdPrimary
        control.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        return control
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        return label
    }()

    private lazy var emptyView: UIView = {
        let v = UIView()
        let icon = UIImageView(image: UIImage(systemName: "doc.text.magnifyingglass"))
        icon.tintColor = .fdMuted
        icon.contentMode = .scaleAspectFit
        v.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.size.equalTo(48)
        }
        v.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        return v
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .fdPrimary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var loadMoreFooter: UIView = {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = .fdPrimary
        spinner.tag = 9001
        container.addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalToSuperview() }
        return container
    }()

    // MARK: - Init

    init(status: Int? = nil, statusList: String? = nil, emptyText: String = "暂无订单") {
        self.statusFilter = status
        self.statusListFilter = statusList
        self.emptyText = emptyText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .fdBg
        emptyLabel.text = emptyText

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLoaded {
            loadOrders(trigger: .initial)
        }
    }

    // MARK: - Public

    func refresh() {
        loadOrders(trigger: .programmatic)
    }

    @objc private func handlePullToRefresh() {
        loadOrders(trigger: .pullToRefresh)
    }

    // MARK: - Data Loading

    private enum LoadTrigger {
        case initial
        case pullToRefresh
        case programmatic
        case loadMore
    }

    private func loadOrders(trigger: LoadTrigger) {
        let isLoadMore = trigger == .loadMore
        if isLoadMore {
            guard hasMore, !isLoadingMore, !isLoading else { return }
            isLoadingMore = true
            updateLoadMoreFooter(visible: true)
        } else {
            guard !isLoading else {
                endRefreshingIfNeeded(for: trigger)
                return
            }
            isLoading = true
            currentPage = 1
            hasMore = true

            if trigger == .initial {
                loadingIndicator.startAnimating()
                tableView.isHidden = true
            }
        }

        let requestPage = isLoadMore ? currentPage + 1 : 1

        Task {
            do {
                let data = try await OrderService.shared.getOrderList(
                    status: statusListFilter == nil ? statusFilter : nil,
                    statusList: statusListFilter,
                    pageNum: requestPage,
                    pageSize: pageSize
                )
                await MainActor.run {
                    let newRecords = data.records ?? []
                    if isLoadMore {
                        self.orders.append(contentsOf: newRecords)
                        self.isLoadingMore = false
                        self.updateLoadMoreFooter(visible: false)
                    } else {
                        self.orders = newRecords
                        self.isLoading = false
                        self.loadingIndicator.stopAnimating()
                        self.tableView.isHidden = false
                        self.endRefreshingIfNeeded(for: trigger)
                    }
                    self.currentPage = data.currentPage ?? requestPage
                    self.hasMore = self.resolveHasMore(data: data, fetchedCount: newRecords.count)
                    self.hasLoaded = true
                    self.updateDisplay()
                }
            } catch {
                await MainActor.run {
                    if isLoadMore {
                        self.isLoadingMore = false
                        self.updateLoadMoreFooter(visible: false)
                        self.showToast("加载失败: \(error.localizedDescription)")
                    } else {
                        self.isLoading = false
                        self.hasLoaded = true
                        self.loadingIndicator.stopAnimating()
                        self.tableView.isHidden = false
                        self.endRefreshingIfNeeded(for: trigger)
                        self.orders = []
                        self.updateDisplay()
                        self.showToast("加载失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func resolveHasMore(data: PaginatedOrderData, fetchedCount: Int) -> Bool {
        if let current = data.currentPage, let total = data.totalPages, total > 0 {
            return current < total
        }
        if let totalRecords = data.totalRecords, totalRecords > 0 {
            return orders.count < totalRecords
        }
        return fetchedCount >= pageSize
    }

    private func updateLoadMoreFooter(visible: Bool) {
        if visible {
            (loadMoreFooter.viewWithTag(9001) as? UIActivityIndicatorView)?.startAnimating()
            tableView.tableFooterView = loadMoreFooter
        } else {
            (loadMoreFooter.viewWithTag(9001) as? UIActivityIndicatorView)?.stopAnimating()
            tableView.tableFooterView = hasMore ? nil : UIView(frame: .zero)
        }
    }

    private func endRefreshingIfNeeded(for trigger: LoadTrigger) {
        guard trigger == .pullToRefresh, refreshControl.isRefreshing else { return }
        refreshControl.endRefreshing()
    }

    private func updateDisplay() {
        let isEmpty = orders.isEmpty
        tableView.backgroundView = isEmpty ? emptyView : nil
        tableView.reloadData()
    }

    private func handleAction(_ action: OrderListCardAction, order: MOrder) {
        switch action {
        case .pay:
            pushConfirm(order: order)
        case .cancel:
            OrderCancelFlow.start(from: self, order: order) { [weak self] _ in
                self?.refresh()
            }
        case .renew:
            OrderNavigationCoordinator.openPackageRenewal(from: self, order: order)
        case .confirmShip:
            OrderStatusActionFlow.confirmShipment(from: self, order: order) { [weak self] in
                self?.refresh()
            }
        case .confirmReceipt:
            OrderStatusActionFlow.confirmReceipt(from: self, order: order) { [weak self] in
                self?.refresh()
            }
        case .afterSale:
            OrderStatusActionFlow.afterSale(from: self, order: order) { [weak self] in
                self?.refresh()
            }
        case .settle:
            OrderStatusActionFlow.settle(from: self, order: order) { [weak self] in
                self?.refresh()
            }
        default:
            showToast("功能即将开放")
        }
    }

    private func pushConfirm(order: MOrder) {
        guard let id = order.id, id > 0 else {
            showToast("订单信息缺失")
            return
        }
        Router.shared.push("/orders/confirm", params: [
            "orderId": String(id),
            "entry": "order_pay",
        ])
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension OrderTabViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OrderCardCell.reuseIdentifier,
            for: indexPath
        ) as? OrderCardCell else {
            return UITableViewCell()
        }
        let order = orders[indexPath.row]
        cell.configure(order: order)
        cell.onAction = { [weak self] action in
            self?.handleAction(action, order: order)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderTabViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard orders.indices.contains(indexPath.row) else { return 200 }
        let hasActions = !OrderListCardAction.actions(
            for: orders[indexPath.row].orderStatus,
            packageType: orders[indexPath.row].packageType
        ).isEmpty
        return hasActions ? 210 : 160
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]
        if order.orderStatus == .pendingPayment {
            pushConfirm(order: order)
            return
        }
        if let id = order.id {
            Router.shared.push("/orders/detail", params: ["id": String(id)])
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasMore, !isLoadingMore, !isLoading, !orders.isEmpty else { return }

        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y

        if contentHeight > 0, contentOffset + frameHeight >= contentHeight - threshold {
            loadOrders(trigger: .loadMore)
        }
    }
}
