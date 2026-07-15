import Combine
import UIKit
import SnapKit
import DGCharts

/// 血糖管理（Funde 风格 UI + Angel Doctor API）
final class BloodSugarViewController: BaseViewController {

    private let viewModel = BloodSugarFundeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let periodSeg = UISegmentedControl(items: ["日", "周", "月"])
    private let chartView = LineChartView()
    private let statsStack = UIStackView()
    private let recordsHost = UIView()
    private var chartCard: UIView!
    private var recordsContainer: UIView!

    override func setupUI() {
        title = "血糖管理"
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
        periodSeg.selectedSegmentIndex = viewModel.periodIndex
        styleSeg(periodSeg)
        periodSeg.addTarget(self, action: #selector(periodChanged(_:)), for: .valueChanged)

        chartCard = makeChartCard()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 10
        recordsContainer = buildRecordsSection()

        [periodSeg, chartCard, statsStack, recordsContainer].forEach(contentView.addSubview)
        periodSeg.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(36)
        }
        chartCard.snp.makeConstraints { make in
            make.top.equalTo(periodSeg.snp.bottom).offset(12)
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
        viewModel.$chartDays
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

    private func styleSeg(_ seg: UISegmentedControl) {
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
    }

    private func makeChartCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()
        let title = UILabel(); title.text = "血糖趋势"; title.font = .fdBodySemibold; title.textColor = .fdText
        let legend = UIStackView(); legend.axis = .horizontal; legend.spacing = 16
        for (lbl, color) in [("空腹", UIColor(hexString: "#FF7A50")), ("餐后", UIColor(hexString: "#6B9FE4"))] {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
            let l = UILabel(); l.text = lbl; l.font = .fdCaption; l.textColor = .fdSubtext
            legend.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(8) }; legend.addArrangedSubview(l)
        }
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        card.addSubview(title); card.addSubview(legend); card.addSubview(chartView)
        title.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legend.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        return card
    }

    private func reloadChart() {
        let days = viewModel.chartDays
        let hasSplit = days.contains { $0.fasting != nil || $0.postMeal != nil }
        var sets: [LineChartDataSet] = []
        if hasSplit {
            let fasting = days.enumerated().compactMap { i, d -> ChartDataEntry? in
                guard let v = d.fasting else { return nil }
                return ChartDataEntry(x: Double(i), y: v)
            }
            let post = days.enumerated().compactMap { i, d -> ChartDataEntry? in
                guard let v = d.postMeal else { return nil }
                return ChartDataEntry(x: Double(i), y: v)
            }
            if !fasting.isEmpty {
                sets.append(LineChartView.makeFundeDataSet(entries: fasting, label: "空腹", color: UIColor(hexString: "#FF7A50")))
            }
            if !post.isEmpty {
                sets.append(LineChartView.makeFundeDataSet(entries: post, label: "餐后", color: UIColor(hexString: "#6B9FE4")))
            }
        }
        if sets.isEmpty {
            let any = days.enumerated().compactMap { i, d -> ChartDataEntry? in
                guard let v = d.anyValue else { return nil }
                return ChartDataEntry(x: Double(i), y: v)
            }
            sets = [LineChartView.makeFundeDataSet(entries: any, label: "血糖", color: UIColor(hexString: "#FF7A50"))]
        }
        chartView.data = LineChartData(dataSets: sets)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days.map(\.label))
        chartView.xAxis.granularity = 1
        chartView.notifyDataSetChanged()
    }

    private func reloadStats() {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let maxText = viewModel.maxValue.map { String(format: "%.1f", $0) } ?? "--"
        let minText = viewModel.minValue.map { String(format: "%.1f", $0) } ?? "--"
        let varText = viewModel.variation.map { String(format: "%.1f", $0) } ?? "--"
        for (label, value, unit) in [("最高", maxText, "mmol/L"), ("最低", minText, "mmol/L"), ("波动幅度", varText, "mmol/L")] {
            statsStack.addArrangedSubview(makeStatCard(label: label, value: value, unit: unit))
        }
    }

    private func makeStatCard(label: String, value: String, unit: String) -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 14; card.addFundeShadow()
        let v = UILabel(); v.text = value; v.font = .fdH2; v.textColor = .fdText
        let u = UILabel(); u.text = unit; u.font = .fdMicro; u.textColor = .fdSubtext
        let l = UILabel(); l.text = label; l.font = .fdCaption; l.textColor = .fdSubtext
        card.addSubview(v); card.addSubview(u); card.addSubview(l)
        v.snp.makeConstraints { make in make.top.equalToSuperview().offset(14); make.leading.equalToSuperview().offset(12) }
        u.snp.makeConstraints { make in make.lastBaseline.equalTo(v); make.leading.equalTo(v.snp.trailing).offset(2) }
        l.snp.makeConstraints { make in
            make.top.equalTo(v.snp.bottom).offset(4); make.leading.equalToSuperview().offset(12); make.bottom.equalToSuperview().offset(-14)
        }
        return card
    }

    private func buildRecordsSection() -> UIView {
        let container = UIView()
        let title = UILabel(); title.text = "近期记录"; title.font = .fdBodySemibold; title.textColor = .fdSubtext
        container.addSubview(title); title.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        recordsHost.backgroundColor = .fdSurface; recordsHost.layer.cornerRadius = 18; recordsHost.addFundeShadow()
        container.addSubview(recordsHost)
        recordsHost.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(12); make.leading.trailing.equalToSuperview() }
        let addBtn = UIButton(type: .system)
        addBtn.setTitle("+ 录入数据", for: .normal)
        addBtn.titleLabel?.font = .fdBodySemibold
        addBtn.setTitleColor(.fdPrimary, for: .normal)
        addBtn.backgroundColor = .fdPrimarySoft; addBtn.layer.cornerRadius = 12
        addBtn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        container.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.top.equalTo(recordsHost.snp.bottom).offset(12); make.leading.trailing.equalToSuperview()
            make.height.equalTo(44); make.bottom.equalToSuperview()
        }
        return container
    }

    private func reloadRecords() {
        recordsHost.subviews.forEach { $0.removeFromSuperview() }
        let items = viewModel.logItems
        if items.isEmpty {
            let empty = UILabel(); empty.text = "暂无记录"; empty.font = .fdCaption; empty.textColor = .fdMuted; empty.textAlignment = .center
            recordsHost.addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview().inset(24) }
            return
        }
        var prev: UIView?
        for (i, item) in items.enumerated() {
            let row = UIView()
            let t = UILabel(); t.text = item.timeDisplay; t.font = .fdCaption; t.textColor = .fdText
            let meal = UILabel(); meal.text = item.typeRemark ?? ""; meal.font = .fdMicro; meal.textColor = .fdMuted
            let v = UILabel(); v.text = item.valueDisplay; v.font = .fdBodySemibold; v.textColor = .fdText
            [t, meal, v].forEach(row.addSubview)
            t.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)) }
            meal.snp.makeConstraints { make in make.centerY.equalTo(t); make.leading.equalTo(t.snp.trailing).offset(8) }
            v.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            if i < items.count - 1 {
                let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div)
                div.snp.makeConstraints { make in make.leading.trailing.bottom.equalToSuperview(); make.height.equalTo(1) }
            }
            recordsHost.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) }
            }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }
    }

    @objc private func periodChanged(_ seg: UISegmentedControl) {
        viewModel.periodIndex = seg.selectedSegmentIndex
        viewModel.load()
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/blood-sugar/manual") }
    @objc private func openHistory() { Router.shared.push("/health/metrics/blood-sugar/history") }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
