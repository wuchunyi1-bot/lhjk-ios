import Combine
import UIKit
import SnapKit
import DGCharts

/// 血压管理（Funde 风格 UI + Angel Doctor API）
final class BloodPressureViewController: BaseViewController {

    private let viewModel = BloodPressureFundeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let segment = UISegmentedControl(items: ["日", "周", "月"])
    private let chartView = LineChartView()
    private let statsStack = UIStackView()
    private let recordsHost = UIView()
    private var chartCard: UIView!
    private var recordsContainer: UIView!

    override func setupUI() {
        title = "血压管理"
        view.backgroundColor = .fdBg

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "历史", style: .plain, target: self, action: #selector(openHistory)),
            UIBarButtonItem(title: "添加", style: .plain, target: self, action: #selector(addRecord)),
        ]

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let pad: CGFloat = 16
        segment.selectedSegmentIndex = viewModel.periodIndex
        segment.selectedSegmentTintColor = .fdPrimary
        segment.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        segment.backgroundColor = .fdBg2
        segment.addTarget(self, action: #selector(periodChanged(_:)), for: .valueChanged)

        chartCard = buildChartCard()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 10

        recordsContainer = buildRecordsSection()

        [segment, chartCard, statsStack, recordsContainer].forEach(contentView.addSubview)
        segment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(36)
        }
        chartCard.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(220)
        }
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(chartCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
        }
        recordsContainer.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    override func bindViewModel() {
        viewModel.$chartPoints
            .combineLatest(viewModel.$logItems)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.reloadUI() }
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

    private func reloadUI() {
        reloadChart()
        reloadStats()
        reloadRecords()
    }

    private func buildChartCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()

        let title = UILabel()
        title.text = "血压趋势"
        title.font = .fdBodySemibold
        title.textColor = .fdText

        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 16
        for (color, label) in [(UIColor(hexString: "#FF7A50"), "收缩压"), (UIColor(hexString: "#6B9FE4"), "舒张压")] {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
            let lbl = UILabel(); lbl.text = label; lbl.font = .fdCaption; lbl.textColor = .fdSubtext
            legendStack.addArrangedSubview(dot)
            dot.snp.makeConstraints { $0.size.equalTo(8) }
            legendStack.addArrangedSubview(lbl)
        }

        chartView.applyFundeStyle()
        chartView.legend.enabled = false

        card.addSubview(title)
        card.addSubview(legendStack)
        card.addSubview(chartView)
        title.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legendStack.snp.makeConstraints { $0.top.equalToSuperview().inset(16); $0.trailing.equalToSuperview().offset(-16) }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        return card
    }

    private func reloadChart() {
        let points = viewModel.chartPoints
        let sysEntries = points.enumerated().compactMap { index, point -> ChartDataEntry? in
            guard let v = point.highBloodPressure?.value else { return nil }
            return ChartDataEntry(x: Double(index), y: Double(v))
        }
        let diaEntries = points.enumerated().compactMap { index, point -> ChartDataEntry? in
            guard let v = point.lowBloodPressure?.value else { return nil }
            return ChartDataEntry(x: Double(index), y: Double(v))
        }
        let sysSet = LineChartView.makeFundeDataSet(entries: sysEntries, label: "收缩压", color: UIColor(hexString: "#FF7A50"), fillAlpha: 0.06)
        let diaSet = LineChartView.makeFundeDataSet(entries: diaEntries, label: "舒张压", color: UIColor(hexString: "#6B9FE4"), fillAlpha: 0.06)
        chartView.data = LineChartData(dataSets: [sysSet, diaSet])
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: points.map(\.chartLabel))
        chartView.xAxis.granularity = 1
        chartView.leftAxis.axisMinimum = 60
        chartView.leftAxis.axisMaximum = 160
        chartView.notifyDataSetChanged()
    }

    private func reloadStats() {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let items: [(String, String, String)] = [
            ("平均收缩压", viewModel.avgSystolic.map(String.init) ?? "--", "mmHg"),
            ("平均舒张压", viewModel.avgDiastolic.map(String.init) ?? "--", "mmHg"),
            ("平均心率", viewModel.avgHeartRate.map(String.init) ?? "--", "bpm"),
        ]
        for (label, value, unit) in items {
            statsStack.addArrangedSubview(makeStatCard(label: label, value: value, unit: unit))
        }
    }

    private func makeStatCard(label: String, value: String, unit: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.addFundeShadow()
        let v = UILabel(); v.text = value; v.font = .fdH2; v.textColor = .fdText
        let u = UILabel(); u.text = unit; u.font = .fdMicro; u.textColor = .fdSubtext
        let l = UILabel(); l.text = label; l.font = .fdCaption; l.textColor = .fdSubtext
        card.addSubview(v); card.addSubview(u); card.addSubview(l)
        v.snp.makeConstraints { make in make.top.equalToSuperview().offset(14); make.leading.equalToSuperview().offset(12) }
        u.snp.makeConstraints { make in make.lastBaseline.equalTo(v); make.leading.equalTo(v.snp.trailing).offset(2) }
        l.snp.makeConstraints { make in
            make.top.equalTo(v.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-14)
        }
        return card
    }

    private func buildRecordsSection() -> UIView {
        let container = UIView()
        let title = UILabel(); title.text = "近期记录"; title.font = .fdBodySemibold; title.textColor = .fdSubtext
        container.addSubview(title)
        title.snp.makeConstraints { $0.top.leading.equalToSuperview() }

        recordsHost.backgroundColor = .fdSurface
        recordsHost.layer.cornerRadius = 18
        recordsHost.addFundeShadow()
        container.addSubview(recordsHost)
        recordsHost.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }

        let addBtn = UIButton(type: .system)
        addBtn.setTitle("+ 录入数据", for: .normal)
        addBtn.titleLabel?.font = .fdBodySemibold
        addBtn.setTitleColor(.fdPrimary, for: .normal)
        addBtn.backgroundColor = .fdPrimarySoft
        addBtn.layer.cornerRadius = 12
        addBtn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        container.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.top.equalTo(recordsHost.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        return container
    }

    private func reloadRecords() {
        recordsHost.subviews.forEach { $0.removeFromSuperview() }
        let items = viewModel.logItems
        if items.isEmpty {
            let empty = UILabel()
            empty.text = "暂无记录"
            empty.font = .fdCaption
            empty.textColor = .fdMuted
            empty.textAlignment = .center
            recordsHost.addSubview(empty)
            empty.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(24)
            }
            return
        }
        var prev: UIView?
        for (i, item) in items.enumerated() {
            let source = (item.dataSource ?? "").contains("蓝牙") ? "bluetooth" : "manual"
            let row = buildRecordRow(
                time: item.timeDisplay,
                value: "\(item.pressureDisplay) mmHg",
                source: source,
                showDivider: i < items.count - 1
            )
            recordsHost.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) }
            }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }
    }

    private func buildRecordRow(time: String, value: String, source: String, showDivider: Bool) -> UIView {
        let row = UIView()
        let t = UILabel(); t.text = time; t.font = .fdCaption; t.textColor = .fdText
        let v = UILabel(); v.text = value; v.font = .fdBodySemibold; v.textColor = .fdText
        let icon = UIImageView(image: UIImage(systemName: source == "bluetooth" ? "antenna.radiowaves.left.and.right" : "hand.point.up.fill"))
        icon.tintColor = .fdMuted
        icon.contentMode = .scaleAspectFit
        row.addSubview(t); row.addSubview(v); row.addSubview(icon)
        t.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.equalToSuperview() }
        v.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
        icon.snp.makeConstraints { make in make.trailing.centerY.equalToSuperview(); make.size.equalTo(16) }
        if showDivider {
            let div = UIView(); div.backgroundColor = .fdBorder
            row.addSubview(div)
            div.snp.makeConstraints { make in make.leading.trailing.bottom.equalToSuperview(); make.height.equalTo(1) }
        }
        return row
    }

    @objc private func periodChanged(_ seg: UISegmentedControl) {
        viewModel.periodIndex = seg.selectedSegmentIndex
        viewModel.load()
    }

    @objc private func addRecord() {
        Router.shared.push("/health/metrics/blood-pressure/manual")
    }

    @objc private func openHistory() {
        Router.shared.push("/health/metrics/blood-pressure/history")
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
