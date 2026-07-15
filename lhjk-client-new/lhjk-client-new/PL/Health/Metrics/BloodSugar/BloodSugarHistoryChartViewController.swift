import Combine
import DGCharts
import UIKit
import SnapKit

final class BloodSugarHistoryChartViewController: BaseViewController {

    private let viewModel = BloodSugarHistoryChartViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let segmented = UISegmentedControl(items: ["7天", "30天", "90天"])
    private let mealFilterStack = UIStackView()
    private let titleLabel = UILabel()
    private let chartView = LineChartView()
    private var mealButtons: [UIButton] = []

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        let filterCard = UIView()
        filterCard.backgroundColor = .fdSurface
        filterCard.layer.cornerRadius = 16

        mealFilterStack.axis = .vertical
        mealFilterStack.spacing = 8

        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText

        let chartCard = UIView()
        chartCard.backgroundColor = .fdSurface
        chartCard.layer.cornerRadius = 16
        chartView.applyFundeStyle()
        chartCard.addSubview(titleLabel)
        chartCard.addSubview(chartView)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(220)
        }

        filterCard.addSubview(mealFilterStack)
        mealFilterStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        view.addSubview(segmented)
        view.addSubview(filterCard)
        view.addSubview(chartCard)
        segmented.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(32)
        }
        filterCard.snp.makeConstraints { make in
            make.top.equalTo(segmented.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        chartCard.snp.makeConstraints { make in
            make.top.equalTo(filterCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    override func bindViewModel() {
        viewModel.$mealTypes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] types in self?.reloadMealFilters(types) }
            .store(in: &cancellables)

        viewModel.$points.combineLatest(viewModel.$chartTitle)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] points, title in
                self?.titleLabel.text = title
                self?.reloadChart(points)
            }
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

    @objc private func mealTapped(_ sender: UIButton) {
        viewModel.selectedMealIndex = sender.tag
        mealButtons.enumerated().forEach { index, button in
            let selected = index == sender.tag
            button.isSelected = selected
            button.layer.borderColor = (selected ? UIColor(hexString: "#FF406F") : UIColor.clear).cgColor
        }
        reloadData()
    }

    private func reloadMealFilters(_ types: [BloodSugarMealType]) {
        mealFilterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        mealButtons.removeAll()
        let rowWidth = 4
        var row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 8
        for (index, type) in types.enumerated() {
            if index > 0 && index % rowWidth == 0 {
                mealFilterStack.addArrangedSubview(row)
                row = UIStackView()
                row.axis = .horizontal
                row.distribution = .fillEqually
                row.spacing = 8
            }
            let button = UIButton(type: .custom)
            button.setTitle(type.name, for: .normal)
            button.titleLabel?.font = .fdCaption
            button.layer.cornerRadius = 16
            button.layer.borderWidth = 1
            button.tag = index
            button.addTarget(self, action: #selector(mealTapped(_:)), for: .touchUpInside)
            button.setTitleColor(.fdSubtext, for: .normal)
            button.setTitleColor(UIColor(hexString: "#FF406F"), for: .selected)
            button.backgroundColor = UIColor(hexString: "#F5F2F3")
            if index == viewModel.selectedMealIndex {
                button.isSelected = true
                button.layer.borderColor = UIColor(hexString: "#FF406F").cgColor
            }
            row.addArrangedSubview(button)
            mealButtons.append(button)
        }
        if row.arrangedSubviews.isEmpty == false {
            mealFilterStack.addArrangedSubview(row)
        }
    }

    private func reloadChart(_ points: [BloodSugarMonitorDay]) {
        let labels = points.map(\.chartLabel)
        let values = points.compactMap(\.chartValue)
        let entries = values.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }
        let set = LineChartView.makeFundeDataSet(
            entries: entries,
            label: "我的血糖",
            color: UIColor(hexString: "#FF7C9C"),
            fillAlpha: 0.25
        )
        set.drawCirclesEnabled = values.count == 1
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.data = LineChartData(dataSets: [set])
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
