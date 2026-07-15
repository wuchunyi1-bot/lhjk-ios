import Combine
import UIKit
import SnapKit

/// 统计 Tab
final class BloodPressureHistoryStatsViewController: BaseViewController {

    private let viewModel = BloodPressureHistoryStatsViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let headCard = UIView()
    private let totalLabel = UILabel()
    private let normalLabel = UILabel()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()
    private let rateLabel = UILabel()
    private let progressView = UIView()
    private let progressFill = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        headCard.backgroundColor = .fdSurface
        headCard.layer.cornerRadius = 16

        [totalLabel, normalLabel, highLabel, lowLabel, rateLabel].forEach {
            $0.font = .fdCaption
            $0.textColor = .fdText2
            headCard.addSubview($0)
        }
        rateLabel.font = .fdBodySemibold
        rateLabel.textColor = .fdPrimary

        progressView.backgroundColor = .fdBg2
        progressView.layer.cornerRadius = 4
        progressFill.backgroundColor = .fdPrimary
        progressFill.layer.cornerRadius = 4
        progressView.addSubview(progressFill)
        headCard.addSubview(progressView)

        totalLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        normalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(8)
            make.leading.equalTo(totalLabel)
        }
        highLabel.snp.makeConstraints { make in
            make.top.equalTo(normalLabel.snp.bottom).offset(6)
            make.leading.equalTo(totalLabel)
        }
        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(highLabel.snp.bottom).offset(6)
            make.leading.equalTo(totalLabel)
        }
        rateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(totalLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        progressView.snp.makeConstraints { make in
            make.top.equalTo(lowLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(progressView).multipliedBy(0)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.register(BloodPressureStatsPeriodCell.self, forCellReuseIdentifier: BloodPressureStatsPeriodCell.reuseID)

        view.addSubview(headCard)
        view.addSubview(tableView)
        headCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headCard.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(260)
        }
    }

    override func bindViewModel() {
        viewModel.$statistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                guard let self else { return }
                let ninety = stats?.ninety
                self.totalLabel.text = "总次数：\(ninety?.total?.value ?? 0)"
                self.normalLabel.text = "正常：\(ninety?.normal?.value ?? 0)"
                self.highLabel.text = "偏高：\(ninety?.high?.value ?? 0)"
                self.lowLabel.text = "偏低：\(ninety?.low?.value ?? 0)"
                self.rateLabel.text = self.viewModel.complianceRateText
                self.progressFill.snp.remakeConstraints { make in
                    make.leading.top.bottom.equalToSuperview()
                    make.width.equalTo(self.progressView).multipliedBy(self.viewModel.complianceProgress)
                }
                self.tableView.reloadData()
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

    func reloadData() { viewModel.load() }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension BloodPressureHistoryStatsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BloodPressureStatsPeriodCell.reuseID, for: indexPath) as! BloodPressureStatsPeriodCell
        switch indexPath.row {
        case 0:
            cell.configure(title: "近7天", stats: viewModel.statistics?.seven)
        default:
            cell.configure(title: "近30天", stats: viewModel.statistics?.thirty)
        }
        return cell
    }
}
