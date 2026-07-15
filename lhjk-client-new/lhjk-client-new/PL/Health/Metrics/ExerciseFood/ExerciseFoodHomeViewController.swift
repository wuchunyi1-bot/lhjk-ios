import Combine
import UIKit
import SnapKit

/// 饮食运动首页 — 对齐 `ADFoodRecordManagerController`
final class ExerciseFoodHomeViewController: BaseViewController {

    private let viewModel = ExerciseFoodHomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let dateBar = ExerciseFoodDateBarView()
    private let headerView = ExerciseFoodCalorieHeaderView()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let bottomBar = ExerciseFoodBottomBarView()
    private let emptyLabel = UILabel()

    override func setupUI() {
        title = "饮食运动"
        view.backgroundColor = UIColor(hexString: "#F9F8F8")

        emptyLabel.text = "暂无记录"
        emptyLabel.font = .fdCaption
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ExerciseFoodRecordCell.self, forCellReuseIdentifier: ExerciseFoodRecordCell.reuseID)
        tableView.register(
            ExerciseFoodSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: ExerciseFoodSectionHeaderView.reuseID
        )

        view.addSubview(dateBar)
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(bottomBar)
        view.addSubview(emptyLabel)

        dateBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        headerView.snp.makeConstraints { make in
            make.top.equalTo(dateBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        bottomBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        dateBar.onPrevious = { [weak self] in self?.viewModel.shiftDay(by: -1) }
        dateBar.onNext = { [weak self] in self?.viewModel.shiftDay(by: 1) }
        dateBar.onPickDate = { [weak self] in self?.pickDate() }
        bottomBar.onAction = { [weak self] index in self?.handleBottomAction(index) }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleChangeNotification),
            name: .exerciseFoodRecordDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func bindViewModel() {
        viewModel.$summary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in self?.headerView.configure(summary: summary) }
            .store(in: &cancellables)

        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !sections.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$dateText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.dateBar.setDateText(text) }
            .store(in: &cancellables)

        viewModel.$selectedDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dateBar.setNextEnabled(self?.viewModel.canGoNext ?? false)
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    @objc private func handleChangeNotification() {
        viewModel.load()
    }

    private func pickDate() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.maximumDate = Date()
        picker.preferredDatePickerStyle = .wheels
        picker.date = viewModel.selectedDate
        let alert = UIAlertController(title: "选择日期", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 8),
        ])
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.viewModel.setDate(picker.date)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func handleBottomAction(_ index: Int) {
        let date = viewModel.dateString
        switch index {
        case 0:
            Router.shared.push("/health/metrics/exercise/add-diet", params: ["timeType": 1, "date": date])
        case 1:
            Router.shared.push("/health/metrics/exercise/add-diet", params: ["timeType": 3, "date": date])
        case 2:
            Router.shared.push("/health/metrics/exercise/add-diet", params: ["timeType": 5, "date": date])
        case 3:
            let alert = UIAlertController(title: "选择加餐", message: nil, preferredStyle: .actionSheet)
            [(2, "上午加餐"), (4, "下午加餐"), (6, "晚上加餐")].forEach { type, title in
                alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                    Router.shared.push("/health/metrics/exercise/add-diet", params: ["timeType": type, "date": date])
                })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        default:
            Router.shared.push("/health/metrics/exercise/add-motion", params: ["date": date])
        }
    }

    private func presentEditor(item: ExerciseFoodRecordItem, isSport: Bool) {
        let sheet = ExerciseFoodQuantitySheet(item: item, isSport: isSport, allowsDelete: true)
        sheet.onSave = { [weak self] result in
            self?.viewModel.update(item: item, quantity: result.quantity, calorie: result.calorie, isSport: isSport)
        }
        sheet.onDelete = { [weak self] in
            self?.viewModel.delete(item: item)
        }
        present(sheet, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension ExerciseFoodHomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { viewModel.sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ExerciseFoodSectionHeaderView.reuseID
        ) as! ExerciseFoodSectionHeaderView
        let sectionModel = viewModel.sections[section]
        header.configure(title: sectionModel.title, hint: sectionModel.hint, consume: sectionModel.consume)
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 62 }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ExerciseFoodRecordCell.reuseID,
            for: indexPath
        ) as! ExerciseFoodRecordCell
        cell.configure(item: viewModel.sections[indexPath.section].items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = viewModel.sections[indexPath.section]
        let item = section.items[indexPath.row]
        if item.isPhotoCustomRecord {
            showToast("拍照记录编辑功能即将上线")
            return
        }
        presentEditor(item: item, isSport: section.isSport)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let section = viewModel.sections[indexPath.section]
        let item = section.items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, done in
            self?.viewModel.delete(item: item)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
