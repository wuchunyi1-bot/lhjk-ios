import UIKit
import SnapKit
import DGCharts

/// 心率监测 — 静息+运动双折线 + 心率分区
/// 参考 funde-client: HeartRateView.vue
final class HeartRateViewController: BaseViewController {

    private struct Record { let date: String; let resting: Int; let exercise: Int }
    private var records: [Record] = [
        Record(date: "05-11", resting: 78, exercise: 138),
        Record(date: "05-12", resting: 77, exercise: 140),
        Record(date: "05-13", resting: 76, exercise: 142),
        Record(date: "05-14", resting: 75, exercise: 139),
        Record(date: "05-15", resting: 77, exercise: 145),
        Record(date: "05-16", resting: 76, exercise: 141),
        Record(date: "05-17", resting: 76, exercise: 142),
    ]
    private let chartView = LineChartView()

    override func setupUI() {
        title = "心率监测"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIView(); scroll.addSubview(content); content.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        let seg = makeSegment()
        content.addSubview(seg); seg.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(36) }

        // Chart
        let chartCard = buildChartCard()
        content.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in make.top.equalTo(seg.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(220) }

        // Stats
        let avgResting = records.map(\.resting).reduce(0, +) / records.count
        let maxEx = records.map(\.exercise).max() ?? 0
        let minRest = records.map(\.resting).min() ?? 0
        let stats = buildTripleStat(
            ("平均静息", "\(avgResting)", "bpm"),
            ("最高运动", "\(maxEx)", "bpm"),
            ("最低静息", "\(minRest)", "bpm")
        )
        content.addSubview(stats); stats.snp.makeConstraints { make in make.top.equalTo(chartCard.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // Heart rate zones
        let zones = buildZonesCard()
        content.addSubview(zones)
        zones.snp.makeConstraints { make in make.top.equalTo(stats.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad) }

        // Records
        let mockHist = [
            ("今天 07:32", "76 bpm (静息)", "bluetooth"),
            ("今天 09:15", "142 bpm (运动)", "bluetooth"),
            ("05-16 07:28", "76 bpm (静息)", "bluetooth"),
            ("05-15 07:45", "77 bpm (静息)", "manual"),
        ]
        let recCard = buildRecords(mockHist)
        content.addSubview(recCard); recCard.snp.makeConstraints { make in make.top.equalTo(zones.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad); make.bottom.equalToSuperview().offset(-20) }

        loadChart()
    }

    private func buildChartCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let t = UILabel(); t.text = "心率趋势"; t.font = .systemFont(ofSize: 14, weight: .semibold); t.textColor = .fdText
        let legend = UIStackView(); legend.axis = .horizontal; legend.spacing = 16
        for (color, lbl) in [(UIColor(hexString: "#FF7A50"), "运动时"), (UIColor(hexString: "#6B9FE4"), "静息时")] {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
            let l = UILabel(); l.text = lbl; l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext
            legend.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(8) }; legend.addArrangedSubview(l)
        }
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        card.addSubview(t); card.addSubview(legend); card.addSubview(chartView)
        t.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legend.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(8); make.leading.trailing.bottom.equalToSuperview().inset(8) }
        return card
    }

    private func loadChart() {
        let restingEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: Double($0.1.resting)) }
        let exerciseEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: Double($0.1.exercise)) }

        let ds1 = LineChartView.makeFundeDataSet(entries: exerciseEntries, label: "运动", color: UIColor(hexString: "#FF7A50"), circleRadius: 4)
        let ds2 = LineChartView.makeFundeDataSet(entries: restingEntries, label: "静息", color: UIColor(hexString: "#6B9FE4"), circleRadius: 4)

        chartView.data = LineChartData(dataSets: [ds1, ds2])
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date))
        chartView.xAxis.granularity = 1
        chartView.leftAxis.axisMinimum = 50; chartView.leftAxis.axisMaximum = 170
    }

    private func buildZonesCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let title = UILabel(); title.text = "心率分区"; title.font = .systemFont(ofSize: 14, weight: .semibold); title.textColor = .fdText
        card.addSubview(title); title.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }

        let zones: [(String, String, UIColor)] = [
            ("热身区", "100–115 bpm", UIColor(hexString: "#52B96A")),
            ("有氧燃脂", "115–133 bpm", UIColor(hexString: "#6B9FE4")),
            ("心肺提升", "133–152 bpm", .fdPrimary),
            ("极限区", ">152 bpm", .fdDanger),
        ]
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 8
        card.addSubview(stack)
        stack.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(16); make.bottom.equalToSuperview().offset(-16) }

        for (label, range, color) in zones {
            let row = UIStackView(); row.axis = .horizontal; row.spacing = 8; row.alignment = .center
            let bar = UIView(); bar.backgroundColor = color; bar.layer.cornerRadius = 3
            let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 14, weight: .medium); l.textColor = .fdText
            let r = UILabel(); r.text = range; r.font = .systemFont(ofSize: 13); r.textColor = .fdSubtext
            row.addArrangedSubview(bar); bar.snp.makeConstraints { $0.width.equalTo(6); $0.height.equalTo(20) }
            row.addArrangedSubview(l)
            row.addArrangedSubview(UIView())
            row.addArrangedSubview(r)
            stack.addArrangedSubview(row)
        }
        return card
    }

    // MARK: - Helpers

    private func buildTripleStat(_ a: (String, String, String), _ b: (String, String, String), _ c: (String, String, String)) -> UIView {
        let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 10
        for (label, value, unit) in [a, b, c] {
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
        return row
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

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "heart-rate"]) }

    private func makeSegment() -> UISegmentedControl {
        let seg = UISegmentedControl(items: ["日", "周", "月"])
        seg.selectedSegmentIndex = 1
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        seg.backgroundColor = .fdBg2
        return seg
    }
}
