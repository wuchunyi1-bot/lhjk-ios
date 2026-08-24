import UIKit
import SnapKit
import Combine

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
        tv.register(ServiceBannerCarouselCell.self, forCellReuseIdentifier: ServiceBannerCarouselCell.reuseID)
        tv.register(MatrixGridCell.self, forCellReuseIdentifier: MatrixGridCell.reuseID)
        tv.register(MallProductGridCell.self, forCellReuseIdentifier: MallProductGridCell.reuseID)
        tv.estimatedRowHeight = 120
        tv.rowHeight = UITableView.automaticDimension
        tv.sectionHeaderHeight = 0
        tv.sectionFooterHeight = 0
        tv.estimatedSectionHeaderHeight = 0
        tv.estimatedSectionFooterHeight = 0
        if #available(iOS 15.0, *) {
            // 关闭系统默认的 section 顶部留白，模块间距只由 footer 的 12pt 控制
            tv.sectionHeaderTopPadding = 0
        }
        tv.contentInsetAdjustmentBehavior = .never
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
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
        hubHeader.onCartTapped = { [weak self] in
            Router.shared.push("/services/cart", from: self)
        }
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
    }

    override func bindViewModel() {
        viewModel.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateFooterView()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$isLoadingMore, viewModel.$hasMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateFooterView()
            }
            .store(in: &cancellables)
    }

    private func updateFooterView() {
        if viewModel.isLoadingMore {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 50))
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            container.addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            tableView.tableFooterView = container
        } else if !viewModel.hasMore && (viewModel.snapshot?.mallPreviewPackages.count ?? 0) > 0 {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 50))
            let label = UILabel()
            label.text = "没有更多数据了"
            label.font = .fdCaption
            label.textColor = .fdMuted
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            tableView.tableFooterView = container
        } else {
            tableView.tableFooterView = nil
        }
    }

    private func sectionKind(at index: Int) -> ServiceViewModel.Section? {
        ServiceViewModel.Section(rawValue: index)
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
            cell.onHeightUpdated = { [weak self] in
                guard let self else { return }
                UIView.performWithoutAnimation {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            return cell

        case .matrix:
            let cell = tableView.dequeueReusableCell(withIdentifier: MatrixGridCell.reuseID, for: indexPath) as! MatrixGridCell
            cell.configure(snapshot.matrix)
            cell.onTileTap = { code in Router.shared.push("/services/list", params: ["code": code]) }
            return cell

        case .mallPreview:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: MallProductGridCell.reuseID,
                for: indexPath
            ) as! MallProductGridCell
            cell.configure(products: viewModel.mallPreviewPackages)
            cell.onMoreTapped = {
                Router.shared.push("/mall")
            }
            cell.onProductTap = { pkg in
                Router.shared.push("/services/pkg", params: pkg.packageDetailRouteParams())
            }
            cell.onContentHeightChanged = { [weak self] in
                guard let self else { return }
                UIView.performWithoutAnimation {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = sectionKind(at: indexPath.section) else {
            return UITableView.automaticDimension
        }
        switch section {
        case .matrix:
            return MatrixGridCell.cardHeight
        case .mallPreview:
            let count = viewModel.mallPreviewPackages.count
            guard count > 0 else { return UITableView.automaticDimension }
            let width = tableView.bounds.width > 0 ? tableView.bounds.width : UIScreen.main.bounds.width
            return MallProductGridCell.gridHeight(productCount: count, containerWidth: width)
        case .bannerCarousel:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = sectionKind(at: indexPath.section), section == .mallPreview else {
            return UITableView.automaticDimension
        }
        let count = viewModel.mallPreviewPackages.count
        guard count > 0 else { return 120 }
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : UIScreen.main.bounds.width
        return MallProductGridCell.gridHeight(productCount: count, containerWidth: width)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let s = sectionKind(at: section),
              let title = viewModel.sectionTitle(for: s) else { return nil }

        let header = SectionTitleView(title: title, more: viewModel.sectionMore(for: s))
        if s == .mallPreview {
            header.onMoreTapped = { Router.shared.push("/mall") }
        }
        let container = UIView()
        container.backgroundColor = .fdBg
        container.addSubview(header)
        header.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let s = sectionKind(at: section) else { return .leastNormalMagnitude }
        if viewModel.rowCount(for: s) == 0 { return .leastNormalMagnitude }
        // 富德优选保留标题行；Banner / 矩阵无 section header（矩阵标题在 Cell 内）
        return viewModel.sectionTitle(for: s) != nil ? 36 : .leastNormalMagnitude
    }

    /// Figma：Banner 底 → 矩阵顶约 12pt；矩阵 → 优选约 12pt
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let s = sectionKind(at: section), viewModel.rowCount(for: s) > 0 else {
            return .leastNormalMagnitude
        }
        switch s {
        case .bannerCarousel, .matrix:
            return 12
        case .mallPreview:
            return 12
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let h = self.tableView(tableView, heightForFooterInSection: section)
        guard h > 1 else { return nil }
        return spacingHeader(height: h)
    }

    private func spacingHeader(height: CGFloat) -> UIView {
        let v = UIView()
        v.snp.makeConstraints { $0.height.equalTo(height) }
        return v
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore, !viewModel.isLoadingMore else { return }

        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let contentOffset = scrollView.contentOffset.y

        if contentHeight > 0, contentOffset + frameHeight >= contentHeight - threshold {
            viewModel.loadMore()
        }
    }
}
