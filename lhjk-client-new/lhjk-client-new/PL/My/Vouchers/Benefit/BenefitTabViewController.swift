import UIKit
import SnapKit

/// 权益卡单状态列表 — 真实接口 `/v1/benefitsTake/*`
final class BenefitTabViewController: BaseViewController {

    let filter: BenefitStatusFilter
    private let emptyText: String
    private let voucherService: VoucherService

    private var entries: [BenefitListEntry] = []
    private var hasLoaded = false
    private var loadTask: Task<Void, Never>?

    var onAvailableCountUpdated: ((Int) -> Void)?

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 140
        tv.dataSource = self
        tv.delegate = self
        tv.register(VoucherBindEntryCell.self, forCellReuseIdentifier: VoucherBindEntryCell.reuseID)
        tv.register(BenefitCardCell.self, forCellReuseIdentifier: BenefitCardCell.reuseID)
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
        let icon = UIImageView(image: UIImage(systemName: "gift.fill"))
        icon.tintColor = .fdMuted
        icon.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = emptyText
        label.font = .fdMyCaption
        label.textColor = .fdMuted
        label.textAlignment = .center
        v.addSubview(icon)
        v.addSubview(label)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-24)
            make.size.equalTo(40)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
        return v
    }()

    init(
        filter: BenefitStatusFilter,
        emptyText: String = "暂无相关权益卡",
        voucherService: VoucherService = AppContainer.shared.voucherService
    ) {
        self.filter = filter
        self.emptyText = emptyText
        self.voucherService = voucherService
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
                let list = try await self.voucherService.loadBenefitEntries(filter: self.filter)
                await MainActor.run {
                    self.entries = list
                    self.hasLoaded = true
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.updateEmpty()
                    if self.filter == .available || self.filter == .all {
                        self.onAvailableCountUpdated?(self.voucherService.availableBenefitCount)
                    }
                }
                if self.filter == .available {
                    _ = await self.voucherService.refreshAvailableBenefitCount()
                    await MainActor.run {
                        self.onAvailableCountUpdated?(self.voucherService.availableBenefitCount)
                    }
                }
            } catch {
                await MainActor.run {
                    self.refreshControl.endRefreshing()
                    self.hasLoaded = true
                    self.updateEmpty()
                    self.showToast(error.localizedDescription)
                }
            }
        }
    }

    private func updateEmpty() {
        let hasBind = showsBindRow
        let empty = entries.isEmpty && !hasBind
        emptyView.isHidden = !empty
        tableView.isHidden = empty
    }

    private var showsBindRow: Bool {
        VoucherListQuery.showsBindEntry(for: filter)
    }

    private func showToast(_ message: String) {
        showToastAlert(message, duration: 1.4)
    }

    private func openBind() {
        Router.shared.push("/activate/bind")
    }

    private func openRedeem(_ card: BenefitCard) {
        Router.shared.push("/activate/redeem")
        _ = card
    }

    private func openTransfer(_ card: BenefitCard) {
        guard card.canGift, let takeId = Int64(card.id) else {
            showToast("该权益卡暂不可转赠")
            return
        }
        let vc = BenefitTransferViewController(card: card, benefitsTakeId: takeId)
        vc.onGifted = { [weak self] in self?.reload() }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openOrder(_ card: BenefitCard) {
        guard let orderId = card.orderId, !orderId.isEmpty else {
            showToast("暂无关联订单")
            return
        }
        Router.shared.push("/orders/detail", params: ["id": orderId])
    }
}

extension BenefitTabViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (showsBindRow ? 1 : 0) + entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsBindRow && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: VoucherBindEntryCell.reuseID,
                for: indexPath
            ) as! VoucherBindEntryCell
            cell.onTap = { [weak self] in self?.openBind() }
            return cell
        }
        let entryIndex = showsBindRow ? indexPath.row - 1 : indexPath.row
        let entry = entries[entryIndex]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BenefitCardCell.reuseID,
            for: indexPath
        ) as! BenefitCardCell
        switch entry {
        case .card(let card):
            cell.configureCard(card)
            cell.onPrimary = { [weak self] in
                if card.status == .redeemed {
                    self?.openOrder(card)
                } else {
                    self?.openRedeem(card)
                }
            }
            cell.onSecondary = { [weak self] in self?.openTransfer(card) }
        case .transfer(let record):
            cell.configureTransfer(record)
        }
        return cell
    }
}
