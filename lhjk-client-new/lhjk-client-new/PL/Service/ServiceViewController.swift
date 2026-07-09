import UIKit
import SnapKit
import Combine

// MARK: - Matrix Cell

fileprivate final class MatrixGridCell: UITableViewCell {
    static let reuseID = "MatrixGridCell"

    var onTileTap: ((String) -> Void)?
    private var items: [ProductMatrixItem] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ items: [ProductMatrixItem]) {
        self.items = items
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 4
        card.addSubview(grid)
        grid.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }

        for r in stride(from: 0, to: items.count, by: 3) {
            let row = UIStackView()
            row.distribution = .fillEqually
            row.spacing = 4
            for c in r..<min(r + 3, items.count) {
                row.addArrangedSubview(buildTile(items[c], index: c))
            }
            grid.addArrangedSubview(row)
        }
    }

    private func buildTile(_ m: ProductMatrixItem, index: Int) -> UIView {
        let tile = UIButton(type: .system)
        tile.backgroundColor = .clear
        tile.layer.cornerRadius = 12
        tile.tag = index

        let icon = UIView()
        icon.layer.cornerRadius = 12
        icon.backgroundColor = m.accent.withAlphaComponent(0.13)
        icon.layer.borderWidth = 1
        icon.layer.borderColor = m.accent.withAlphaComponent(0.2).cgColor
        let il = UILabel()
        il.text = m.code
        il.font = .fdCaptionSemibold
        il.textColor = m.accent
        il.textAlignment = .center
        icon.addSubview(il)
        il.snp.makeConstraints { $0.center.equalToSuperview() }
        icon.snp.makeConstraints { $0.size.equalTo(44) }

        let name = UILabel()
        name.text = m.name
        name.font = .fdCaptionSemibold
        name.textColor = .fdText
        name.textAlignment = .center
        let desc = UILabel()
        desc.text = m.desc
        desc.font = .fdMicro
        desc.textColor = .fdSubtext
        desc.textAlignment = .center
        desc.isHidden = m.desc.isEmpty
        let tier = UILabel()
        tier.text = m.tier
        tier.font = .fdMicroSemibold
        tier.textColor = m.accent
        tier.textAlignment = .center
        tier.isHidden = m.tier.isEmpty

        let stack = UIStackView(arrangedSubviews: [icon, name, desc, tier])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        tile.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)) }

        if m.current {
            let badge = UILabel()
            badge.text = "使用中"
            badge.font = .fdMicroSemibold
            badge.textColor = .white
            badge.backgroundColor = .fdPrimary
            badge.layer.cornerRadius = 4
            badge.textAlignment = .center
            badge.clipsToBounds = true
            tile.addSubview(badge)
            badge.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(4); $0.height.equalTo(16); $0.width.equalTo(44) }
        }

        tile.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
        return tile
    }

    @objc private func tileTapped(_ sender: UIButton) {
        guard sender.tag < items.count else { return }
        onTileTap?(items[sender.tag].code)
    }
}

// MARK: - ViewController

/// 服务模块 Hub 页 — 对齐 funde-client `ServicesView.vue`
final class ServiceViewController: BaseViewController {

    private let viewModel = ServiceViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let hubHeader = ServiceHubHeaderView()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(ActivateBannerCell.self, forCellReuseIdentifier: ActivateBannerCell.reuseID)
        tv.register(ServiceBannerCarouselCell.self, forCellReuseIdentifier: ServiceBannerCarouselCell.reuseID)
        tv.register(MatrixGridCell.self, forCellReuseIdentifier: MatrixGridCell.reuseID)
        tv.register(HealthPackageCategoryCell.self, forCellReuseIdentifier: HealthPackageCategoryCell.reuseID)
        tv.register(HealthPackageCardCell.self, forCellReuseIdentifier: HealthPackageCardCell.reuseID)
        tv.contentInsetAdjustmentBehavior = .never
        return tv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(hubHeader)
        view.addSubview(tableView)

        hubHeader.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(hubHeader.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        hubHeader.onInstitutionTap = { [weak self] in self?.presentInstitutionPicker() }
        hubHeader.onSearchTap = { [weak self] in self?.openSearch() }
        hubHeader.onCartTap = { Router.shared.push("/services/cart") }
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                guard let self, let snapshot else { return }
                self.hubHeader.configure(
                    institutionName: snapshot.institution.name,
                    showsInstitutionPicker: snapshot.institutions.count > 1
                )
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func sectionKind(at index: Int) -> ServiceViewModel.Section? {
        ServiceViewModel.Section(rawValue: index)
    }

    private func presentInstitutionPicker() {
        guard let snapshot = viewModel.snapshot, snapshot.institutions.count > 1 else { return }
        let sheet = UIAlertController(title: "选择服务机构", message: nil, preferredStyle: .actionSheet)
        for institution in snapshot.institutions {
            let title = institution.id == snapshot.institution.id
                ? "✓ \(institution.name)"
                : institution.name
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.selectInstitution(id: institution.id)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = hubHeader
            popover.sourceRect = CGRect(x: 20, y: 0, width: 200, height: 44)
        }
        present(sheet, animated: true)
    }

    private func openSearch() {
        var params: [String: Any] = [:]
        if let hospitalId = ServiceCatalogService.validApiHospitalId(viewModel.snapshot?.institution.hospitalId) {
            params["hospitalId"] = hospitalId
        }
        Router.shared.push("/services/search", params: params)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServiceViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        ServiceViewModel.Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = sectionKind(at: section) else { return 0 }
        return viewModel.rowCount(for: s)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let s = sectionKind(at: indexPath.section), let snapshot = viewModel.snapshot else {
            return UITableViewCell()
        }

        switch s {
        case .activateBanner:
            let cell = tableView.dequeueReusableCell(withIdentifier: ActivateBannerCell.reuseID, for: indexPath) as! ActivateBannerCell
            cell.onTap = { Router.shared.push("/activate") }
            return cell

        case .bannerCarousel:
            let cell = tableView.dequeueReusableCell(withIdentifier: ServiceBannerCarouselCell.reuseID, for: indexPath) as! ServiceBannerCarouselCell
            cell.configure(snapshot.banners)
            cell.onBannerTap = { banner in
                guard let path = banner.routePath else { return }
                if let id = banner.routeParamId {
                    Router.shared.push(path, params: ["id": id])
                } else {
                    Router.shared.push(path)
                }
            }
            return cell

        case .matrix:
            let cell = tableView.dequeueReusableCell(withIdentifier: MatrixGridCell.reuseID, for: indexPath) as! MatrixGridCell
            cell.configure(snapshot.matrix)
            cell.onTileTap = { code in Router.shared.push("/services/list", params: ["code": code]) }
            return cell

        case .recommend:
            if viewModel.isCategoryRow(at: indexPath) {
                let cell = tableView.dequeueReusableCell(withIdentifier: HealthPackageCategoryCell.reuseID, for: indexPath) as! HealthPackageCategoryCell
                cell.configure(
                    categories: snapshot.categoryTitles,
                    selected: snapshot.selectedCategoryTitle ?? snapshot.categoryTitles.first ?? ""
                )
                cell.onCategorySelected = { [weak self] category in
                    self?.viewModel.selectCategory(category)
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: HealthPackageCardCell.reuseID, for: indexPath) as! HealthPackageCardCell
            if let pkg = viewModel.package(at: indexPath) {
                cell.configure(pkg)
                cell.onDetailTap = { Router.shared.push("/services/pkg", params: ["id": pkg.id]) }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = sectionKind(at: section),
              let title = viewModel.sectionTitle(for: s) else { return spacingHeader(height: 8) }

        let header = SectionTitleView(title: title, more: viewModel.sectionMore(for: s))
        if s == .recommend {
            header.onMoreTapped = { Router.shared.push("/services/list", params: ["code": "all"]) }
        }
        let container = UIView()
        container.backgroundColor = .fdBg
        container.addSubview(header)
        header.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = sectionKind(at: section) else { return 8 }
        if viewModel.rowCount(for: s) == 0 { return .leastNormalMagnitude }
        return viewModel.sectionTitle(for: s) != nil ? 36 : 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { spacingHeader(height: 8) }

    private func spacingHeader(height: CGFloat) -> UIView {
        let v = UIView()
        v.snp.makeConstraints { $0.height.equalTo(height) }
        return v
    }
}
