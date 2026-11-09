import Combine
import SnapKit
import UIKit

/// 预约体检落地页。首页金刚区 `FundeApp:/appointments/exams`
///
/// 套餐来自 `GET /v1/serviceItem/list?businessType=2`。使用记录没有接口。
final class ExamAppointmentViewController: BaseViewController {

    private let viewModel = ExamAppointmentListViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无可预约体检套餐")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        title = "预约体检"
        view.backgroundColor = .fdBg

        let recordsItem = UIBarButtonItem(
            title: "使用记录",
            style: .plain,
            target: self,
            action: #selector(openUsageRecords)
        )
        recordsItem.tintColor = .fdPrimary
        navigationItem.rightBarButtonItem = recordsItem

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.register(ExamPackageCell.self, forCellReuseIdentifier: ExamPackageCell.reuseID)
        tableView.tableHeaderView = sectionHeader()
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = refresh

        view.addSubview(tableView)
        view.addSubview(emptyView)
        spinner.color = .fdPrimary
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        emptyView.snp.makeConstraints { $0.edges.equalTo(tableView) }
        spinner.snp.makeConstraints { $0.center.equalTo(tableView) }
    }

    override func bindViewModel() {
        viewModel.$items
            .combineLatest(viewModel.$isLoading, viewModel.$isLoadingMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in self?.render() }
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
        tableView.tableHeaderView = sectionHeader()
        tableView.reloadData()
    }

    private func render() {
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

    private func sectionHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        let title = UILabel()
        title.text = "可预约体检套餐"
        title.font = .fdFont(ofSize: 16, weight: .semibold)
        title.textColor = .fdText
        header.addSubview(title)
        title.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalToSuperview()
        }
        return header
    }

    private func openDetail(_ item: ServiceItemVO) {
        var params: [String: Any] = ["configId": item.id]
        if let price = item.plainPrice {
            params["price"] = price
        }
        Router.shared.push("/appointments/exams/detail", params: params, from: self)
    }

    @objc private func openUsageRecords() {
        Router.shared.push("/appointments/exams/usage-records", from: self)
    }

    @objc private func pullToRefresh() {
        viewModel.reload()
    }
}

extension ExamAppointmentViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExamPackageCell.reuseID, for: indexPath) as! ExamPackageCell
        let item = viewModel.items[indexPath.row]
        cell.configure(item)
        cell.onBook = { [weak self] in self?.openDetail(item) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openDetail(viewModel.items[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let height = scrollView.contentSize.height
        let frame = scrollView.bounds.height
        guard height > frame, offset > height - frame - 80 else { return }
        viewModel.loadMore()
    }
}

/// 体检预约使用记录。履约列表没有接口。
final class ExamUsageRecordsViewController: BaseViewController {

    override func setupUI() {
        title = "使用记录"
        view.backgroundColor = .fdBg
        let empty = FDEmptyStateView(style: .page, message: "暂无使用记录")
        view.addSubview(empty)
        empty.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
