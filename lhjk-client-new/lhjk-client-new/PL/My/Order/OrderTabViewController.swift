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

    /// Tab 对应的 API 状态筛选（nil=全部）
    let statusFilter: Int?

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
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        return tv
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
        let label = UILabel()
        label.text = "暂无订单"
        label.font = .fdCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        v.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
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

    init(status: Int? = nil) {
        self.statusFilter = status
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func setupUI() {
        view.backgroundColor = .fdBg

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
        // 仅首次加载
        if !hasLoaded {
            loadOrders()
        }
    }

    // MARK: - Public

    /// 强制刷新（如订单状态变更后调用）
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
                    status: statusFilter
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

    // MARK: - Toast

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
        return orders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderCardCell.reuseIdentifier, for: indexPath) as? OrderCardCell else {
            return UITableViewCell()
        }
        cell.configure(order: orders[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderTabViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]
        if let id = order.id {
            Router.shared.push("/orders/detail", params: ["id": String(id)])
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
}
