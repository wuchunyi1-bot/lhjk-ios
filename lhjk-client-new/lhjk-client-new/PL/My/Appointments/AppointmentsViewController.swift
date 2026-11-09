import Combine
import SnapKit
import UIKit

/// 我的预约。汇总入口，当前只接得到康养小屋预约记录。
///
/// 体检预约、就医协助没有使用记录接口。待安排、待确认因此为空。
final class AppointmentsViewController: BaseViewController {

    private let viewModel = MyAppointmentsViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tabScroll = UIScrollView()
    private let tabStack = UIStackView()
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
        title = "我的预约"
        view.backgroundColor = .fdBg
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
                self?.renderTabs()
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
        renderTabs()
        tableView.reloadData()
    }

    private func setupTabs() {
        tabScroll.showsHorizontalScrollIndicator = false
        tabScroll.backgroundColor = .fdSurface
        tabStack.axis = .horizontal
        tabStack.spacing = 4
        tabStack.alignment = .center
        view.addSubview(tabScroll)
        tabScroll.addSubview(tabStack)
        tabScroll.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(48)
        }
        tabStack.snp.makeConstraints {
            $0.edges.equalTo(tabScroll.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
            $0.height.equalTo(tabScroll.frameLayoutGuide)
        }
        renderTabs()
    }

    private func renderTabs() {
        tabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tab in MyAppointmentTab.allCases {
            let button = UIButton(type: .system)
            button.setTitle(tab.title, for: .normal)
            let selected = tab == viewModel.tab
            button.titleLabel?.font = .fdFont(ofSize: 14, weight: selected ? .semibold : .regular)
            button.setTitleColor(selected ? .fdPrimary : .fdSubtext, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
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
        tableView.estimatedRowHeight = 160
        tableView.register(MyAppointmentCell.self, forCellReuseIdentifier: MyAppointmentCell.reuseID)
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
        view.addSubview(tableView)
        view.addSubview(emptyView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(tabScroll.snp.bottom)
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

    @objc private func tabTapped(_ sender: UIButton) {
        guard let tab = MyAppointmentTab(rawValue: sender.tag) else { return }
        viewModel.select(tab)
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
            guard let self else { return }
            var params: [String: Any] = ["id": item.id]
            if !item.configId.isEmpty { params["configId"] = item.configId }
            Router.shared.push("/wellness-cabins/appointments/detail", params: params, from: self)
        }
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let height = scrollView.contentSize.height
        let frame = scrollView.bounds.height
        guard height > frame, offset > height - frame - 80 else { return }
        viewModel.loadMore()
    }
}
