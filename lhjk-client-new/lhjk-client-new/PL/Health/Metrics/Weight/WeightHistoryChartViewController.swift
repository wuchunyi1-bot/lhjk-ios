import Combine
import DGCharts
import UIKit
import SnapKit

/// 体重趋势图 Tab
final class WeightHistoryChartViewController: BaseViewController {

    private let viewModel = WeightHistoryChartViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let titleLabel = UILabel()
    private let legendStack = UIStackView()
    private let chartView = LineChartView()

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        let chartCard = UIView()
        chartCard.backgroundColor = .fdSurface
        chartCard.layer.cornerRadius = 16

        titleLabel.font = .fdBodySemibold
        titleLabel.textColor = .fdText
        titleLabel.text = "体重趋势"

        legendStack.axis = .horizontal
        legendStack.spacing = 16
        legendStack.distribution = .fillEqually
        [
            ("正常", "#5AD480"),
            ("偏低", "#FE6186"),
            ("偏高", "#FFB25C"),
        ].forEach { title, hex in
            let item = legendItem(title: title, colorHex: hex)
            legendStack.addArrangedSubview(item)
        }

        chartView.applyFundeStyle()
        chartView.legend.enabled = false

        chartCard.addSubview(titleLabel)
        chartCard.addSubview(legendStack)
        chartCard.addSubview(chartView)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        legendStack.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(20)
        }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(legendStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(260)
        }

        view.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    override func bindViewModel() {
        viewModel.$points
            .receive(on: DispatchQueue.main)
            .sink { [weak self] points in self?.reloadChart(points) }
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

    private func reloadChart(_ points: [WeightHistoryDataPoint]) {
        let validPoints = points.filter { $0.weightValue != nil }
        let labels = validPoints.map(\.chartLabel)
        let entries = validPoints.enumerated().map { index, point in
            ChartDataEntry(x: Double(index), y: point.weightValue!)
        }

        let set = LineChartDataSet(entries: entries, label: "体重")
        set.mode = .linear
        set.lineWidth = 2
        set.drawValuesEnabled = false
        set.drawCirclesEnabled = true
        set.circleRadius = 4
        set.colors = [UIColor(hexString: "#5AD480")]
        set.circleColors = validPoints.map { UIColor(hexString: $0.pointColorHex) }

        if let firstMin = validPoints.compactMap(\.minRange).first,
           let firstMax = validPoints.compactMap(\.maxRange).first {
            let minLine = ChartLimitLine(limit: firstMin, label: "推荐下限")
            minLine.lineColor = UIColor(hexString: "#FE6186").withAlphaComponent(0.5)
            minLine.lineDashLengths = [4, 4]
            let maxLine = ChartLimitLine(limit: firstMax, label: "推荐上限")
            maxLine.lineColor = UIColor(hexString: "#FFB25C").withAlphaComponent(0.5)
            maxLine.lineDashLengths = [4, 4]
            chartView.leftAxis.removeAllLimitLines()
            chartView.leftAxis.addLimitLine(minLine)
            chartView.leftAxis.addLimitLine(maxLine)
        }

        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.data = LineChartData(dataSet: set)
    }

    private func legendItem(title: String, colorHex: String) -> UIView {
        let dot = UIView()
        dot.backgroundColor = UIColor(hexString: colorHex)
        dot.layer.cornerRadius = 4
        let label = UILabel()
        label.text = title
        label.font = .fdMicro
        label.textColor = .fdSubtext
        let stack = UIStackView(arrangedSubviews: [dot, label])
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        dot.snp.makeConstraints { $0.size.equalTo(8) }
        return stack
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
