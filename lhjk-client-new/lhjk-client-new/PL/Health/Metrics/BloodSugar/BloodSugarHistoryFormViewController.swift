import Combine
import UIKit
import SnapKit

final class BloodSugarHistoryFormViewController: BaseViewController {

    private let viewModel = BloodSugarHistoryFormViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let segmented = UISegmentedControl(items: ["7天", "30天", "90天"])
    private let statsCard = UIView()
    private let totalLabel = UILabel()
    private let normalLabel = UILabel()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()
    private let headerRow = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        statsCard.backgroundColor = .fdSurface
        statsCard.layer.cornerRadius = 16
        [totalLabel, normalLabel, highLabel, lowLabel].forEach {
            $0.font = .fdCaption
            $0.textColor = .fdText2
            statsCard.addSubview($0)
        }
        totalLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        normalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(6)
            make.leading.equalTo(totalLabel)
        }
        highLabel.snp.makeConstraints { make in
            make.top.equalTo(normalLabel.snp.bottom).offset(6)
            make.leading.equalTo(totalLabel)
        }
        lowLabel.snp.makeConstraints { make in
            make.top.equalTo(highLabel.snp.bottom).offset(6)
            make.leading.equalTo(totalLabel)
            make.bottom.equalToSuperview().offset(-14)
        }

        headerRow.axis = .horizontal
        headerRow.distribution = .fillEqually
        headerRow.backgroundColor = UIColor(hexString: "#FAFAFA")

        tableView.backgroundColor = .fdSurface
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.dataSource = self
        tableView.register(BloodSugarFormDayCell.self, forCellReuseIdentifier: BloodSugarFormDayCell.reuseID)

        view.addSubview(segmented)
        view.addSubview(statsCard)
        view.addSubview(headerRow)
        view.addSubview(tableView)

        segmented.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(32)
        }
        statsCard.snp.makeConstraints { make in
            make.top.equalTo(segmented.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        headerRow.snp.makeConstraints { make in
            make.top.equalTo(statsCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(44)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func bindViewModel() {
        viewModel.$totalText.combineLatest(viewModel.$normalText, viewModel.$highText, viewModel.$lowText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total, normal, high, low in
                self?.totalLabel.text = "总次数：\(total)"
                self?.normalLabel.text = "正常：\(normal)"
                self?.highLabel.text = "偏高：\(high)"
                self?.lowLabel.text = "偏低：\(low)"
            }
            .store(in: &cancellables)

        viewModel.$mealTypes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in
                self?.reloadHeader(titles: types.compactMap(\.name))
            }
            .store(in: &cancellables)

        viewModel.$days
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.toastMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    func reloadData() { viewModel.load() }

    @objc private func periodChanged() {
        viewModel.selectedPeriodIndex = segmented.selectedSegmentIndex
        reloadData()
    }

    private func reloadHeader(titles: [String]) {
        headerRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let dateLabel = UILabel()
        dateLabel.text = "日期"
        dateLabel.font = .fdCaptionSemibold
        dateLabel.textAlignment = .center
        dateLabel.snp.makeConstraints { $0.width.equalTo(56) }
        headerRow.addArrangedSubview(dateLabel)
        for title in titles {
            let label = UILabel()
            label.text = title
            label.font = .fdMicroSemibold
            label.textAlignment = .center
            label.textColor = .fdSubtext
            headerRow.addArrangedSubview(label)
        }
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}

extension BloodSugarHistoryFormViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.days.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BloodSugarFormDayCell.reuseID, for: indexPath) as! BloodSugarFormDayCell
        let day = viewModel.days[indexPath.row]
        cell.configure(date: day.formattedDate, values: viewModel.rowValues(for: day), striped: indexPath.row % 2 != 0)
        return cell
    }
}
