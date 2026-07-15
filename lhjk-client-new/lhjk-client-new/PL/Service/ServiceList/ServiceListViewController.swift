import UIKit
import SnapKit
import Combine

/// 套餐选择页 — 双 TableView 布局
/// 参考 funde-client: ServiceListView.vue（左栏健康管理类目 + 右栏套包 API）
final class ServiceListViewController: BaseViewController {

    private let viewModel: ServiceListViewModel
    private var cancellables = Set<AnyCancellable>()

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
        tv.register(PackageHeaderCell.self, forCellReuseIdentifier: PackageHeaderCell.reuseID)
        tv.register(PackageCardCell.self, forCellReuseIdentifier: PackageCardCell.reuseID)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 1
        return tv
    }()

    init(productCode: String) {
        self.viewModel = ServiceListViewModel(routeCode: productCode)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择套餐"
        viewModel.load()
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(leftTable)
        view.addSubview(rightTable)

        leftTable.snp.makeConstraints { make in
            make.top.leading.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(88)
        }
        rightTable.snp.makeConstraints { make in
            make.top.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
            make.leading.equalTo(leftTable.snp.trailing)
        }
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
                self?.rightTable.reloadData()
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
        let count = viewModel.packages.count
        return count == 0 ? 2 : count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryNavCell.reuseID, for: indexPath) as! CategoryNavCell
            let category = viewModel.categories[indexPath.row]
            cell.configure(title: category.title, active: category.id == viewModel.activeCategoryId)
            return cell
        }

        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: PackageHeaderCell.reuseID, for: indexPath) as! PackageHeaderCell
            if let category = viewModel.activeCategory {
                cell.configure(categoryTitle: category.title, description: category.description)
            }
            return cell
        }

        if viewModel.packages.isEmpty {
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            let label = UILabel()
            label.text = "🚧\n套餐即将开放\n敬请期待"
            label.font = .fdBody
            label.textColor = .fdSubtext
            label.textAlignment = .center
            label.numberOfLines = 0
            cell.contentView.addSubview(label)
            label.snp.makeConstraints { $0.center.equalToSuperview() }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: PackageCardCell.reuseID, for: indexPath) as! PackageCardCell
        let pkg = viewModel.packages[indexPath.row - 1]
        cell.configure(pkg)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.tag == 0 {
            let category = viewModel.categories[indexPath.row]
            viewModel.selectCategory(id: category.id)
            rightTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        } else if indexPath.row > 0, !viewModel.packages.isEmpty {
            let pkg = viewModel.packages[indexPath.row - 1]
            Router.shared.push("/services/pkg", params: ["id": pkg.id])
        }
    }
}
