import UIKit
import SnapKit

/// 权益卡单状态列表 — 对齐订单 `OrderTabViewController`（独立 TableView + 缓存）
final class BenefitTabViewController: BaseViewController {

    let filter: BenefitStatusFilter
    private let emptyText: String
    private let voucherService: VoucherService

    private var entries: [BenefitListEntry] = []
    private var hasLoaded = false
    private var countdownTimer: Timer?
    private var now = Date()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
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
        label.font = .fdCaption
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
        countdownTimer?.invalidate()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLoaded {
            reload()
        } else {
            startCountdownIfNeeded()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    func refresh() {
        reload()
    }

    @objc private func handleRefresh() {
        reload()
    }

    private func reload() {
        let cards = voucherService.getBenefitCards()
        let transfers = voucherService.getTransferRecords()
        entries = VoucherListQuery.benefitEntries(cards: cards, transfers: transfers, filter: filter)
        hasLoaded = true
        tableView.reloadData()
        refreshControl.endRefreshing()
        updateEmpty()
        startCountdownIfNeeded()
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

    private func startCountdownIfNeeded() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        let needs = entries.contains {
            if case .transfer(let r) = $0 { return r.status == .waiting }
            return false
        }
        guard needs else { return }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.now = Date()
            self.tableView.reloadData()
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }

    private func openBind() { showToast("绑定权益卡功能即将开放") }
    private func openRedeem(_ card: BenefitCard) {
        showToast("兑换套餐功能即将开放")
        _ = card
    }
    private func openTransfer(_ card: BenefitCard) {
        showToast("赠送好友功能即将开放")
        _ = card
    }
    private func openOrder(_ card: BenefitCard) {
        guard let orderId = card.orderId, !orderId.isEmpty else {
            showToast("订单异常")
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
            cell.configureTransfer(
                record,
                countdown: VoucherListQuery.remainingTransferText(expiresAt: record.expiresAt, now: now)
            )
        }
        return cell
    }
}
