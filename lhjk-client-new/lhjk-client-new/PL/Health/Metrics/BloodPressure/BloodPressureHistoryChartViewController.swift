import Combine
import DGCharts
import UIKit
import SnapKit

/// 趋势图 Tab
final class BloodPressureHistoryChartViewController: BaseViewController {

    private let viewModel = BloodPressureHistoryChartViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let segmented = UISegmentedControl(items: ["7天", "30天", "90天"])
    private let bpChartView = LineChartView()
    private let hrChartView = LineChartView()

    override func setupUI() {
        view.backgroundColor = UIColor(hexString: "#F1F3F5")

        let scroll = UIScrollView()
        let content = UIView()
        view.addSubview(scroll)
        scroll.addSubview(content)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        content.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        let bpCard = chartCard(title: "血压趋势", chart: bpChartView)
        let hrCard = chartCard(title: "心率趋势", chart: hrChartView)

        content.addSubview(segmented)
        content.addSubview(bpCard)
        content.addSubview(hrCard)

        segmented.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(32)
        }
        bpCard.snp.makeConstraints { make in
            make.top.equalTo(segmented.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(260)
        }
        hrCard.snp.makeConstraints { make in
            make.top.equalTo(bpCard.snp.bottom).offset(12)
            make.leading.trailing.equalTo(bpCard)
            make.height.equalTo(260)
            make.bottom.equalToSuperview().offset(-20)
        }

        [bpChartView, hrChartView].forEach { $0.applyFundeStyle() }
    }

    override func bindViewModel() {
        viewModel.$points
            .receive(on: DispatchQueue.main)
            .sink { [weak self] points in self?.reloadCharts(points) }
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

    @objc private func periodChanged() {
        viewModel.selectedPeriodIndex = segmented.selectedSegmentIndex
        reloadData()
    }

    private func reloadCharts(_ points: [BloodPressureChartPoint]) {
        let labels = points.map(\.chartLabel)
        let sys = points.compactMap { $0.highBloodPressure?.value }.map { Double($0) }
        let dia = points.compactMap { $0.lowBloodPressure?.value }.map { Double($0) }
        let hr = points.compactMap { $0.heartRate?.value }.map { Double($0) }

        bpChartView.data = makeLineData(
            chartView: bpChartView,
            labels: labels,
            sets: [
                ("收缩压", sys, UIColor(hexString: "#FF7C9C")),
                ("舒张压", dia, UIColor(hexString: "#FFB25C")),
            ]
        )
        hrChartView.data = makeLineData(
            chartView: hrChartView,
            labels: labels,
            sets: [("心率", hr, UIColor(hexString: "#FF7C9C"))]
        )
    }

    private func makeLineData(
        chartView: LineChartView,
        labels: [String],
        sets: [(String, [Double], UIColor)]
    ) -> LineChartData {
        var dataSets: [LineChartDataSet] = []
        for (name, values, color) in sets {
            let entries = values.enumerated().map { ChartDataEntry(x: Double($0.offset), y: $0.element) }
            let set = LineChartView.makeFundeDataSet(entries: entries, label: name, color: color)
            set.drawCirclesEnabled = values.count == 1
            dataSets.append(set)
        }
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        return LineChartData(dataSets: dataSets)
    }

    private func chartCard(title: String, chart: LineChartView) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16

        let label = UILabel()
        label.text = title
        label.font = .fdBodySemibold
        label.textColor = .fdText

        card.addSubview(label)
        card.addSubview(chart)
        label.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(14)
        }
        chart.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        return card
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
