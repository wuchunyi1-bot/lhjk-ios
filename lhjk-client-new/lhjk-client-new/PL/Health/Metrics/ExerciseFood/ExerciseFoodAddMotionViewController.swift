import Combine
import UIKit
import SnapKit

final class ExerciseFoodAddMotionViewController: BaseViewController {

    private let viewModel: ExerciseFoodAddMotionViewModel
    private var cancellables = Set<AnyCancellable>()

    private let searchButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let bottomBar = ExerciseFoodAddBottomBar()

    init(dateString: String) {
        self.viewModel = ExerciseFoodAddMotionViewModel(dateString: dateString)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func setupUI() {
        title = "添加运动"
        view.backgroundColor = .fdBg

        searchButton.setTitle("🔍 搜索运动", for: .normal)
        searchButton.titleLabel?.font = .fdBody
        searchButton.contentHorizontalAlignment = .left
        searchButton.backgroundColor = .fdSurface
        searchButton.addTarget(self, action: #selector(openSearch), for: .touchUpInside)

        tableView.backgroundColor = .fdSurface
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ExerciseFoodDefinitionCell.self, forCellReuseIdentifier: ExerciseFoodDefinitionCell.reuseID)

        bottomBar.onConfirm = { [weak self] in self?.viewModel.save() }

        view.addSubview(searchButton)
        view.addSubview(tableView)
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
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchButton.snp.bottom)
            make.leading.trailing.equalToSuperview()
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

        viewModel.$selectedItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                guard let self else { return }
                self.bottomBar.update(selectedCount: selected.count, totalCalorie: self.viewModel.totalCalorie)
                self.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$definitions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
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
        Router.shared.push("/health/metrics/exercise/search", params: [
            "type": ExerciseFoodConstants.definitionTypeSport,
            "date": viewModel.dateString,
        ])
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
        let sheet = ExerciseFoodQuantitySheet(item: record, definition: item, isSport: true)
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

extension ExerciseFoodAddMotionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.definitions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseFoodDefinitionCell.reuseID,
            for: indexPath
        ) as! ExerciseFoodDefinitionCell
        let item = viewModel.definitions[indexPath.row]
        cell.configure(item: item, selected: viewModel.isSelected(item))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentQuantityPicker(for: viewModel.definitions[indexPath.row])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)
    }
}
