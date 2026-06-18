import UIKit
import SnapKit
import DGCharts

/// 血糖管理 — 空腹+餐后双折线
/// 参考 funde-client: BloodSugarView.vue
final class BloodSugarViewController: BaseViewController {

    private struct Record { let date: String; let fasting: Double; let postMeal: Double }
    private var records: [Record] = [
        Record(date: "05-11", fasting: 5.6, postMeal: 7.5),
        Record(date: "05-12", fasting: 5.7, postMeal: 7.1),
        Record(date: "05-13", fasting: 5.9, postMeal: 7.8),
        Record(date: "05-14", fasting: 6.1, postMeal: 8.2),
        Record(date: "05-15", fasting: 5.8, postMeal: 7.3),
        Record(date: "05-16", fasting: 5.7, postMeal: 7.0),
        Record(date: "05-17", fasting: 5.8, postMeal: 7.2),
    ]
    private var subType = 0 // 0:指血 1:动态
    private let chartView = LineChartView()

    override func setupUI() {
        title = "血糖管理"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView()
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIView()
        scroll.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        // Sub-type tabs
        let subSeg = UISegmentedControl(items: ["指血血糖", "动态血糖"])
        subSeg.selectedSegmentIndex = subType
        styleSeg(subSeg)
        subSeg.addTarget(self, action: #selector(subTypeChanged(_:)), for: .valueChanged)
        content.addSubview(subSeg)
        subSeg.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(36) }

        // Chart
        let chartCard = makeChartCard(title: "血糖趋势", legend: [("空腹", UIColor(hexString: "#FF7A50")), ("餐后2h", UIColor(hexString: "#6B9FE4"))])
        content.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in make.top.equalTo(subSeg.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(220) }

        // Stats
        let fastingVals = records.map(\.fasting)
        let postMealVals = records.map(\.postMeal)
        let maxVal = Int(max(fastingVals.max() ?? 0, postMealVals.max() ?? 0))
        let minVal = Int(min(fastingVals.min() ?? 0, postMealVals.min() ?? 0))
        let variation = String(format: "%.1f", Double(maxVal) - Double(minVal))
        let statsRow = buildTripleStat(a: ("最高", "\(maxVal)", "mmol/L"), b: ("最低", "\(minVal)", "mmol/L"), c: ("波动幅度", variation, "mmol/L"))
        content.addSubview(statsRow)
        statsRow.snp.makeConstraints { make in make.top.equalTo(chartCard.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // Records
        let mockHist = [
            ("今天 08:10", "5.8 mmol/L", "manual", "空腹"),
            ("昨天 10:10", "7.2 mmol/L", "manual", "餐后2h"),
            ("05-16 08:05", "5.7 mmol/L", "bluetooth", "空腹"),
            ("05-15 08:30", "5.8 mmol/L", "bluetooth", "空腹"),
        ]
        let recCard = buildRecordsCard(records: mockHist)
        content.addSubview(recCard)
        recCard.snp.makeConstraints { make in make.top.equalTo(statsRow.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad); make.bottom.equalToSuperview().offset(-20) }

        loadChart()
    }

    private func loadChart() {
        let fastingEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: $0.1.fasting) }
        let postMealEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: $0.1.postMeal) }

        let ds1 = LineChartView.makeFundeDataSet(entries: fastingEntries, label: "空腹", color: UIColor(hexString: "#FF7A50"))
        let ds2 = LineChartView.makeFundeDataSet(entries: postMealEntries, label: "餐后2h", color: UIColor(hexString: "#6B9FE4"))

        chartView.data = LineChartData(dataSets: [ds1, ds2])
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date))
        chartView.xAxis.granularity = 1
        chartView.leftAxis.axisMinimum = 3; chartView.leftAxis.axisMaximum = 14
    }

    // MARK: - Shared builders

    private func makeChartCard(title: String, legend: [(String, UIColor)]) -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        let t = UILabel(); t.text = title; t.font = .fdBodySemibold; t.textColor = .fdText
        let legendStack = UIStackView(); legendStack.axis = .horizontal; legendStack.spacing = 16
        for (lbl, color) in legend {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
            let l = UILabel(); l.text = lbl; l.font = .fdCaption; l.textColor = .fdSubtext
            legendStack.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(8) }
            legendStack.addArrangedSubview(l)
        }
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        card.addSubview(t); card.addSubview(legendStack); card.addSubview(chartView)
        t.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legendStack.snp.makeConstraints { $0.top.trailing.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(8); make.leading.trailing.bottom.equalToSuperview().inset(8) }
        return card
    }

    private func buildTripleStat(a: (String, String, String), b: (String, String, String), c: (String, String, String)) -> UIView {
        let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 10
        for (label, value, unit) in [a, b, c] {
            let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 14; card.addFundeShadow(radius: 4)
            let v = UILabel(); v.text = value; v.font = .fdH2; v.textColor = .fdText
            let u = UILabel(); u.text = unit; u.font = .fdMicro; u.textColor = .fdSubtext
            let l = UILabel(); l.text = label; l.font = .fdCaption; l.textColor = .fdSubtext
            card.addSubview(v); card.addSubview(u); card.addSubview(l)
            v.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview().offset(12) }
            u.snp.makeConstraints { $0.lastBaseline.equalTo(v); $0.leading.equalTo(v.snp.trailing).offset(2) }
            l.snp.makeConstraints { $0.top.equalTo(v.snp.bottom).offset(4); $0.leading.equalToSuperview().offset(12); $0.bottom.equalToSuperview().offset(-14) }
            row.addArrangedSubview(card)
        }
        return row
    }

    private func buildRecordsCard(records: [(String, String, String, String)]) -> UIView {
        let container = UIView()
        let title = UILabel(); title.text = "近期记录"; title.font = .fdBodySemibold; title.textColor = .fdSubtext
        container.addSubview(title); title.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        container.addSubview(card)
        card.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview() }
        var prev: UIView?
        for (i, (time, val, src, type)) in records.enumerated() {
            let row = UIView()
            let t = UILabel(); t.text = time; t.font = .fdCaption; t.textColor = .fdText
            let v = UILabel(); v.text = "\(val)  \(type)"; v.font = .fdBodySemibold; v.textColor = .fdText
            let icon = UIImageView(image: UIImage(systemName: src == "bluetooth" ? "bluetooth" : "hand.point.up.fill")); icon.tintColor = .fdMuted
            row.addSubview(t); row.addSubview(v); row.addSubview(icon)
            t.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.equalToSuperview() }
            v.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            icon.snp.makeConstraints { make in make.trailing.centerY.equalToSuperview(); make.size.equalTo(16) }
            if i < records.count - 1 {
                let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div)
                div.snp.makeConstraints { make in make.leading.trailing.bottom.equalToSuperview(); make.height.equalTo(1) }
            }
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

    private func styleSeg(_ seg: UISegmentedControl) {
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
    }

    @objc private func subTypeChanged(_ seg: UISegmentedControl) { subType = seg.selectedSegmentIndex }
    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "blood-sugar"]) }
}

