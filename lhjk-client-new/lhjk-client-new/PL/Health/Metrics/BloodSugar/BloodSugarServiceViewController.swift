import Combine
import UIKit
import SnapKit

final class BloodSugarServiceViewController: BaseViewController {

    private enum Row: Int, CaseIterable {
        case head, diabetes, entry, advice
    }

    private let viewModel = BloodSugarServiceViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let bannerView = BluetoothDeviceBannerView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func setupUI() {
        title = "血糖管理"
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        bannerView.onTap = { Router.shared.push("/me/devices") }
        tableView.backgroundColor = UIColor(hexString: "#F1F3F5")
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.register(BloodSugarServiceHeadCell.self, forCellReuseIdentifier: BloodSugarServiceHeadCell.reuseID)
        tableView.register(BloodSugarDiabetesTypeCell.self, forCellReuseIdentifier: BloodSugarDiabetesTypeCell.reuseID)
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
        viewModel.$record.combineLatest(viewModel.$stateText, viewModel.$dateText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
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
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    @objc private func openHistory() {
        Router.shared.push("/health/metrics/blood-sugar/history")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension BloodSugarServiceViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { Row.allCases.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Row(rawValue: indexPath.row) {
        case .head:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodSugarServiceHeadCell.reuseID, for: indexPath) as! BloodSugarServiceHeadCell
            cell.configure(record: viewModel.record, stateText: viewModel.stateText, dateText: viewModel.dateText)
            return cell
        case .diabetes:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodSugarDiabetesTypeCell.reuseID, for: indexPath) as! BloodSugarDiabetesTypeCell
            cell.configure(typeText: viewModel.diabetesTypeText)
            return cell
        case .entry:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodPressureRecordEntryCell.reuseID, for: indexPath) as! BloodPressureRecordEntryCell
            cell.onManualTap = { Router.shared.push("/health/metrics/blood-sugar/manual") }
            cell.onHistoryTap = { [weak self] in self?.openHistory() }
            return cell
        case .advice:
            let cell = tableView.dequeueReusableCell(withIdentifier: BloodPressureAdviceCell.reuseID, for: indexPath) as! BloodPressureAdviceCell
            cell.configure(title: viewModel.adviceTitle, content: viewModel.adviceContent, showsMore: viewModel.showsAdviceMore)
            cell.onMoreTap = { Router.shared.push("/health/metrics/blood-sugar/detail", params: [:]) }
            return cell
        case .none:
            return UITableViewCell()
        }
    }
}
