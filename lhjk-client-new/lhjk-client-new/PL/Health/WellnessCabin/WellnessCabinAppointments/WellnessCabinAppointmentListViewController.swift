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
        tabScroll.backgroundColor = .fdSurface
        tabStack.axis = .horizontal
        tabStack.spacing = 8
        tabStack.alignment = .center
        view.addSubview(tabScroll)
        tabScroll.addSubview(tabStack)
        tabScroll.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48)
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
            let button = UIButton(type: .system)
            button.setTitle(tab.title, for: .normal)
            button.titleLabel?.font = .fdFont(ofSize: 14, weight: tab == viewModel.tab ? .semibold : .regular)
            button.setTitleColor(tab == viewModel.tab ? .fdPrimary : .fdSubtext, for: .normal)
            button.tag = tab.rawValue
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            tabStack.addArrangedSubview(button)
        }
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
        tableView.register(WellnessCabinAppointmentCell.self, forCellReuseIdentifier: WellnessCabinAppointmentCell.reuseID)
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refresh
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(tabScroll.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }
    }

    @objc private func tabTapped(_ sender: UIButton) {
        guard let tab = CabinAppointmentTab(rawValue: sender.tag) else { return }
        viewModel.select(tab)
    }

    @objc private func refreshPulled() {
        viewModel.reload()
    }

    private func bookAgain(_ item: CabinAppointmentVO) {
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
        cell.onBookAgain = { [weak self] in
            self?.bookAgain(item)
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
