import Combine
import UIKit
import SnapKit
import DGCharts

/// 体重管理（Funde 风格 UI + Angel Doctor API）
final class WeightViewController: BaseViewController {

    private let viewModel = WeightFundeViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let segment = UISegmentedControl(items: ["日", "周", "月"])
    private let chartView = LineChartView()
    private let progressHost = UIView()
    private let statsStack = UIStackView()
    private let recordsHost = UIView()
    private var chartCard: UIView!
    private var recordsContainer: UIView!

    override func setupUI() {
        title = "体重管理"
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

        progressHost.backgroundColor = .fdSurface
        progressHost.layer.cornerRadius = 18
        progressHost.addFundeShadow()

        chartCard = buildChartCard()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 8
        recordsContainer = buildRecordsSection()

        [segment, progressHost, chartCard, statsStack, recordsContainer].forEach(contentView.addSubview)
        segment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(36)
        }
        progressHost.snp.makeConstraints { make in
            make.top.equalTo(segment.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad)
        }
        chartCard.snp.makeConstraints { make in
            make.top.equalTo(progressHost.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(220)
        }
        statsStack.snp.makeConstraints { make in
            make.top.equalTo(chartCard.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad)
        }
        recordsContainer.snp.makeConstraints { make in
            make.top.equalTo(statsStack.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    override func bindViewModel() {
        viewModel.$filteredPoints
            .combineLatest(viewModel.$logItems, viewModel.$latest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in self?.reloadUI() }
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
        reloadProgress()
        reloadChart()
        reloadStats()
        reloadRecords()
    }

    private func reloadProgress() {
        progressHost.subviews.forEach { $0.removeFromSuperview() }
        let current = viewModel.currentWeight
        let title = UILabel()
        if let current {
            title.text = "当前体重 \(String(format: "%.1f", current)) kg"
        } else {
            title.text = "暂无体重数据"
        }
        title.font = .fdBodySemibold
        title.textColor = .fdText
        let bmi = UILabel()
        bmi.text = "BMI \(viewModel.bmiText)"
        bmi.font = .fdCaption
        bmi.textColor = .fdSubtext
        progressHost.addSubview(title)
        progressHost.addSubview(bmi)
        title.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        bmi.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    private func buildChartCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let t = UILabel(); t.text = "体重趋势"; t.font = .fdBodySemibold; t.textColor = .fdText
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        card.addSubview(t); card.addSubview(chartView)
        t.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(t.snp.bottom).offset(8); make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        return card
    }

    private func reloadChart() {
        let points = viewModel.filteredPoints
        let entries = points.enumerated().compactMap { i, p -> ChartDataEntry? in
            guard let v = p.weightValue else { return nil }
            return ChartDataEntry(x: Double(i), y: v)
        }
        let set = LineChartView.makeFundeDataSet(entries: entries, label: "体重", color: UIColor(hexString: "#FF7A50"), fillAlpha: 0.06)
        chartView.data = LineChartData(dataSet: set)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: points.map(\.chartLabel))
        chartView.xAxis.granularity = 1
        chartView.notifyDataSetChanged()
    }

    private func reloadStats() {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let start = viewModel.startWeight.map { String(format: "%.1f", $0) } ?? "--"
        let current = viewModel.currentWeight.map { String(format: "%.1f", $0) } ?? "--"
        let change = viewModel.change.map { String(format: "%.1f", $0) } ?? "--"
        for (label, value, unit) in [
            ("起始", start, "kg"), ("当前", current, "kg"), ("变化", change, "kg"), ("BMI", viewModel.bmiText, ""),
        ] {
            statsStack.addArrangedSubview(makeStatCard(label: label, value: value, unit: unit))
        }
    }

    private func makeStatCard(label: String, value: String, unit: String) -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 12; card.addFundeShadow()
        let v = UILabel(); v.text = value; v.font = .fdBodySemibold; v.textColor = .fdText; v.adjustsFontSizeToFitWidth = true
        let u = UILabel(); u.text = unit; u.font = .fdMicro; u.textColor = .fdSubtext
        let l = UILabel(); l.text = label; l.font = .fdMicro; l.textColor = .fdSubtext
        card.addSubview(v); card.addSubview(u); card.addSubview(l)
        v.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(10) }
        u.snp.makeConstraints { make in make.lastBaseline.equalTo(v); make.leading.equalTo(v.snp.trailing).offset(2) }
        l.snp.makeConstraints { make in
            make.top.equalTo(v.snp.bottom).offset(4); make.leading.equalToSuperview().inset(10); make.bottom.equalToSuperview().offset(-10)
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
            let v = UILabel(); v.text = item.weightDisplay; v.font = .fdBodySemibold; v.textColor = .fdText
            row.addSubview(t); row.addSubview(v)
            t.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)) }
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
        viewModel.applyFilter()
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/weight/manual") }
    @objc private func openHistory() { Router.shared.push("/health/metrics/weight/history") }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
