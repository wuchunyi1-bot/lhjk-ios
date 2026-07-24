import UIKit
import SnapKit
import Combine

/// 套餐选择页 — 对齐 funde-client `ServiceListView.vue`
final class ServiceListViewController: BaseViewController {

    private let viewModel: ServiceListViewModel
    private var cancellables = Set<AnyCancellable>()

    private let institutionCard = ServiceInstitutionCardView()
    private let layoutContainer = UIView()
    private let topDivider = UIView()

    private lazy var leftTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg2
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(CategoryNavCell.self, forCellReuseIdentifier: CategoryNavCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 0
        return tv
    }()

    private lazy var rightTable: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(PackageCardCell.self, forCellReuseIdentifier: PackageCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 1
        return tv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        return spinner
    }()

    init(productCode: String) {
        self.viewModel = ServiceListViewModel(routeCode: productCode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择套餐"
        setupNavigationItems()
        institutionCard.configure(viewModel.institution)
        viewModel.load()
    }

    private func setupNavigationItems() {
        let searchItem = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(openSearch)
        )
        let cartItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(openCart)
        )
        navigationItem.rightBarButtonItems = [cartItem, searchItem]
    }

    @objc private func openSearch() {
        Router.shared.push("/services/search", params: ["hospitalId": viewModel.searchHospitalId])
    }

    @objc private func openCart() {
        Router.shared.push("/services/cart")
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        topDivider.backgroundColor = .fdBorder

        view.addSubview(institutionCard)
        view.addSubview(topDivider)
        view.addSubview(layoutContainer)
        layoutContainer.addSubview(leftTable)
        layoutContainer.addSubview(rightTable)
        view.addSubview(loadingIndicator)

        institutionCard.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
        }
        topDivider.snp.makeConstraints {
            $0.top.equalTo(institutionCard.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(1)
        }
        layoutContainer.snp.makeConstraints {
            $0.top.equalTo(topDivider.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        leftTable.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(78)
        }
        rightTable.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(leftTable.snp.trailing)
        }
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(rightTable)
        }

        institutionCard.onSwitchTap = { [weak self] in
            guard let self else { return }
            var params: [String: Any] = ["source": "services"]
            if let id = InstitutionSelectionStore.shared.selected?.id {
                params["selectedId"] = id
            }
            Router.shared.push("/services/institution", params: params)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        institutionCard.configure(viewModel.institution)
    }

    override func bindViewModel() {
        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                guard let self else { return }
                self.leftTable.reloadData()
                if let id = self.viewModel.activeCategoryId,
                   let idx = categories.firstIndex(where: { $0.id == id }) {
                    self.leftTable.scrollToRow(
                        at: IndexPath(row: idx, section: 0),
                        at: .middle,
                        animated: false
                    )
                }
            }
            .store(in: &cancellables)

        viewModel.$packages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rightTable.reloadData() }
            .store(in: &cancellables)

        viewModel.$activeCategoryId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.leftTable.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isLoadingPackages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$institution
            .receive(on: DispatchQueue.main)
            .sink { [weak self] display in
                self?.institutionCard.configure(display)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension ServiceListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 {
            return viewModel.categories.count
        }
        return viewModel.packages.isEmpty ? 1 : viewModel.packages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: CategoryNavCell.reuseID,
                for: indexPath
            ) as! CategoryNavCell
            let category = viewModel.categories[indexPath.row]
            cell.configure(title: category.title, active: category.id == viewModel.activeCategoryId)
            return cell
        }

        if viewModel.packages.isEmpty {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            let label = UILabel()
            label.text = "暂无套餐"
            label.font = .fdBody
            label.textColor = .fdSubtext
            label.textAlignment = .center
            cell.contentView.addSubview(label)
            label.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.leading.trailing.equalToSuperview().inset(24)
                $0.top.bottom.equalToSuperview().inset(48)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: PackageCardCell.reuseID,
            for: indexPath
        ) as! PackageCardCell
        cell.configure(
            viewModel.packages[indexPath.row],
            categoryServiceId: viewModel.activeCategoryId
        )
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 0 { return 52 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            let category = viewModel.categories[indexPath.row]
            viewModel.selectCategory(id: category.id)
            rightTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        } else if !viewModel.packages.isEmpty {
            let pkg = viewModel.packages[indexPath.row]
            Router.shared.push(
                "/services/pkg",
                params: pkg.packageDetailRouteParams(categoryServiceId: viewModel.activeCategoryId)
            )
        }
    }
}
