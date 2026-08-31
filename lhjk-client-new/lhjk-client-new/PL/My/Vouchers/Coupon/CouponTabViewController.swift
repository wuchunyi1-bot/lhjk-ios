import UIKit
import SnapKit

/// 优惠券单状态列表 — 独立 TableView（对齐订单 Tab）
final class CouponTabViewController: BaseViewController {

    let filter: CouponStatusFilter
    private let emptyTitle: String
    private let emptySubtitle: String
    private let couponService: CouponService

    private var coupons: [VoucherCouponAsset] = []
    private var expandedIds: Set<String> = []
    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?

    var onAvailableCountUpdated: ((Int) -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        tv.clipsToBounds = false
        tv.estimatedRowHeight = CouponCardCell.collapsedRowHeight(for: UIScreen.main.bounds.width)
        tv.dataSource = self
        tv.delegate = self
        tv.register(CouponCardCell.self, forCellReuseIdentifier: CouponCardCell.reuseID)
        tv.refreshControl = refreshControl
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let c = UIRefreshControl()
        c.tintColor = .fdPrimary
        c.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return c
    }()

    private lazy var emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        let icon = UIImageView(image: UIImage(systemName: "ticket"))
        icon.tintColor = .fdMuted
        icon.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = emptyTitle
        title.font = .fdMyBodyBold
        title.textColor = .fdText
        title.textAlignment = .center
        let subtitle = UILabel()
        subtitle.text = emptySubtitle
        subtitle.font = .fdMyCaption
        subtitle.textColor = .fdSubtext
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.spacing = 10
        stack.alignment = .center
        v.addSubview(stack)
        icon.snp.makeConstraints { $0.size.equalTo(40) }
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        return v
    }()

    init(
        filter: CouponStatusFilter,
        emptyTitle: String = "暂无相关优惠券",
        emptySubtitle: String = "可在确认订单时选择符合条件的优惠券。",
        couponService: CouponService = AppContainer.shared.couponService
    ) {
        self.filter = filter
        self.emptyTitle = emptyTitle
        self.emptySubtitle = emptySubtitle
        self.couponService = couponService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        loadTask?.cancel()
    }

    override func setupUI() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLoaded {
            reload()
        }
    }

    func refresh() {
        reload()
    }

    @objc private func handleRefresh() {
        reload()
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.couponService.getCouponTakeList(
                    status: self.filter.apiStatus,
                    pageNum: 1,
                    pageSize: 50
                )
                guard !Task.isCancelled else { return }

                var assets = result.items.map { $0.toVoucherAsset() }
                if self.filter == .all {
                    assets = VoucherListQuery.coupons(assets: assets, filter: .all)
                }

                await MainActor.run {
                    self.coupons = assets
                    self.hasLoaded = true
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    let empty = assets.isEmpty
                    self.emptyView.isHidden = !empty
                    self.tableView.isHidden = empty

                    if self.filter == .available {
                        self.onAvailableCountUpdated?(result.total)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.coupons = []
                    self.hasLoaded = true
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.emptyView.isHidden = false
                    self.tableView.isHidden = true
                }
            }
        }
    }
}

extension CouponTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coupons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let coupon = coupons[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CouponCardCell.reuseID,
            for: indexPath
        ) as! CouponCardCell
        cell.configure(coupon, expanded: expandedIds.contains(coupon.id))
        cell.onUse = {
            Router.shared.push("/services/list", params: ["code": ""])
        }
        cell.onToggleRules = { [weak self] in
            guard let self else { return }
            let id = coupon.id
            if self.expandedIds.contains(id) {
                self.expandedIds.remove(id)
            } else {
                self.expandedIds.insert(id)
            }
            let expanded = self.expandedIds.contains(id)
            UIView.performWithoutAnimation {
                if let cell = self.tableView.cellForRow(at: indexPath) as? CouponCardCell {
                    cell.configure(coupon, expanded: expanded)
                }
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let coupon = coupons[indexPath.row]
        let expanded = expandedIds.contains(coupon.id)
        return CouponCardCell.rowHeight(
            for: tableView.bounds.width,
            item: coupon,
            expanded: expanded
        )
    }
}
