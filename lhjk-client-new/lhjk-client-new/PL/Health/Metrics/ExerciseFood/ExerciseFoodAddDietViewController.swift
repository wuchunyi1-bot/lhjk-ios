import Combine
import UIKit
import SnapKit

final class ExerciseFoodAddDietViewController: BaseViewController {

    private let viewModel: ExerciseFoodAddDietViewModel
    private var cancellables = Set<AnyCancellable>()

    private let searchButton = UIButton(type: .system)
    private let leftTable = UITableView(frame: .zero, style: .plain)
    private let rightTable = UITableView(frame: .zero, style: .plain)
    private let bottomBar = ExerciseFoodAddBottomBar()

    init(timeType: Int?, dateString: String) {
        self.viewModel = ExerciseFoodAddDietViewModel(timeType: timeType, dateString: dateString)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "添加饮食"
        view.backgroundColor = .fdBg

        searchButton.setTitle("🔍 搜索食物", for: .normal)
        searchButton.titleLabel?.font = .fdBody
        searchButton.contentHorizontalAlignment = .left
        searchButton.backgroundColor = .fdSurface
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)

        leftTable.backgroundColor = UIColor(hexString: "#F5F2F3")
        leftTable.separatorStyle = .none
        leftTable.dataSource = self
        leftTable.delegate = self
        leftTable.register(ExerciseFoodCategoryCell.self, forCellReuseIdentifier: ExerciseFoodCategoryCell.reuseID)

        rightTable.backgroundColor = .fdSurface
        rightTable.separatorStyle = .none
        rightTable.dataSource = self
        rightTable.delegate = self
        rightTable.register(ExerciseFoodDefinitionCell.self, forCellReuseIdentifier: ExerciseFoodDefinitionCell.reuseID)

        bottomBar.onConfirm = { [weak self] in self?.viewModel.save() }

        view.addSubview(searchButton)
        view.addSubview(leftTable)
        view.addSubview(rightTable)
        view.addSubview(bottomBar)

        searchButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(56)
        }
        leftTable.snp.makeConstraints { make in
            make.top.equalTo(searchButton.snp.bottom)
            make.leading.bottom.equalToSuperview()
            make.width.equalTo(90)
        }
        rightTable.snp.makeConstraints { make in
            make.top.equalTo(searchButton.snp.bottom)
            make.leading.equalTo(leftTable.snp.trailing)
            make.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
    }

    override func bindViewModel() {
        viewModel.load()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSearchSelection(_:)),
            name: .exerciseFoodSearchDidSelect,
            object: nil
        )

        Publishers.CombineLatest(viewModel.$selectedItems, viewModel.$definitions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected, _ in
                guard let self else { return }
                self.bottomBar.update(selectedCount: selected.count, totalCalorie: self.viewModel.totalCalorie)
                self.rightTable.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.leftTable.reloadData() }
            .store(in: &cancellables)

        viewModel.$definitions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.rightTable.reloadData() }
            .store(in: &cancellables)

        viewModel.saveSucceeded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                NotificationCenter.default.post(name: .exerciseFoodRecordDidChange, object: nil)
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    @objc private func openSearch() {
        var params: [String: Any] = [
            "type": ExerciseFoodConstants.definitionTypeFood,
            "date": viewModel.dateString,
        ]
        if let timeType = viewModel.timeType {
            params["timeType"] = timeType
        }
        Router.shared.push("/health/metrics/exercise/search", params: params)
    }

    @objc private func handleSearchSelection(_ notification: Notification) {
        guard let item = notification.object as? ExerciseFoodDefinitionItem else { return }
        presentQuantityPicker(for: item)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func presentQuantityPicker(for item: ExerciseFoodDefinitionItem) {
        let record = item.toRecordItem()
        let sheet = ExerciseFoodQuantitySheet(item: record, definition: item, isSport: false)
        sheet.onSave = { [weak self] result in
            self?.viewModel.add(item: item, quantity: result.quantity, calorie: result.calorie)
        }
        present(sheet, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension ExerciseFoodAddDietViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView === leftTable ? viewModel.categories.count : viewModel.definitions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === leftTable {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ExerciseFoodCategoryCell.reuseID,
                for: indexPath
            ) as! ExerciseFoodCategoryCell
            let category = viewModel.categories[indexPath.row]
            cell.configure(title: category.name, selected: indexPath.row == viewModel.selectedCategoryIndex)
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseFoodDefinitionCell.reuseID,
            for: indexPath
        ) as! ExerciseFoodDefinitionCell
        let item = viewModel.definitions[indexPath.row]
        cell.configure(item: item, selected: viewModel.isSelected(item))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === leftTable {
            viewModel.selectCategory(at: indexPath.row)
            leftTable.reloadData()
            return
        }
        presentQuantityPicker(for: viewModel.definitions[indexPath.row])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView === rightTable else { return }
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)
    }
}
