import Combine
import UIKit
import SnapKit

/// 体重服务首页 — 对齐源项目 `ADWeightServiceController`
final class WeightServiceViewController: BaseViewController {

    private enum Row: Int, CaseIterable {
        case head, entry, advice
    }

    private let viewModel = WeightServiceViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let bannerView = BluetoothDeviceBannerView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func setupUI() {
        title = "体重服务"
        view.backgroundColor = .fdBg

        bannerView.onTap = { [weak self] in
            Router.shared.push("/me/devices")
        }

        tableView.backgroundColor = .fdBg
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WeightServiceHeadCell.self, forCellReuseIdentifier: WeightServiceHeadCell.reuseID)
        tableView.register(BloodPressureRecordEntryCell.self, forCellReuseIdentifier: BloodPressureRecordEntryCell.reuseID)
        tableView.register(BloodPressureAdviceCell.self, forCellReuseIdentifier: BloodPressureAdviceCell.reuseID)

        view.addSubview(bannerView)
        view.addSubview(tableView)
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.$record
            .combineLatest(viewModel.$stateText, viewModel.$dateText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.$adviceTitle
            .combineLatest(viewModel.$adviceContent, viewModel.$showsAdviceMore)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadRows(at: [IndexPath(row: Row.advice.rawValue, section: 0)], with: .none)
            }
            .store(in: &cancellables)

        viewModel.$equipment
            .receive(on: DispatchQueue.main)
            .sink { [weak self] equipment in
                let state: BluetoothDeviceBannerView.State = equipment == nil ? .unbound : .connected
                self?.bannerView.configure(equipment: equipment, state: state)
            }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in self?.showToast(message) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    @objc private func openHistory() {
        Router.shared.push("/health/metrics/weight/history")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension WeightServiceViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Row.allCases.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Row(rawValue: indexPath.row) {
        case .head:
            let cell = tableView.dequeueReusableCell(withIdentifier: WeightServiceHeadCell.reuseID, for: indexPath) as! WeightServiceHeadCell
            cell.configure(record: viewModel.record, stateText: viewModel.stateText, dateText: viewModel.dateText)
            return cell
        case .entry:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodPressureRecordEntryCell.reuseID, for: indexPath) as! BloodPressureRecordEntryCell
            cell.onManualTap = { [weak self] in
                Router.shared.push("/health/metrics/weight/manual")
            }
            cell.onHistoryTap = { [weak self] in self?.openHistory() }
            return cell
        case .advice:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodPressureAdviceCell.reuseID, for: indexPath) as! BloodPressureAdviceCell
            cell.configure(title: viewModel.adviceTitle, content: viewModel.adviceContent, showsMore: viewModel.showsAdviceMore)
            cell.onMoreTap = { [weak self] in
                Router.shared.push("/health/metrics/weight/detail", params: [:])
            }
            return cell
        case .none:
            return UITableViewCell()
        }
    }
}
