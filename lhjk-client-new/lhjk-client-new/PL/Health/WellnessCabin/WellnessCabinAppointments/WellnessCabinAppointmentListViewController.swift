import Combine
import SnapKit
import UIKit

/// 康养小屋预约记录。门店详情顶栏进入。
final class WellnessCabinAppointmentListViewController: BaseViewController {

    private let viewModel = WellnessCabinAppointmentListViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tabScroll = UIScrollView()
    private let tabStack = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无预约记录")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        title = "预约记录"
        setupTabs()
        setupTable()
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        spinner.snp.makeConstraints { $0.center.equalTo(tableView) }
    }

    override func bindViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
        viewModel.$tab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.renderTabs() }
            .store(in: &cancellables)
        viewModel.$isLoading
            .combineLatest(viewModel.$isLoadingMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.render() }
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
        renderTabs()
        tableView.reloadData()
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

    private func setupTabs() {
        tabScroll.showsHorizontalScrollIndicator = false
        tabScroll.backgroundColor = UIColor(hexString: "#FDF6F3")
        tabStack.axis = .horizontal
        tabStack.spacing = 16
        tabStack.alignment = .fill
        view.addSubview(tabScroll)
        tabScroll.addSubview(tabStack)
        tabScroll.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(6)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(34)
        }
        tabStack.snp.makeConstraints {
            $0.edges.equalTo(tabScroll.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalTo(tabScroll.frameLayoutGuide)
        }
        renderTabs()
    }

    private func renderTabs() {
        tabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tab in CabinAppointmentTab.allCases {
            let selected = tab == viewModel.tab
            let title = UILabel()
            title.text = tab.title
            title.font = .fdFont(ofSize: 16, weight: selected ? .medium : .regular)
            title.textColor = UIColor(hexString: selected ? "#1F2942" : "#535D72")
            title.textAlignment = .center

            let mark = UIView()
            mark.backgroundColor = UIColor(hexString: "#FF7A50")
            mark.layer.cornerRadius = 2
            mark.clipsToBounds = true
            mark.isHidden = !selected

            let column = UIControl()
            column.tag = tab.rawValue
            column.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            column.addSubview(title)
            column.addSubview(mark)
            column.snp.makeConstraints { $0.height.equalTo(34) }
            title.snp.makeConstraints {
                $0.top.equalToSuperview().offset(2)
                $0.leading.trailing.equalToSuperview()
            }
            mark.snp.makeConstraints {
                $0.top.equalTo(title.snp.bottom).offset(4)
                $0.centerX.equalToSuperview()
                $0.width.equalTo(18)
                $0.height.equalTo(4)
            }
            tabStack.addArrangedSubview(column)
        }
    }

    private func setupTable() {
        tableView.backgroundColor = UIColor(hexString: "#FDF6F3")
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(WellnessCabinAppointmentCell.self, forCellReuseIdentifier: WellnessCabinAppointmentCell.reuseID)
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refresh
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(tabScroll.snp.bottom).offset(6)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
    }

    @objc private func tabTapped(_ sender: UIControl) {
        guard let tab = CabinAppointmentTab(rawValue: sender.tag) else { return }
        viewModel.select(tab)
    }

    @objc private func refreshPulled() {
        viewModel.reload()
    }

    private func openDetail(_ item: CabinAppointmentVO) {
        guard !item.id.isEmpty else {
            showToastAlert("未找到该预约")
            return
        }
        var params: [String: Any] = ["id": item.id]
        if !item.configId.isEmpty { params["configId"] = item.configId }
        Router.shared.push("/wellness-cabins/appointments/detail", params: params, from: self)
    }

    private func confirmCancel(_ item: CabinAppointmentVO) {
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
        Router.shared.push(
            "/wellness-cabins/detail",
            params: ["hospitalId": item.hospitalId],
            from: self
        )
    }
}

extension WellnessCabinAppointmentListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: WellnessCabinAppointmentCell.reuseID,
            for: indexPath
        ) as! WellnessCabinAppointmentCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item)
        cell.onDetail = { [weak self] in
            self?.openDetail(item)
        }
        cell.onBookAgain = { [weak self] in
            self?.bookAgain(item)
        }
        cell.onCancel = { [weak self] in
            self?.confirmCancel(item)
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard viewModel.hasMore, !viewModel.isLoadingMore, !viewModel.isLoading else { return }
        let threshold: CGFloat = 100
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        let offset = scrollView.contentOffset.y
        guard contentHeight > 0, offset + frameHeight >= contentHeight - threshold else { return }
        viewModel.loadMore()
    }
}
