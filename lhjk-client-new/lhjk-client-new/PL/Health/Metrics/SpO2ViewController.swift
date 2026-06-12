import UIKit
import SnapKit
import DGCharts

/// 血氧监测
/// 参考 funde-client: SpO2View.vue
final class SpO2ViewController: BaseViewController {

    private struct Record { let date: String; let value: Double }
    private var records: [Record] = [
        Record(date: "05-11", value: 98), Record(date: "05-12", value: 97), Record(date: "05-13", value: 98),
        Record(date: "05-14", value: 96), Record(date: "05-15", value: 97), Record(date: "05-16", value: 98),
        Record(date: "05-17", value: 98),
    ]
    private let chartView = LineChartView()

    override func setupUI() {
        title = "血氧监测"; view.backgroundColor = .fdBg
        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let c = UIView(); scroll.addSubview(c); c.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let p: CGFloat = 16

        // Latest card
        let latestCard = applyCard(UIView(), bg: UIColor(hexString: "#38B2AC"))
        let label = UILabel(); label.text = "最新测量 · 今天 07:32"; label.font = .systemFont(ofSize: 12); label.textColor = UIColor.white.withAlphaComponent(0.8)
        let val = UILabel(); val.text = "98"; val.font = .systemFont(ofSize: 48, weight: .bold); val.textColor = .white
        let unit = UILabel(); unit.text = "%"; unit.font = .systemFont(ofSize: 18); unit.textColor = UIColor.white.withAlphaComponent(0.85)
        let statusBadge = tagView("正常", bg: UIColor.white.withAlphaComponent(0.3), fg: .white)
        c.addSubview(latestCard); latestCard.addSubview(label); latestCard.addSubview(val); latestCard.addSubview(unit); latestCard.addSubview(statusBadge)
        latestCard.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.trailing.equalToSuperview().inset(p) }
        label.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(18) }
        val.snp.makeConstraints { make in make.top.equalTo(label.snp.bottom).offset(4); make.leading.equalToSuperview().inset(18) }
        unit.snp.makeConstraints { make in make.lastBaseline.equalTo(val).offset(-8); make.leading.equalTo(val.snp.trailing).offset(4) }
        statusBadge.snp.makeConstraints { make in make.top.equalTo(val.snp.bottom).offset(4); make.leading.equalToSuperview().inset(18); make.bottom.equalToSuperview().offset(-18) }

        // Reference strip
        let ref = UIView(); ref.backgroundColor = .fdSurface; ref.layer.cornerRadius = 10; ref.addFundeShadow()
        let refLbl = UILabel(); refLbl.text = "正常范围：95% ~ 100% · 低于 95% 请及时就医"; refLbl.font = .systemFont(ofSize: 12); refLbl.textColor = UIColor(hexString: "#38B2AC")
        ref.addSubview(refLbl); refLbl.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        c.addSubview(ref); ref.snp.makeConstraints { $0.top.equalTo(latestCard.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(p) }

        // Segment
        let seg = makeSeg(["日", "周", "月"]); c.addSubview(seg)
        seg.snp.makeConstraints { $0.top.equalTo(ref.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(36) }

        // Chart
        let chartCard = applyCard(UIView())
        chartView.applyFundeStyle(); chartView.legend.enabled = false
        chartCard.addSubview(chartView)
        c.addSubview(chartCard)
        chartCard.snp.makeConstraints { $0.top.equalTo(seg.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(180) }
        chartView.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }

        // Stats
        let avg = records.map(\.value).reduce(0,+) / Double(records.count)
        let minV = records.map(\.value).min() ?? 0
        let maxV = records.map(\.value).max() ?? 0
        let stats = tripleStat(("平均", String(format: "%.0f", avg), "%"), ("最低", String(format: "%.0f", minV), "%"), ("最高", String(format: "%.0f", maxV), "%"))
        c.addSubview(stats); stats.snp.makeConstraints { $0.top.equalTo(chartCard.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(p) }

        // Records
        let mockHist = [("今天 07:32", "98%", "bluetooth"), ("昨天 07:30", "97%", "bluetooth"), ("05-16 07:28", "98%", "bluetooth")]
        let recCard = buildRecords(mockHist); c.addSubview(recCard)
        recCard.snp.makeConstraints { $0.top.equalTo(stats.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(p) }

        let btn = UIButton(type: .system); btn.setTitle("+ 录入数据", for: .normal); btn.styleFundeSoft()
        btn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        c.addSubview(btn); btn.snp.makeConstraints { $0.top.equalTo(recCard.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(p); $0.height.equalTo(44); $0.bottom.equalToSuperview().offset(-20) }

        loadChart()
    }

    private func loadChart() {
        let entries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: $0.1.value) }
        let ds = LineChartView.makeFundeDataSet(entries: entries, label: "血氧", color: UIColor(hexString: "#38B2AC"), fillAlpha: 0.1, lineWidth: 2.5)
        chartView.data = LineChartData(dataSet: ds)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date)); chartView.xAxis.granularity = 1
        chartView.leftAxis.axisMinimum = 90; chartView.leftAxis.axisMaximum = 100
        // 95% reference line
        let refLine = ChartLimitLine(limit: 95, label: "95%")
        refLine.lineColor = UIColor.fdDanger.withAlphaComponent(0.4); refLine.lineWidth = 1.5; refLine.lineDashLengths = [5, 3]
        refLine.valueFont = .systemFont(ofSize: 10); refLine.valueTextColor = .fdDanger
        chartView.leftAxis.addLimitLine(refLine)
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "spo2"]) }

    private func applyCard(_ card: UIView, bg: UIColor = .fdSurface, radius: CGFloat = 18) -> UIView {
        card.backgroundColor = bg; card.layer.cornerRadius = radius
        if bg == .fdSurface { card.addFundeShadow() }; return card
    }
    private func makeSeg(_ items: [String]) -> UISegmentedControl {
        let s = UISegmentedControl(items: items); s.selectedSegmentIndex = 1
        s.selectedSegmentTintColor = .fdPrimary; s.backgroundColor = .fdBg2
        s.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        s.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal); return s
    }
    private func tagView(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 12); l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }; return v
    }
    private func tripleStat(_ a: (String, String, String), _ b: (String, String, String), _ c: (String, String, String)) -> UIView {
        let row = UIStackView(); row.distribution = .fillEqually; row.spacing = 10
        for (label, value, unit) in [a, b, c] {
            let card = applyCard(UIView(), radius: 14); card.addFundeShadow(radius: 4)
            let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: 22, weight: .bold); v.textColor = .fdText
            let u = UILabel(); u.text = unit; u.font = .systemFont(ofSize: 11); u.textColor = .fdSubtext
            let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext
            card.addSubview(v); card.addSubview(u); card.addSubview(l)
            v.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview().offset(12) }
            u.snp.makeConstraints { $0.lastBaseline.equalTo(v); $0.leading.equalTo(v.snp.trailing).offset(2) }
            l.snp.makeConstraints { $0.top.equalTo(v.snp.bottom).offset(4); $0.leading.equalToSuperview().offset(12); $0.bottom.equalToSuperview().offset(-14) }
            row.addArrangedSubview(card)
        }; return row
    }
    private func buildRecords(_ items: [(String, String, String)]) -> UIView {
        let ctr = UIView()
        let t = UILabel(); t.text = "近期记录"; t.font = .systemFont(ofSize: 14, weight: .semibold); t.textColor = .fdSubtext
        ctr.addSubview(t); t.snp.makeConstraints { $0.top.leading.equalToSuperview() }
        let card = applyCard(UIView())
        ctr.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(t.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview() }
        var prev: UIView?
        for (i, (time, val, src)) in items.enumerated() {
            let row = UIView(); let tl = UILabel(); tl.text = time; tl.font = .systemFont(ofSize: 13); tl.textColor = .fdText
            let vl = UILabel(); vl.text = val; vl.font = .systemFont(ofSize: 14, weight: .semibold); vl.textColor = .fdText
            let icon = UIImageView(image: UIImage(systemName: src == "bluetooth" ? "bluetooth" : "hand.point.up.fill")); icon.tintColor = .fdMuted
            row.addSubview(tl); row.addSubview(vl); row.addSubview(icon)
            tl.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview() }
            vl.snp.makeConstraints { make in make.top.equalTo(tl.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            icon.snp.makeConstraints { $0.trailing.centerY.equalToSuperview(); $0.size.equalTo(16) }
            if i < items.count - 1 { let d = UIView(); d.backgroundColor = .fdBorder; row.addSubview(d); d.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) } }
            card.addSubview(row); row.snp.makeConstraints { make in make.leading.trailing.equalToSuperview().inset(16); if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) } }
            prev = row
        }; prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }; return ctr
    }
}
