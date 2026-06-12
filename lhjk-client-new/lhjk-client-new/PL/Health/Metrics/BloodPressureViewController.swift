import UIKit
import SnapKit
import DGCharts

/// 血压管理 — 双折线图（收缩压 + 舒张压）
/// 参考 funde-client: BloodPressureView.vue
final class BloodPressureViewController: BaseViewController {

    // MARK: - Data

    private struct Record {
        let date: String; let sys: Int; let dia: Int
    }

    private var records: [Record] = [
        Record(date: "05-11", sys: 132, dia: 84),
        Record(date: "05-12", sys: 135, dia: 86),
        Record(date: "05-13", sys: 140, dia: 90),
        Record(date: "05-14", sys: 142, dia: 91),
        Record(date: "05-15", sys: 138, dia: 88),
        Record(date: "05-16", sys: 137, dia: 87),
        Record(date: "05-17", sys: 138, dia: 88),
    ]

    private var period = 1 // 0:日 1:周 2:月
    private let periods = ["日", "周", "月"]

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let chartView = LineChartView()

    override func setupUI() {
        title = "血压管理"
        view.backgroundColor = .fdBg

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let content = UIView()
        scrollView.addSubview(content)
        content.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let pad: CGFloat = 16

        // Segmented control
        let seg = UISegmentedControl(items: periods)
        seg.selectedSegmentIndex = period
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(periodChanged(_:)), for: .valueChanged)
        content.addSubview(seg)
        seg.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(36)
        }

        // Chart
        let chartCard = buildChartCard()
        content.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in
            make.top.equalTo(seg.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.height.equalTo(220)
        }

        // Stats
        let avgSys = records.map(\.sys).reduce(0, +) / records.count
        let avgDia = records.map(\.dia).reduce(0, +) / records.count
        let statsRow = buildStatsRow(avgSys: avgSys, avgDia: avgDia)
        content.addSubview(statsRow)
        statsRow.snp.makeConstraints { make in
            make.top.equalTo(chartCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(pad)
        }

        // Records list
        let recordsCard = buildRecordsCard()
        content.addSubview(recordsCard)
        recordsCard.snp.makeConstraints { make in
            make.top.equalTo(statsRow.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(pad)
            make.bottom.equalToSuperview().offset(-20)
        }

        loadChart()
    }

    // MARK: - Chart Card

    private func buildChartCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let title = UILabel()
        title.text = "血压趋势"
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .fdText

        // Legend
        let legendStack = UIStackView()
        legendStack.axis = .horizontal
        legendStack.spacing = 16
        for (color, label) in [(UIColor(hexString: "#FF7A50"), "收缩压"), (UIColor(hexString: "#6B9FE4"), "舒张压")] {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
            let lbl = UILabel(); lbl.text = label; lbl.font = .systemFont(ofSize: 12); lbl.textColor = .fdSubtext
            legendStack.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(8) }
            legendStack.addArrangedSubview(lbl)
        }

        chartView.applyFundeStyle()
        chartView.legend.enabled = false

        card.addSubview(title)
        card.addSubview(legendStack)
        card.addSubview(chartView)

        title.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        legendStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        chartView.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }

        return card
    }

    private func loadChart() {
        let sysEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: Double($0.1.sys)) }
        let diaEntries = records.enumerated().map { ChartDataEntry(x: Double($0.0), y: Double($0.1.dia)) }

        let sysDataSet = LineChartView.makeFundeDataSet(entries: sysEntries, label: "收缩压", color: UIColor(hexString: "#FF7A50"), fillAlpha: 0.06)
        let diaDataSet = LineChartView.makeFundeDataSet(entries: diaEntries, label: "舒张压", color: UIColor(hexString: "#6B9FE4"), fillAlpha: 0.06)

        let data = LineChartData(dataSets: [sysDataSet, diaDataSet])
        chartView.data = data

        // X axis labels
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date))
        chartView.xAxis.granularity = 1
        chartView.xAxis.labelCount = records.count

        // Reference zone
        chartView.leftAxis.axisMinimum = 60
        chartView.leftAxis.axisMaximum = 160
    }

    // MARK: - Stats

    private func buildStatsRow(avgSys: Int, avgDia: Int) -> UIView {
        let row = UIStackView()
        row.distribution = .fillEqually
        row.spacing = 10

        for (label, value, unit) in [
            ("平均收缩压", "\(avgSys)", "mmHg"),
            ("平均舒张压", "\(avgDia)", "mmHg"),
            ("平均心率", "89", "bpm"),
        ] {
            let card = UIView()
            card.backgroundColor = .fdSurface
            card.layer.cornerRadius = 14
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOffset = CGSize(width: 0, height: 1)
            card.layer.shadowRadius = 4
            card.layer.shadowOpacity = 0.02

            let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: 22, weight: .bold); v.textColor = .fdText
            let u = UILabel(); u.text = unit; u.font = .systemFont(ofSize: 11); u.textColor = .fdSubtext
            let l = UILabel(); l.text = label; l.font = .systemFont(ofSize: 12); l.textColor = .fdSubtext

            card.addSubview(v); card.addSubview(u); card.addSubview(l)
            v.snp.makeConstraints { make in make.top.equalToSuperview().offset(14); make.leading.equalToSuperview().offset(12) }
            u.snp.makeConstraints { make in make.lastBaseline.equalTo(v); make.leading.equalTo(v.snp.trailing).offset(2) }
            l.snp.makeConstraints { make in make.top.equalTo(v.snp.bottom).offset(4); make.leading.equalToSuperview().offset(12); make.bottom.equalToSuperview().offset(-14) }
            row.addArrangedSubview(card)
        }
        return row
    }

    // MARK: - Records

    private func buildRecordsCard() -> UIView {
        let container = UIView()
        let title = UILabel(); title.text = "近期记录"; title.font = .systemFont(ofSize: 14, weight: .semibold); title.textColor = .fdSubtext
        container.addSubview(title)
        title.snp.makeConstraints { make in make.top.leading.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor; card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6; card.layer.shadowOpacity = 0.03
        container.addSubview(card)
        card.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(12); make.leading.trailing.equalToSuperview() }

        let mockHistory = [
            ("今天 07:32", "138/88 mmHg", "bluetooth"),
            ("昨天 07:15", "137/87 mmHg", "bluetooth"),
            ("05-16 07:20", "135/86 mmHg", "manual"),
            ("05-15 07:30", "140/90 mmHg", "bluetooth"),
        ]
        var prev: UIView?
        for (i, (time, val, src)) in mockHistory.enumerated() {
            let row = buildRecordRow(time: time, value: val, source: src, showDivider: i < mockHistory.count - 1)
            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) }
            }
            prev = row
        }
        prev?.snp.makeConstraints { make in make.bottom.equalToSuperview().offset(-4) }

        let addBtn = UIButton(type: .system)
        addBtn.setTitle("+ 录入数据", for: .normal)
        addBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        addBtn.setTitleColor(.fdPrimary, for: .normal)
        addBtn.backgroundColor = .fdPrimarySoft; addBtn.layer.cornerRadius = 12
        addBtn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        container.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.top.equalTo(card.snp.bottom).offset(12); make.leading.trailing.equalToSuperview()
            make.height.equalTo(44); make.bottom.equalToSuperview()
        }
        return container
    }

    private func buildRecordRow(time: String, value: String, source: String, showDivider: Bool) -> UIView {
        let row = UIView()
        let t = UILabel(); t.text = time; t.font = .systemFont(ofSize: 13); t.textColor = .fdText
        let v = UILabel(); v.text = value; v.font = .systemFont(ofSize: 14, weight: .semibold); v.textColor = .fdText
        let icon = UIImageView(image: UIImage(systemName: source == "bluetooth" ? "bluetooth" : "hand.point.up.fill"))
        icon.tintColor = .fdMuted; icon.contentMode = .scaleAspectFit
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

    @objc private func periodChanged(_ seg: UISegmentedControl) { period = seg.selectedSegmentIndex }
    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "blood-pressure"]) }
}
