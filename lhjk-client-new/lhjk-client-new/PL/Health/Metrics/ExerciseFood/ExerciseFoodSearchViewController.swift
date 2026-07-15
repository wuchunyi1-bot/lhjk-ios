import Combine
import UIKit
import SnapKit

final class ExerciseFoodSearchViewController: BaseViewController {

    private let viewModel: ExerciseFoodSearchViewModel
    private var cancellables = Set<AnyCancellable>()

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(type: Int) {
        self.viewModel = ExerciseFoodSearchViewModel(type: type)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = viewModel.type == ExerciseFoodConstants.definitionTypeSport ? "搜索运动" : "搜索食物"
        view.backgroundColor = .fdBg

        searchBar.placeholder = viewModel.type == ExerciseFoodConstants.definitionTypeSport ? "运动名称" : "食物名称"
        searchBar.delegate = self

        tableView.backgroundColor = .fdSurface
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(ExerciseFoodDefinitionCell.self, forCellReuseIdentifier: ExerciseFoodDefinitionCell.reuseID)

        emptyLabel.text = "暂无结果"
        emptyLabel.font = .fdCaption
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }
    }

    override func bindViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !items.isEmpty
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension ExerciseFoodSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseFoodDefinitionCell.reuseID,
            for: indexPath
        ) as! ExerciseFoodDefinitionCell
        cell.configure(item: viewModel.items[indexPath.row], selected: false)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        NotificationCenter.default.post(name: .exerciseFoodSearchDidSelect, object: item)
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)
    }
}

extension ExerciseFoodSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.keyword = searchBar.text ?? ""
        searchBar.resignFirstResponder()
        viewModel.search()
    }
}
