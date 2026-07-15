import UIKit
import SnapKit
import Combine

/// 服务套餐详情 — 对齐图示；数据优先 `getHospitalPackageDetail`
final class ServicePackageDetailViewController: BaseViewController {

    private let viewModel: ServicePackageDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let orderBar = PackageDetailOrderBarView()
    private let statusLabel = UILabel()

    private let tabBarView = PackageDetailTabBarView()
    private var carouselView: PackageDetailCarouselView?
    private let infoView = PackageDetailInfoView()
    private var tierPickerView: PackageDetailTierPickerView?
    private let detailCardView = PackageDetailCardView()
    private var autoScrollTimer: Timer?

    private enum TableRow: Equatable {
        case carousel
        case info
        case tier
        case tabBar
        case comboGroup(ServicePackageComboGroup)
        case detail
    }

    private var activeTab: PackageDetailTab = .content
    private var tierIndex = 0
    private var rows: [TableRow] = []
    /// 单选组：groupName → 选中下标（第 0 项锁定）
    private var radioPicks: [String: Int] = [:]
    /// 多选组：groupName → 选中下标集合
    private var checkPicks: [String: Set<Int>] = [:]

    private var package: ServicePackageDetail? { viewModel.package }

    private var activeTier: ServicePackageTier? {
        guard let package, package.tiers.indices.contains(tierIndex) else { return nil }
        return package.tiers[tierIndex]
    }

    init(
        packageId: String,
        hospitalId: String? = nil
    ) {
        self.viewModel = ServicePackageDetailViewModel(
            packageId: packageId,
            hospitalId: hospitalId
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { stopAutoScroll() }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "套餐详情"

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ServicePackageHostedCell.self, forCellReuseIdentifier: ServicePackageHostedCell.reuseID)
        tableView.isHidden = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        tabBarView.delegate = self

        statusLabel.font = .fdBody
        statusLabel.textColor = .fdSubtext
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "套餐信息加载中..."
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(-40)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    override func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self, self.package == nil else { return }
                self.statusLabel.text = loading ? "套餐信息加载中..." : self.statusLabel.text
            }
            .store(in: &cancellables)

        viewModel.$package
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pkg in
                guard let self, let pkg else { return }
                self.render(pkg)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self, self.package == nil, let message, !message.isEmpty else { return }
                self.statusLabel.text = message
            }
            .store(in: &cancellables)

        viewModel.load()
    }

    private func render(_ pkg: ServicePackageDetail) {
        stopAutoScroll()
        orderBar.removeFromSuperview()
        carouselView = nil
        tierPickerView = nil
        tierIndex = 0
        activeTab = .content

        resetPicks(for: pkg.tiers[tierIndex])
        carouselView = PackageDetailCarouselView(
            labels: pkg.carouselLabels,
            imageURLs: pkg.carouselImageURLs,
            accent: pkg.accent
        )
        infoView.configure(with: pkg)
        if pkg.tiers.count > 1 {
            let picker = PackageDetailTierPickerView()
            picker.delegate = self
            picker.configure(tiers: pkg.tiers, selectedIndex: tierIndex, accent: pkg.accent)
            tierPickerView = picker
        }
        detailCardView.configure(with: pkg)
        rebuildRows()
        setupOrderBar()

        statusLabel.isHidden = true
        tableView.isHidden = false
        selectTab(.content, animated: false)
        startAutoScroll()
        refreshPayable()
    }

    private func setupOrderBar() {
        orderBar.onAddToCart = { [weak self] in self?.tapCart() }
        orderBar.onOrder = { [weak self] in self?.tapOrder() }
        orderBar.attach(to: view, below: tableView)
        tableView.contentInset.bottom = 12
    }

    private func rebuildRows() {
        guard package != nil else {
            rows = []
            return
        }
        var next: [TableRow] = [.carousel, .info]
        if tierPickerView != nil { next.append(.tier) }
        next.append(.tabBar)
        switch activeTab {
        case .content:
            for group in activeTier?.groups ?? [] {
                next.append(.comboGroup(group))
            }
        case .detail:
            next.append(.detail)
        }
        rows = next
    }

    private func reloadTableContent() {
        rebuildRows()
        tableView.reloadData()
    }

    private func selectTab(_ tab: PackageDetailTab, animated: Bool) {
        activeTab = tab
        tabBarView.select(tab, animated: animated)
        rebuildRows()
        tableView.reloadData()
        if !animated { view.layoutIfNeeded() }
    }

    private func resetPicks(for tier: ServicePackageTier) {
        var radios: [String: Int] = [:]
        var checks: [String: Set<Int>] = [:]
        for group in tier.groups {
            switch group.selectMode {
            case .radio:
                let preferred = group.items.enumerated().first { $0.offset > 0 && $0.element.defaultSelected }?.offset
                radios[group.name] = preferred ?? (group.items.count > 1 ? 1 : 0)
            case .checkbox:
                checks[group.name] = Set(
                    group.items.enumerated().compactMap { $0.element.defaultSelected ? $0.offset : nil }
                )
            case .required:
                break
            }
        }
        radioPicks = radios
        checkPicks = checks
    }

    private func makeComboGroupView(_ group: ServicePackageComboGroup) -> PackageComboGroupView {
        let view = PackageComboGroupView()
        view.configure(
            group: group,
            radioPick: radioPicks[group.name],
            checkPicks: checkPicks[group.name] ?? []
        )
        view.onRadioSelect = { [weak self] index in
            guard let self else { return }
            self.radioPicks[group.name] = index
            self.reloadTableContent()
            self.refreshPayable()
        }
        view.onCheckToggle = { [weak self] index in
            guard let self else { return }
            var set = self.checkPicks[group.name] ?? []
            if set.contains(index) { set.remove(index) } else { set.insert(index) }
            self.checkPicks[group.name] = set
            self.reloadTableContent()
            self.refreshPayable()
        }
        return view
    }

    private func refreshPayable() {
        guard let tier = activeTier else {
            orderBar.setPayableText("—")
            return
        }
        if tier.price == 0 && tier.priceUnit.contains("面议") {
            orderBar.setPayableText("面议")
            return
        }
        var total = tier.price
        for group in tier.groups where group.selectMode == .checkbox {
            let picked = checkPicks[group.name] ?? []
            for i in picked where group.items.indices.contains(i) {
                total += group.items[i].price
            }
        }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        let num = f.string(from: NSNumber(value: total)) ?? "\(total)"
        orderBar.setPayableText("¥\(num)")
    }

    private func startAutoScroll() {
        stopAutoScroll()
        guard let carousel = carouselView, carousel.pageCount > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { [weak self] _ in
            self?.carouselView?.advancePage()
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func tapCart() {
        guard let pkg = package else { return }
        AppContainer.shared.cartService.addPackage(pkg)
        Router.shared.push("/services/cart")
    }

    private func tapOrder() {
        let id = package?.id ?? ""
        Router.shared.push("/orders/confirm", params: ["id": id])
    }
}

// MARK: - UITableView

extension ServicePackageDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ServicePackageHostedCell.reuseID,
            for: indexPath
        ) as! ServicePackageHostedCell

        switch row {
        case .carousel:
            if let carousel = carouselView {
                cell.host(carousel, insets: UIEdgeInsets(top: 8, left: 16, bottom: 0, right: 16))
            }
        case .info:
            cell.host(infoView, insets: UIEdgeInsets(top: 14, left: 16, bottom: 0, right: 16))
        case .tier:
            if let tierPickerView {
                cell.host(tierPickerView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
            }
        case .tabBar:
            cell.host(tabBarView, insets: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
        case .comboGroup(let group):
            let box = makeComboGroupView(group)
            let isLast = indexPath.row == rows.count - 1
            cell.host(box, insets: UIEdgeInsets(top: 10, left: 16, bottom: isLast ? 24 : 0, right: 16))
        case .detail:
            cell.host(detailCardView, insets: UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16))
        }
        return cell
    }
}

// MARK: - Delegates

extension ServicePackageDetailViewController: PackageDetailTabBarViewDelegate {

    func tabBarView(_ view: PackageDetailTabBarView, didSelect tab: PackageDetailTab) {
        selectTab(tab, animated: true)
    }
}

extension ServicePackageDetailViewController: PackageDetailTierPickerViewDelegate {

    func tierPickerView(_ view: PackageDetailTierPickerView, didSelect index: Int) {
        guard let pkg = package, index != tierIndex else { return }
        tierIndex = index
        resetPicks(for: pkg.tiers[tierIndex])
        view.configure(tiers: pkg.tiers, selectedIndex: tierIndex, accent: pkg.accent)
        reloadTableContent()
        refreshPayable()
    }
}
