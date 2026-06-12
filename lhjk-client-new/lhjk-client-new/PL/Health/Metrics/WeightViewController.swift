import UIKit
import SnapKit
import DGCharts

/// 体重管理 — 单折线 + 目标虚线
/// 参考 funde-client: WeightView.vue
final class WeightViewController: BaseViewController {

    private struct Record { let date: String; let weight: Double }
    private let targetWeight = 65.0

    private var records: [Record] = [
        Record(date: "05-11", weight: 69.2), Record(date: "05-12", weight: 69.0),
        Record(date: "05-13", weight: 68.8), Record(date: "05-14", weight: 68.9),
        Record(date: "05-15", weight: 68.7), Record(date: "05-16", weight: 68.5),
        Record(date: "05-17", weight: 68.5),
    ]
    private let chartView = LineChartView()

    override func setupUI() {
        title = "体重管理"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIView(); scroll.addSubview(content); content.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        let seg = makePeriodSegment()
        content.addSubview(seg); seg.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(36) }

        // Progress
        let startWeight = records.first?.weight ?? 69.2
        let currentWeight = records.last?.weight ?? 68.5
        let remaining = currentWeight - targetWeight
        let progressView = buildProgressCard(current: currentWeight, target: targetWeight, remaining: remaining)
        content.addSubview(progressView)
        progressView.snp.makeConstraints { make in make.top.equalTo(seg.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // Chart
        let chartCard = buildChartCard()
        content.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in make.top.equalTo(progressView.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(220) }

        // Stats
        let maxW = records.map(\.weight).max() ?? 0
        let minW = records.map(\.weight).min() ?? 0
        let change = maxW - minW
        let bmi = String(format: "%.1f", currentWeight / 1.7 / 1.7)
        let stats = buildQuadStat(
            a: ("起始", "\(String(format: "%.1f", startWeight))", "kg"),
            b: ("当前", "\(String(format: "%.1f", currentWeight))", "kg"),
            c: ("变化", "\(String(format: "%.1f", change))", "kg"),
            d: ("BMI", bmi, "")
        )
        content.addSubview(stats); stats.snp.makeConstraints { make in make.top.equalTo(chartCard.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // Records
        let mockHist = [
            ("05-17 08:00", "68.5 kg  BMI 23.7", "bluetooth"),
            ("05-16 07:50", "68.5 kg  BMI 23.7", "bluetooth"),
            ("05-15 08:10", "68.7 kg  BMI 23.8", "manual"),
            ("05-14 07:55", "68.9 kg  BMI 23.8", "bluetooth"),
        ]
        let recCard = buildRecords(mockHist)
        content.addSubview(recCard); recCard.snp.makeConstraints { make in make.top.equalTo(stats.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad); make.bottom.equalToSuperview().offset(-20) }

        loadChart()
    }

    private func buildProgressCard(current: Double, target: Double, remaining: Double) -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let title = UILabel(); title.text = "距离目标还有 \(String(format: "%.1f", remaining)) kg"; title.font = .systemFont(ofSize: 14, weight: .semibold); title.textColor = .fdText
        let progressBg = UIView(); progressBg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14); progressBg.layer.cornerRadius = 4
        let fill = UIView(); fill.backgroundColor = .fdPrimary; fill.layer.cornerRadius = 4
        let start = records.first?.weight ?? target + 5
        let pct = min(max((start - current) / (start - target), 0), 1)
        progressBg.addSubview(fill)
        let pctLbl = UILabel(); pctLbl.text = "\(Int(pct * 100))%"; pctLbl.font = .systemFont(ofSize: 13, weight: .bold); pctLbl.textColor = .fdPrimary
        card.addSubview(title); card.addSubview(progressBg); card.addSubview(pctLbl)
        title.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        pctLbl.snp.makeConstraints { $0.centerY.equalTo(title); $0.trailing.equalToSuperview().offset(-16) }
        progressBg.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(10); make.leading.trailing.equalToSuperview().inset(16); make.height.equalTo(8); make.bottom.equalToSuperview().offset(-16) }
        fill.snp.makeConstraints { make in make.leading.top.bottom.equalToSuperview(); make.width.equalToSuperview().multipliedBy(pct) }
        return card
    }

    private func buildChartCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let t = UILabel(); t.text = "体重趋势"; t.font = .systemFont(ofSize: 14, weight: .semibold); t.textColor = .fdText
        let dot = UIView(); dot.backgroundColor = UIColor(hexString: "#FF7A50"); dot.layer.cornerRadius = 4
        let targetDot = UIView(); targetDot.backgroundColor = UIColor(hexString: "#6B9FE4"); targetDot.layer.cornerRadius = 4
        let legend = UIStackView(); legend.axis = .horizontal; legend.spacing = 16
        for (d, lbl) in [(dot, "体重"), (targetDot, "目标")] {
            legend.addArrangedSubview(d); d.snp.makeConstraints { $0.size.equalTo(8) }
            let l = UILabel(); l.text = lbl; l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext; legend.addArrangedSubview(l)
        }
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        card.addSubview(t); card.addSubview(legend); card.addSubview(chartView)
        t.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legend.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(8); make.leading.trailing.bottom.equalToSuperview().inset(8) }
        return card
    }

    private func loadChart() {
        let entries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: $0.1.weight) }
        let ds = LineChartView.makeFundeDataSet(entries: entries, label: "体重", color: UIColor(hexString: "#FF7A50"), fillAlpha: 0.06)

        chartView.data = LineChartData(dataSet: ds)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date))
        chartView.xAxis.granularity = 1

        // Target limit line
        let targetLine = ChartLimitLine(limit: targetWeight, label: "目标 \(String(format: "%.0f", targetWeight))kg")
        targetLine.lineColor = UIColor(hexString: "#6B9FE4"); targetLine.lineWidth = 1.5
        targetLine.lineDashLengths = [6, 4]
        targetLine.labelPosition = .rightTop
        targetLine.valueFont = .systemFont(ofSize: 10)
        targetLine.valueTextColor = UIColor(hexString: "#6B9FE4")
        chartView.leftAxis.addLimitLine(targetLine)

        chartView.leftAxis.axisMinimum = targetWeight - 5
        chartView.leftAxis.axisMaximum = (records.map(\.weight).max() ?? 70) + 2
    }

    private func buildQuadStat(a: (String, String, String), b: (String, String, String), c: (String, String, String), d: (String, String, String)) -> UIView {
        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 10
        for rowItems in [[a, b], [c, d]] {
            let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 10
            for (label, value, unit) in rowItems {
                let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 14; card.addFundeShadow(radius: 4)
                let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: 22, weight: .bold); v.textColor = .fdText
                let u = UILabel(); u.text = unit; u.font = .systemFont(ofSize: 11); u.textColor = .fdSubtext
                let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext
                card.addSubview(v); card.addSubview(u); card.addSubview(l)
                v.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview().offset(12) }
                u.snp.makeConstraints { $0.lastBaseline.equalTo(v); $0.leading.equalTo(v.snp.trailing).offset(2) }
                l.snp.makeConstraints { $0.top.equalTo(v.snp.bottom).offset(4); $0.leading.equalToSuperview().offset(12); $0.bottom.equalToSuperview().offset(-14) }
                row.addArrangedSubview(card)
            }
            grid.addArrangedSubview(row)
        }
        return grid
    }

    private func buildRecords(_ items: [(String, String, String)]) -> UIView {
        let container = UIView()
        let title = UILabel(); title.text = "近期记录"; title.font = .systemFont(ofSize: 14, weight: .semibold); title.textColor = .fdSubtext
        container.addSubview(title); title.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        container.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview() }
        var prev: UIView?
        for (i, (time, val, src)) in items.enumerated() {
            let row = UIView(); let t = UILabel(); t.text = time; t.font = .systemFont(ofSize: 13); t.textColor = .fdText
            let v = UILabel(); v.text = val; v.font = .systemFont(ofSize: 14, weight: .semibold); v.textColor = .fdText
            let icon = UIImageView(image: UIImage(systemName: src == "bluetooth" ? "bluetooth" : "hand.point.up.fill")); icon.tintColor = .fdMuted
            row.addSubview(t); row.addSubview(v); row.addSubview(icon)
            t.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview() }
            v.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            icon.snp.makeConstraints { make in make.trailing.centerY.equalToSuperview(); make.size.equalTo(16) }
            if i < items.count - 1 { let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div); div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) } }
            card.addSubview(row)
            row.snp.makeConstraints { make in make.leading.trailing.equalToSuperview().inset(16); if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) } }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }
        let btn = UIButton(type: .system); btn.setTitle("+ 录入数据", for: .normal); btn.styleFundeSoft()
        btn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        container.addSubview(btn); btn.snp.makeConstraints { make in make.top.equalTo(card.snp.bottom).offset(12); make.leading.trailing.equalToSuperview(); make.height.equalTo(44); make.bottom.equalToSuperview() }
        return container
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "weight"]) }

    private func makePeriodSegment() -> UISegmentedControl {
        let seg = UISegmentedControl(items: ["周", "月", "年"])
        seg.selectedSegmentIndex = 1
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        seg.backgroundColor = .fdBg2
        return seg
    }
}
