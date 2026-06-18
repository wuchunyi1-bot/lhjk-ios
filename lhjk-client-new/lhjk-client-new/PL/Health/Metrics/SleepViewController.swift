import UIKit
import SnapKit
import DGCharts

/// 睡眠监测 — 摘要卡 + 睡眠结构条 + 柱状图趋势
/// 参考 funde-client: SleepView.vue
final class SleepViewController: BaseViewController {

    // MARK: - Data

    private struct SleepRecord {
        let date: String; let total: Double; let deep: Double; let score: Int
    }
    private var records: [SleepRecord] = [
        SleepRecord(date: "05-11", total: 6.8, deep: 1.5, score: 75),
        SleepRecord(date: "05-12", total: 7.0, deep: 1.7, score: 78),
        SleepRecord(date: "05-13", total: 6.2, deep: 1.2, score: 68),
        SleepRecord(date: "05-14", total: 7.5, deep: 2.0, score: 85),
        SleepRecord(date: "05-15", total: 7.1, deep: 1.8, score: 80),
        SleepRecord(date: "05-16", total: 6.9, deep: 1.6, score: 77),
        SleepRecord(date: "05-17", total: 7.2, deep: 1.8, score: 82),
    ]

    private let latest = (total: 7.2, deep: 1.8, light: 3.6, rem: 1.4, awake: 0.4, score: 82, bedtime: "23:10", wakeup: "06:22")

    // Colors
    private let stageColors = (
        deep:  UIColor(hexString: "#2D4A8A"),
        light: UIColor(hexString: "#6B9FE4"),
        rem:   UIColor(hexString: "#9B7DEA"),
        awake: UIColor(hexString: "#E8E8E8")
    )

    private let barChartView = BarChartView()

    // MARK: - Lifecycle

    override func setupUI() {
        title = "睡眠监测"
        view.backgroundColor = .fdBg

        let scroll = UIScrollView(); view.addSubview(scroll); scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let content = UIView(); scroll.addSubview(content); content.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        let pad: CGFloat = 16

        // 1. Summary card
        let summary = buildSummaryCard()
        content.addSubview(summary)
        summary.snp.makeConstraints { make in make.top.equalToSuperview().offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // 2. Sleep stages
        let stages = buildStagesCard()
        content.addSubview(stages)
        stages.snp.makeConstraints { make in make.top.equalTo(summary.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // 3. Period segment
        let seg = makePeriodSegment()
        content.addSubview(seg)
        seg.snp.makeConstraints { make in make.top.equalTo(stages.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(36) }

        // 4. Bar chart
        let chartCard = buildChartCard()
        content.addSubview(chartCard)
        chartCard.snp.makeConstraints { make in make.top.equalTo(seg.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(200) }

        // 5. Stats row
        let stats = buildStatsRow()
        content.addSubview(stats)
        stats.snp.makeConstraints { make in make.top.equalTo(chartCard.snp.bottom).offset(12); make.leading.trailing.equalToSuperview().inset(pad) }

        // 6. Records
        let recCard = buildRecordsCard()
        content.addSubview(recCard)
        recCard.snp.makeConstraints { make in make.top.equalTo(stats.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad) }

        // 7. Advisor note
        let note = buildAdvisorNote()
        content.addSubview(note)
        note.snp.makeConstraints { make in make.top.equalTo(recCard.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad) }

        // 8. Add button
        let btn = UIButton(type: .system)
        btn.setTitle("手动录入睡眠", for: .normal)
        btn.titleLabel?.font = .fdBodyBold
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary; btn.layer.cornerRadius = 14
        btn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        content.addSubview(btn)
        btn.snp.makeConstraints { make in make.top.equalTo(note.snp.bottom).offset(16); make.leading.trailing.equalToSuperview().inset(pad); make.height.equalTo(52); make.bottom.equalToSuperview().offset(-20) }

        loadChart()
    }

    // MARK: - Score Color

    private func scoreColor(_ s: Int) -> UIColor {
        if s >= 80 { return UIColor(hexString: "#52B96A") }
        if s >= 60 { return UIColor(hexString: "#F5A623") }
        return UIColor(hexString: "#E45454")
    }

    // MARK: - Summary Card

    private func buildSummaryCard() -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(hexString: "#2D4A8A")
        card.layer.cornerRadius = 24

        let label = UILabel(); label.text = "昨晚"; label.font = .fdCaption; label.textColor = UIColor.white.withAlphaComponent(0.8)
        let total = UILabel(); total.text = "\(latest.total)"; total.font = .fdFont(ofSize: 38, weight: .bold); total.textColor = .white
        let unit = UILabel(); unit.text = "小时"; unit.font = .fdBody; unit.textColor = UIColor.white.withAlphaComponent(0.85)
        let time = UILabel(); time.text = "\(latest.bedtime) – \(latest.wakeup)"; time.font = .fdCaption; time.textColor = UIColor.white.withAlphaComponent(0.75)

        // Score ring
        let ring = UIView()
        ring.layer.cornerRadius = 32; ring.layer.borderWidth = 3
        ring.layer.borderColor = scoreColor(latest.score).cgColor
        ring.backgroundColor = UIColor.white.withAlphaComponent(0.12)

        let scoreLbl = UILabel(); scoreLbl.text = "\(latest.score)"; scoreLbl.font = .fdH2; scoreLbl.textColor = scoreColor(latest.score)
        let sub = UILabel(); sub.text = "睡眠分"; sub.font = .fdMicro; sub.textColor = UIColor.white.withAlphaComponent(0.85)
        ring.addSubview(scoreLbl); ring.addSubview(sub)
        scoreLbl.snp.makeConstraints { make in make.centerX.equalToSuperview(); make.centerY.equalToSuperview().offset(-6) }
        sub.snp.makeConstraints { make in make.centerX.equalToSuperview(); make.top.equalTo(scoreLbl.snp.bottom) }

        card.addSubview(label); card.addSubview(total); card.addSubview(unit); card.addSubview(time); card.addSubview(ring)
        label.snp.makeConstraints { make in make.top.leading.equalToSuperview().inset(20) }
        total.snp.makeConstraints { make in make.top.equalTo(label.snp.bottom).offset(4); make.leading.equalToSuperview().inset(20) }
        unit.snp.makeConstraints { make in make.lastBaseline.equalTo(total).offset(-4); make.leading.equalTo(total.snp.trailing).offset(4) }
        time.snp.makeConstraints { make in make.top.equalTo(total.snp.bottom).offset(4); make.leading.equalToSuperview().inset(20); make.bottom.equalToSuperview().offset(-20) }
        ring.snp.makeConstraints { make in make.centerY.equalToSuperview(); make.trailing.equalToSuperview().offset(-20); make.size.equalTo(64) }

        return card
    }

    // MARK: - Stages Card

    private func buildStagesCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()

        let title = UILabel(); title.text = "睡眠结构"; title.font = .fdCaptionSemibold; title.textColor = .fdSubtext

        // Stage bar
        let totalHours = latest.deep + latest.light + latest.rem + latest.awake
        let bar = UIStackView(); bar.axis = .horizontal; bar.spacing = 1; bar.distribution = .fillProportionally

        let stages: [(Double, UIColor)] = [(latest.deep, stageColors.deep), (latest.light, stageColors.light), (latest.rem, stageColors.rem), (latest.awake, stageColors.awake)]
        for (hours, color) in stages {
            let block = UIView(); block.backgroundColor = color
            bar.addArrangedSubview(block)
            block.snp.makeConstraints { make in make.width.equalTo(bar).multipliedBy(hours / totalHours).priority(.high) }
        }

        // Legend
        let legend = UIStackView(); legend.axis = .horizontal; legend.spacing = 12
        let items = [("深睡", latest.deep, stageColors.deep), ("浅睡", latest.light, stageColors.light), ("REM", latest.rem, stageColors.rem), ("清醒", latest.awake, stageColors.awake)]
        for (name, hours, color) in items {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 3
            let lbl = UILabel(); lbl.text = "\(name) \(hours)h"; lbl.font = .fdCaption; lbl.textColor = .fdSubtext
            legend.addArrangedSubview(dot); dot.snp.makeConstraints { $0.size.equalTo(10) }
            legend.addArrangedSubview(lbl)
        }

        card.addSubview(title); card.addSubview(bar); card.addSubview(legend)
        title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }
        bar.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(10); make.leading.trailing.equalToSuperview().inset(16); make.height.equalTo(16) }
        legend.snp.makeConstraints { make in make.top.equalTo(bar.snp.bottom).offset(10); make.leading.trailing.equalToSuperview().inset(16); make.bottom.equalToSuperview().offset(-14) }

        return card
    }

    // MARK: - Bar Chart

    private func buildChartCard() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()

        let title = UILabel(); title.text = "睡眠评分趋势（≥80 优秀）"; title.font = .fdCaption; title.textColor = .fdSubtext

        barChartView.applyFundeStyle()
        barChartView.legend.enabled = false
        barChartView.rightAxis.enabled = false
        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = 100
        barChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: records.map(\.date))
        barChartView.xAxis.granularity = 1

        card.addSubview(title); card.addSubview(barChartView)
        title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }
        barChartView.snp.makeConstraints { make in make.top.equalTo(title.snp.bottom).offset(8); make.leading.trailing.bottom.equalToSuperview().inset(8) }

        return card
    }

    private func loadChart() {
        let entries = records.enumerated().map { BarChartDataEntry(x: Double($0.0), y: Double($0.1.score)) }

        let ds = BarChartDataSet(entries: entries, label: "睡眠分")
        ds.drawValuesEnabled = true
        ds.valueFont = .fdMicro
        ds.valueTextColor = .fdSubtext
        ds.highlightEnabled = false

        // Color each bar by score
        ds.colors = records.map { scoreColor($0.score) }
        ds.valueFormatter = DefaultValueFormatter(decimals: 0)

        // Rounded top corners
        let data = BarChartData(dataSet: ds)
        data.barWidth = 0.4
        barChartView.data = data

        // Reference line at 80
        let refLine = ChartLimitLine(limit: 80, label: "优秀")
        refLine.lineColor = UIColor(hexString: "#52B96A").withAlphaComponent(0.3)
        refLine.lineWidth = 1
        refLine.lineDashLengths = [4, 3]
        refLine.valueFont = .fdMicro
        refLine.valueTextColor = UIColor(hexString: "#52B96A")
        barChartView.leftAxis.addLimitLine(refLine)

        barChartView.leftAxis.axisMinimum = 0
        barChartView.leftAxis.axisMaximum = 100
    }

    // MARK: - Stats Row

    private func buildStatsRow() -> UIView {
        let row = UIStackView(); row.distribution = .fillEqually; row.alignment = .center

        let items = [
            ("\(latest.total)", "总时长\n(小时)", UIColor.fdText),
            ("\(latest.deep)", "深度睡眠\n(小时)", UIColor.fdText),
            ("\(latest.score)", "睡眠评分", scoreColor(latest.score)),
        ]
        for (val, label, color) in items {
            let col = UIStackView(); col.axis = .vertical; col.alignment = .center; col.spacing = 4
            let v = UILabel(); v.text = val; v.font = .fdH2; v.textColor = color
            let l = UILabel(); l.text = label; l.font = .fdCaption; l.textColor = .fdSubtext; l.textAlignment = .center; l.numberOfLines = 0
            col.addArrangedSubview(v); col.addArrangedSubview(l)
            row.addArrangedSubview(col)
        }
        return row
    }

    // MARK: - Records

    private func buildRecordsCard() -> UIView {
        let container = UIView()
        let bar = UIView(); bar.backgroundColor = .fdPrimary; bar.layer.cornerRadius = 2
        let title = UILabel(); title.text = "睡眠记录"; title.font = .fdBodyBold; title.textColor = .fdText
        container.addSubview(bar); container.addSubview(title)
        bar.snp.makeConstraints { make in make.top.leading.equalToSuperview(); make.width.equalTo(3); make.height.equalTo(16) }
        title.snp.makeConstraints { make in make.centerY.equalTo(bar); make.leading.equalTo(bar.snp.trailing).offset(8) }

        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 18; card.addFundeShadow()
        container.addSubview(card)
        card.snp.makeConstraints { make in make.top.equalTo(bar.snp.bottom).offset(10); make.leading.trailing.equalToSuperview() }

        let mockRecords = [
            ("昨晚 23:10 – 06:22", "7.2小时 · 评分 82", "bluetooth"),
            ("05-16 23:30 – 06:27", "6.9小时 · 评分 77", "bluetooth"),
            ("05-15 22:58 – 06:04", "7.1小时 · 评分 80", "bluetooth"),
        ]
        var prev: UIView?
        for (i, (time, val, src)) in mockRecords.enumerated() {
            let row = UIView()
            let t = UILabel(); t.text = time; t.font = .fdCaption; t.textColor = .fdText
            let v = UILabel(); v.text = val; v.font = .fdCaption; v.textColor = .fdSubtext
            let tag = buildTag(src == "bluetooth" ? "蓝牙记录" : "手动记录", isBT: src == "bluetooth")
            row.addSubview(t); row.addSubview(v); row.addSubview(tag)
            t.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview() }
            v.snp.makeConstraints { make in make.top.equalTo(t.snp.bottom).offset(2); make.leading.equalToSuperview(); make.bottom.equalToSuperview().offset(-12) }
            tag.snp.makeConstraints { make in make.trailing.centerY.equalToSuperview() }
            if i < mockRecords.count - 1 {
                let div = UIView(); div.backgroundColor = .fdBorder; row.addSubview(div)
                div.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }
            }
            card.addSubview(row)
            row.snp.makeConstraints { make in make.leading.trailing.equalToSuperview().inset(16); if let p = prev { make.top.equalTo(p.snp.bottom) } else { make.top.equalToSuperview().offset(4) } }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4); $0.bottom.equalTo(card) }

        return container
    }

    // MARK: - Advisor Note

    private func buildAdvisorNote() -> UIView {
        let card = UIView(); card.backgroundColor = .fdSurface; card.layer.cornerRadius = 24; card.addFundeShadow()
        card.layer.borderWidth = 0

        // Left blue border
        let leftBorder = UIView(); leftBorder.backgroundColor = UIColor(hexString: "#2D4A8A"); leftBorder.layer.cornerRadius = 2
        card.addSubview(leftBorder)
        leftBorder.snp.makeConstraints { make in make.leading.equalToSuperview().offset(16); make.top.bottom.equalToSuperview().inset(14); make.width.equalTo(3) }

        let avatar = UIView(); avatar.backgroundColor = UIColor(hexString: "#2D4A8A"); avatar.layer.cornerRadius = 8
        let avatarLbl = UILabel(); avatarLbl.text = "王"; avatarLbl.font = .fdCaptionSemibold; avatarLbl.textColor = .white
        avatar.addSubview(avatarLbl); avatarLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let name = UILabel(); name.text = "王健管师 · 批注"; name.font = .fdBodySemibold; name.textColor = .fdText

        let content = UILabel()
        content.text = "昨晚睡眠质量良好，深度睡眠时长达标。建议保持规律作息，睡前一小时避免使用手机，有助于提升 REM 睡眠比例。"
        content.font = .fdCaption; content.textColor = .fdSubtext; content.numberOfLines = 0

        card.addSubview(avatar); card.addSubview(name); card.addSubview(content)
        avatar.snp.makeConstraints { make in make.top.equalToSuperview().offset(14); make.leading.equalTo(leftBorder.snp.trailing).offset(12); make.size.equalTo(32) }
        name.snp.makeConstraints { make in make.centerY.equalTo(avatar); make.leading.equalTo(avatar.snp.trailing).offset(10) }
        content.snp.makeConstraints { make in make.top.equalTo(avatar.snp.bottom).offset(10); make.leading.equalTo(avatar); make.trailing.equalToSuperview().offset(-16); make.bottom.equalToSuperview().offset(-14) }

        return card
    }

    private func buildTag(_ text: String, isBT: Bool) -> UIView {
        let v = UIView(); v.backgroundColor = isBT ? UIColor(hexString: "#E8F4FD") : UIColor(hexString: "#F5F5F5"); v.layer.cornerRadius = 999
        let l = UILabel(); l.text = text; l.font = .fdMicro; l.textColor = isBT ? UIColor(hexString: "#3D6FB8") : UIColor(hexString: "#999999")
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }

    private func makePeriodSegment() -> UISegmentedControl {
        let seg = UISegmentedControl(items: ["日", "周", "月"])
        seg.selectedSegmentIndex = 1
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
        return seg
    }

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "sleep"]) }
}
