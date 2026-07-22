import UIKit
import SnapKit

/// 订单列表子 VC — 单个 Tab 的 TableView + 数据加载
///
/// 每个 Tab 持有独立实例，具备数据缓存能力：
/// - 首次显示时请求 API
/// - 切换回已加载的 Tab 直接使用缓存，不重复请求
/// - 外部调用 `refresh()` 可强制刷新
final class OrderTabViewController: BaseViewController {

    // MARK: - Config

    /// 单状态筛选（nil 且无 statusList = 全部）
    let statusFilter: Int?
    /// 多状态筛选（如退款/售后 `6,9`）
    let statusListFilter: String?
    let emptyText: String

    // MARK: - State

    private var orders: [MOrder] = []
    private var hasLoaded = false
    private var isLoading = false

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
        return tv
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

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyView.isHidden = true

        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLoaded {
            loadOrders()
        }
    }

    // MARK: - Public

    func refresh() {
        hasLoaded = false
        loadOrders()
    }

    // MARK: - Data Loading

    private func loadOrders() {
        guard !isLoading else { return }
        isLoading = true

        loadingIndicator.startAnimating()
        tableView.isHidden = true
        emptyView.isHidden = true

        Task {
            do {
                let data = try await OrderService.shared.getOrderList(
                    status: statusListFilter == nil ? statusFilter : nil,
                    statusList: statusListFilter
                )
                await MainActor.run {
                    self.orders = data.records ?? []
                    self.isLoading = false
                    self.hasLoaded = true
                    self.loadingIndicator.stopAnimating()
                    self.updateDisplay()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.hasLoaded = true
                    self.loadingIndicator.stopAnimating()
                    self.orders = []
                    self.updateDisplay()
                    self.showToast("加载失败: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateDisplay() {
        let isEmpty = orders.isEmpty
        tableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        if !isEmpty {
            tableView.reloadData()
        }
    }

    private func handleAction(_ action: OrderListCardAction, order: MOrder) {
        switch action {
        case .pay:
            pushConfirm(order: order)
        default:
            showToast("功能即将开放")
        }
    }

    private func pushConfirm(order: MOrder) {
        guard let id = order.id, id > 0 else {
            showToast("订单信息缺失")
            return
        }
        Router.shared.push("/orders/confirm", params: ["orderId": String(id)])
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
        160
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
}
