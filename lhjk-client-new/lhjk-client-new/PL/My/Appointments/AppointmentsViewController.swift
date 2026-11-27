import Combine
import SnapKit
import UIKit

/// 预约记录。一次拉取当前登录人的记录，不按 `businessType` 拆开请求。
///
/// 小屋仍走小屋详情、取消和再次预约。体检和就医协助：待安排无操作，待确认进确认页，其余状态由「查看详情」进入使用详情。点卡片只对小屋有效。
final class AppointmentsViewController: BaseViewController {

    private let viewModel = MyAppointmentsViewModel()
    private var cancellables = Set<AnyCancellable>()

    private lazy var tabCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor(hexString: "#FDF6F3")
        view.showsHorizontalScrollIndicator = false
        view.dataSource = self
        view.delegate = self
        view.register(OrderTabCell.self, forCellWithReuseIdentifier: OrderTabCell.reuseID)
        return view
    }()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无预约")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        title = "预约记录"
        view.backgroundColor = UIColor(hexString: "#FDF6F3")
        setupTabs()
        setupTable()
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalTo(tableView) }
    }

    override func bindViewModel() {
        viewModel.$items
            .combineLatest(viewModel.$isLoading, viewModel.$tab)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.render()
                self?.tabCollectionView.reloadData()
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.showToastAlert(message)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)
    }

    override func refreshForSeniorMode() {
        super.refreshForSeniorMode()
        tabCollectionView.reloadData()
        tableView.reloadData()
    }

    private func setupTabs() {
        let tabContainer = UIView()
        tabContainer.backgroundColor = UIColor(hexString: "#FDF6F3")
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(34)
        }
        tabContainer.addSubview(tabCollectionView)
        tabCollectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupTable() {
        tableView.backgroundColor = UIColor(hexString: "#FDF6F3")
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(MyAppointmentCell.self, forCellReuseIdentifier: MyAppointmentCell.reuseID)
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(tabCollectionView.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }
    }

    private func render() {
        emptyView.configure(message: viewModel.emptyText)
        let showEmpty = viewModel.items.isEmpty && !viewModel.isLoading
        emptyView.isHidden = !showEmpty
        tableView.isHidden = viewModel.items.isEmpty
        if viewModel.isLoading, viewModel.items.isEmpty {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
        if !viewModel.isLoading {
            refresh.endRefreshing()
        }
        tableView.reloadData()
    }

    @objc private func pullToRefresh() {
        viewModel.reload()
    }
}

extension AppointmentsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyAppointmentCell.reuseID, for: indexPath) as! MyAppointmentCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item)
        cell.onDetail = { [weak self] in
            if item.isCabin {
                self?.openDetail(item)
            } else {
                self?.openUsageDetail(item)
            }
        }
        cell.onBookAgain = { [weak self] in
            self?.bookAgain(item)
        }
        cell.onCancel = { [weak self] in
            self?.confirmCancel(item)
        }
        return cell
    }

    private func openDetail(_ item: CabinAppointmentVO) {
        guard item.isCabin else { return }
        var params: [String: Any] = ["id": item.id]
        if !item.configId.isEmpty { params["configId"] = item.configId }
        Router.shared.push("/wellness-cabins/appointments/detail", params: params, from: self)
    }

    private func openUsageDetail(_ item: CabinAppointmentVO) {
        guard item.status != 1 else { return }
        Router.shared.push(
            "/appointments/usage-records/confirm",
            params: ["id": item.id],
            from: self
        )
    }

    private func confirmCancel(_ item: CabinAppointmentVO) {
        guard item.isCabin else { return }
        let alert = UIAlertController(
            title: "确认取消本次预约？",
            message: "取消仅作废本次预约时段，您下次可直接重新选择服务项目预约。\n\n注：此处不会办理退款；如需退款，请前往「订单」办理退单/售后。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: "确认取消", style: .destructive) { [weak self] _ in
            self?.submitCancel(item)
        })
        present(alert, animated: true)
    }

    private func submitCancel(_ item: CabinAppointmentVO) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let cancelled = try await self.viewModel.cancel(item)
                await MainActor.run {
                    guard cancelled else { return }
                    self.showToastAlert("已取消本次预约")
                    self.viewModel.reload()
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "取消失败，请重试"
                await MainActor.run { self.showToastAlert(message) }
            }
        }
    }

    private func bookAgain(_ item: CabinAppointmentVO) {
        guard item.isCabin else { return }
        if !item.configId.isEmpty {
            var params: [String: Any] = ["configId": item.configId]
            if !item.hospitalId.isEmpty { params["hospitalId"] = item.hospitalId }
            Router.shared.push("/wellness-cabins/book", params: params, from: self)
            return
        }
        guard !item.hospitalId.isEmpty else {
            showToastAlert("暂无门店信息")
            return
        }
        Router.shared.push("/wellness-cabins/detail", params: ["hospitalId": item.hospitalId], from: self)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(viewModel.items[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let offset = scrollView.contentOffset.y
        let height = scrollView.contentSize.height
        let frame = scrollView.bounds.height
        guard height > frame, offset > height - frame - 80 else { return }
        viewModel.loadMore()
    }
}

extension AppointmentsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        MyAppointmentTab.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderTabCell.reuseID,
            for: indexPath
        ) as! OrderTabCell
        let tab = MyAppointmentTab.allCases[indexPath.item]
        cell.configure(title: tab.title, isSelected: tab == viewModel.tab)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tab = MyAppointmentTab.allCases[indexPath.item]
        guard tab != viewModel.tab else { return }
        viewModel.select(tab)
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let title = MyAppointmentTab.allCases[indexPath.item].title
        let width = title.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 32),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.fdFont(ofSize: 18, weight: .medium)],
            context: nil
        ).width + 4
        return CGSize(width: max(28, ceil(width)), height: 32)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}
