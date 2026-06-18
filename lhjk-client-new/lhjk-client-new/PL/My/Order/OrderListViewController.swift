import UIKit
import SnapKit

/// 全部订单列表 — 5 Tab 筛选 + 订单卡片
/// 参考 funde-client: OrderListView.vue
final class OrderListViewController: BaseViewController {

    // MARK: - Data Models

    private enum OrderStatus: String, CaseIterable {
        case pendingUse = "pending_use"
        case inProgress = "in_progress"
        case completed = "completed"
        case pendingReview = "pending_review"

        var label: String {
            switch self {
            case .pendingUse: return "待使用"
            case .inProgress: return "使用中"
            case .completed: return "已完成"
            case .pendingReview: return "待评价"
            }
        }
    }

    private struct ServiceOrder {
        let id: String
        let serviceName: String
        let serviceTag: String
        let status: OrderStatus
        let statusLabel: String
        let startDate: String
        let endDate: String
        let price: Int
        let daysLeft: Int
    }

    // MARK: - Tabs

    private let tabs = ["全部", "待使用", "使用中", "已完成", "待评价"]
    private let tabStatus: [OrderStatus?] = [nil, .pendingUse, .inProgress, .completed, .pendingReview]

    // MARK: - Mock Data

    private let allOrders: [ServiceOrder] = [
        ServiceOrder(id: "ord-001", serviceName: "德好·慢病逆转", serviceTag: "三好共管",
                     status: .inProgress, statusLabel: "使用中",
                     startDate: "2026-03-15", endDate: "2026-09-15", price: 9800, daysLeft: 45),
        ServiceOrder(id: "ord-002", serviceName: "德健·健康管理师", serviceTag: "健管家",
                     status: .completed, statusLabel: "已完成",
                     startDate: "2025-01-01", endDate: "2025-12-31", price: 2980, daysLeft: 0),
        ServiceOrder(id: "ord-003", serviceName: "慈铭高端体检", serviceTag: "三甲体检套餐",
                     status: .pendingUse, statusLabel: "待使用",
                     startDate: "2026-05-28", endDate: "2026-06-30", price: 1680, daysLeft: 35),
        ServiceOrder(id: "ord-004", serviceName: "营养师膳食指导", serviceTag: "慢病饮食干预",
                     status: .pendingReview, statusLabel: "待评价",
                     startDate: "2026-04-01", endDate: "2026-05-01", price: 699, daysLeft: 0),
    ]

    private let initialTab: String?

    init(initialTab: String? = nil) {
        self.initialTab = initialTab
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - State

    private var selectedTabIndex = 0

    private lazy var filteredOrders: [ServiceOrder] = {
        let status = tabStatus[selectedTabIndex]
        guard let status = status else { return allOrders }
        return allOrders.filter { $0.status == status }
    }()

    // MARK: - UI

    private lazy var segmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: tabs)
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        return seg
    }()

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的订单"

        // Apply initial tab from route params (e.g. /orders?tab=pending_use)
        if let tab = initialTab, let idx = tabStatus.firstIndex(where: { $0?.rawValue == tab }) {
            selectedTabIndex = idx
            segmentedControl.selectedSegmentIndex = idx
        }
    }

    override func setupUI() {
        view.backgroundColor = .fdBg

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(32)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.isHidden = true

        updateDisplay()
    }

    // MARK: - Actions

    @objc private func tabChanged(_ seg: UISegmentedControl) {
        selectedTabIndex = seg.selectedSegmentIndex
        updateDisplay()
    }

    private func updateDisplay() {
        let status = tabStatus[selectedTabIndex]
        if let status = status {
            filteredOrders = allOrders.filter { $0.status == status }
        } else {
            filteredOrders = allOrders
        }
        tableView.reloadData()
        emptyView.isHidden = !filteredOrders.isEmpty
        tableView.isHidden = filteredOrders.isEmpty
    }
}

// MARK: - UITableViewDataSource

extension OrderListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredOrders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderCardCell.reuseIdentifier, for: indexPath) as? OrderCardCell else {
            return UITableViewCell()
        }
        let o = filteredOrders[indexPath.row]
        cell.configure(
            name: o.serviceName,
            status: o.statusLabel,
            statusKey: o.status.rawValue,
            tag: o.serviceTag,
            startDate: o.startDate,
            endDate: o.endDate,
            price: o.price,
            daysLeft: o.daysLeft
        )
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let order = filteredOrders[indexPath.row]
        Router.shared.push("/orders/detail", params: ["id": order.id])
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
}
