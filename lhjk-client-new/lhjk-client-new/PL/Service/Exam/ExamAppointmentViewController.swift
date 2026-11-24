import Combine
import SnapKit
import UIKit

/// 预约体检落地页。首页金刚区 `FundeApp:/appointments/exams`
///
/// 套餐来自 `GET /v1/cabin/medicalConfigList?businessType=2`。使用记录走预约列表并带 `businessType=2`。
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
        title.font = .fdFont(designSize: 16, seniorSize: 19, weight: .bold)
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

    private func confirmBook(_ item: ServiceItemVO) {
        let needsPurchase = item.needsPurchase && !(item.packageId ?? "").isEmpty
        let alert = UIAlertController(
            title: "确认预约",
            message: needsPurchase
                ? "「\(item.name)」需要购买后才能预约。"
                : "确认预约这个体检套餐吗？确认后会为您联系工作人员继续安排。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "再想想", style: .cancel))
        alert.addAction(UIAlertAction(title: needsPurchase ? "去购买" : "确认预约", style: .default) { [weak self] _ in
            guard let self else { return }
            if needsPurchase, let packageId = item.packageId {
                let params = ServiceRoutes.packageDetailParams(packageId: packageId)
                Router.shared.push("/services/pkg", params: params, from: self)
            } else {
                self.showToastAlert("已提交预约，工作人员会联系您安排")
            }
        })
        present(alert, animated: true)
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
        cell.configure(item, isFirst: indexPath.row == 0, isLast: indexPath.row == viewModel.items.count - 1)
        cell.onBook = { [weak self] in self?.confirmBook(item) }
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

/// 体检、就医协助的使用记录。同一接口按 `businessType` 分开，避免两边看到对方的数据。
class ServiceUsageRecordsViewController: BaseViewController {

    private let viewModel: ServiceUsageRecordsViewModel
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = FDEmptyStateView(style: .page, message: "暂无使用记录")
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let refresh = UIRefreshControl()

    init(businessType: Int) {
        viewModel = ServiceUsageRecordsViewModel(businessType: businessType)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.reload()
    }

    override func setupUI() {
        title = "使用记录"
        view.backgroundColor = .fdBg
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 160
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(MyAppointmentCell.self, forCellReuseIdentifier: MyAppointmentCell.reuseID)
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
            .combineLatest(viewModel.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.render() }
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

    @objc private func pullToRefresh() {
        viewModel.reload()
    }
}

extension ServiceUsageRecordsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MyAppointmentCell.reuseID,
            for: indexPath
        ) as! MyAppointmentCell
        cell.configure(viewModel.items[indexPath.row], showsCabinActions: false)
        return cell
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

@MainActor
final class ServiceUsageRecordsViewModel: ObservableObject {

    @Published private(set) var items: [CabinAppointmentVO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = false
    @Published private(set) var errorMessage: String?

    private let businessType: Int
    private let pageSize = 20
    private var currentPage = 1
    private var requestID = 0
    private let cabinService: CabinService

    init(
        businessType: Int,
        cabinService: CabinService = AppContainer.shared.cabinService
    ) {
        self.businessType = businessType
        self.cabinService = cabinService
    }

    func reload() {
        requestID += 1
        let token = requestID
        currentPage = 1
        hasMore = false
        isLoading = true
        let businessType = businessType
        let service = cabinService
        let pageSize = pageSize
        Task {
            do {
                let page = try await service.appointments(
                    businessType: businessType,
                    pageNum: 1,
                    pageSize: pageSize
                )
                apply(page, pageNum: 1, append: false, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取使用记录失败"
                fail(message, token: token, append: false)
            }
        }
    }

    func loadMore() {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        let token = requestID
        let next = currentPage + 1
        let businessType = businessType
        let service = cabinService
        let pageSize = pageSize
        Task {
            do {
                let page = try await service.appointments(
                    businessType: businessType,
                    pageNum: next,
                    pageSize: pageSize
                )
                apply(page, pageNum: next, append: true, token: token)
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? "获取使用记录失败"
                fail(message, token: token, append: true)
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func apply(_ page: PaginatedCabinAppointmentData, pageNum: Int, append: Bool, token: Int) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        let rows = (page.records ?? []).map { record -> CabinAppointmentVO in
            var copy = record
            copy.businessType = businessType
            return copy
        }
        items = append ? items + rows : rows
        currentPage = pageNum
        let total = page.totalRecords ?? items.count
        hasMore = !rows.isEmpty && items.count < total
    }

    private func fail(_ message: String, token: Int, append: Bool) {
        guard token == requestID else { return }
        isLoading = false
        isLoadingMore = false
        if !append {
            items = []
            hasMore = false
        }
        errorMessage = message
    }
}

final class ExamUsageRecordsViewController: ServiceUsageRecordsViewController {

    init() {
        super.init(businessType: ServiceItemService.examBusinessType)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
