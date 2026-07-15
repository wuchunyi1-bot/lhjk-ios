import Combine
import UIKit
import SnapKit

/// 体重日志 Tab
final class WeightHistoryLogViewController: BaseViewController {

    private let viewModel = WeightHistoryLogViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let monthButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        monthButton.titleLabel?.font = .fdBodySemibold
        monthButton.setTitleColor(.fdText, for: .normal)
        monthButton.addTarget(self, action: #selector(chooseMonth), for: .touchUpInside)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WeightHistoryLogCell.self, forCellReuseIdentifier: WeightHistoryLogCell.reuseID)

        emptyLabel.text = "暂无数据"
        emptyLabel.font = .fdCaption
        emptyLabel.textColor = .fdMuted
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true

        view.addSubview(monthButton)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        monthButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(18)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(monthButton.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    override func bindViewModel() {
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !items.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$monthText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in self?.monthButton.setTitle(text, for: .normal) }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if !loading { self?.tableView.refreshControl?.endRefreshing() }
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in self?.showToast(message) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    func reloadData() { viewModel.refresh() }

    @objc private func handleRefresh() { viewModel.refresh() }

    @objc private func chooseMonth() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()

        let alert = UIAlertController(title: "选择月份", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 8),
        ])
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.viewModel.updateMonth(picker.date)
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension WeightHistoryLogViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WeightHistoryLogCell.reuseID, for: indexPath) as! WeightHistoryLogCell
        cell.configure(item: viewModel.items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        guard let monitorId = item.monitorId?.value else { return }
        Router.shared.push("/health/metrics/weight/detail", params: ["monitorId": monitorId])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        if offsetY > contentHeight - height - 80 {
            viewModel.loadMore()
        }
    }
}
