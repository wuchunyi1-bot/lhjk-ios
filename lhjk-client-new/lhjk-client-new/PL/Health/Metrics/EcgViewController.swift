import UIKit
import SnapKit

/// 心电监测
///
/// 参考：
/// - funde-client/prototype/src/views/health/metrics/EcgView.vue
/// - funde-client/docs/page-specs/health-metrics-ecg.page.yaml
///
/// 7 个 region：bluetooth-banner / ecg-result-card / period-tabs / ecg-hr-chart
/// / stats-panel / records-list / add-cta (fixed bottom)
final class EcgViewController: BaseViewController {

    // MARK: - Mock Data

    private let latestConclusion = "窦性心律 · 正常心电图"
    private let latestHR = 76
    private let latestTime = "本月 12 日"

    private let ecgHistory: [(date: String, hr: Int, conclusion: String)] = [
        ("05-17", 76, "正常"), ("05-12", 78, "正常"), ("05-07", 81, "正常"),
        ("05-02", 77, "正常"), ("04-27", 79, "正常"),
    ]

    private let records: [(time: String, value: String, source: String)] = [
        ("本月 12 日 09:15", "正常窦性心律 76bpm", "bluetooth"),
        ("05-02 09:00",     "正常窦性心律 78bpm", "bluetooth"),
        ("04-27 08:45",     "正常窦性心律 81bpm", "manual"),
    ]

    // MARK: - ECG Waveform (Demo)

    private let ecgChartView = ECGChartView()
    private let ecgSimulator = ECGSimulator(heartRate: 75, sampleRate: 250)
    private var demoDataTimer: Timer?

    // 渐变图层引用（viewDidLayoutSubviews 中更新 frame）
    private let resultCardGradient = CAGradientLayer()
    private weak var resultCardView: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        startDemoIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ecgChartView.startRendering()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ecgChartView.stopRendering()
    }

    deinit { stopDemo() }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let card = resultCardView {
            resultCardGradient.frame = card.bounds
        }
    }

    // MARK: - UI

    override func setupUI() {
        title = "心电监测"
        view.backgroundColor = .fdBg

        // ---- 底部固定按钮（add-cta，不跟随滚动）----
        let fixedBtn = makeFixedButton()

        // ---- 可滚动内容区 ----
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(fixedBtn.snp.top)
        }

        let c = UIView()
        scroll.addSubview(c)
        c.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide)
            make.width.equalTo(scroll.frameLayoutGuide)
        }

        let p: CGFloat = 16

        // ---- Region 1: Bluetooth Banner (P1 预留) ----
        let btBanner = makeBluetoothBanner()
        c.addSubview(btBanner)
        btBanner.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(p)
        }

        // ---- Region 2: ECG Result Card (blue gradient) ----
        let resultCard = makeResultCard()
        c.addSubview(resultCard)
        resultCard.snp.makeConstraints { make in
            make.top.equalTo(btBanner.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(p)
        }

        // ---- Region 3: Period Tabs + Date Nav ----
        let seg = makeSeg(["日", "周", "月"])
        seg.selectedSegmentIndex = 2
        c.addSubview(seg)
        seg.snp.makeConstraints { make in
            make.top.equalTo(resultCard.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(p)
            make.height.equalTo(36)
        }

        let dateNav = makeDateNav()
        c.addSubview(dateNav)
        dateNav.snp.makeConstraints { make in
            make.top.equalTo(seg.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }

        // ---- Region 4: HR Trend Bars ----
        let trendCard = makeTrendCard()
        c.addSubview(trendCard)
        trendCard.snp.makeConstraints { make in
            make.top.equalTo(dateNav.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(p)
        }

        // ---- Region 5: Stats Panel ----
        let statsPanel = makeStatsPanel()
        c.addSubview(statsPanel)
        statsPanel.snp.makeConstraints { make in
            make.top.equalTo(trendCard.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(p)
        }

        // ---- Region 6: Records List ----
        let recSection = makeRecordsSection()
        c.addSubview(recSection)
        recSection.snp.makeConstraints { make in
            make.top.equalTo(statsPanel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(p)
        }

        // ---- 滚动区域底部锚点 ----
        recSection.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Region 1: Bluetooth Banner

    private func makeBluetoothBanner() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#EBF5FB")
        v.layer.cornerRadius = 10

        let icon = UIImageView(image: UIImage(systemName: "bluetooth"))
        icon.tintColor = UIColor(hexString: "#3d6fb8")

        let lbl = UILabel()
        lbl.text = "ECG 设备未连接"
        lbl.font = .fdCaption
        lbl.textColor = UIColor(hexString: "#3d6fb8")

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(hexString: "#3d6fb8").withAlphaComponent(0.5)

        v.addSubview(icon)
        v.addSubview(lbl)
        v.addSubview(arrow)
        icon.snp.makeConstraints { $0.left.equalToSuperview().offset(12); $0.centerY.equalToSuperview(); $0.size.equalTo(18) }
        lbl.snp.makeConstraints { $0.left.equalTo(icon.snp.right).offset(8); $0.centerY.equalToSuperview() }
        arrow.snp.makeConstraints { $0.right.equalToSuperview().offset(-12); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }
        v.snp.makeConstraints { $0.height.equalTo(42) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBluetoothBanner))
        v.addGestureRecognizer(tap)
        return v
    }

    // MARK: - Region 2: Result Card

    private func makeResultCard() -> UIView {
        let card = UIView()
        resultCardView = card
        card.layer.cornerRadius = 20
        card.clipsToBounds = true

        // 蓝色渐变背景 #1a5276 → #2e86c1
        resultCardGradient.colors = [
            UIColor(hexString: "#1a5276").cgColor,
            UIColor(hexString: "#2e86c1").cgColor
        ]
        resultCardGradient.startPoint = CGPoint(x: 0, y: 0)
        resultCardGradient.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(resultCardGradient, at: 0)

        // "最新报告" badge + 时间
        let badge = tag("最新报告", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let time = UILabel()
        time.text = latestTime
        time.font = .fdCaption
        time.textColor = UIColor.white.withAlphaComponent(0.75)

        // 结论
        let conclusion = UILabel()
        conclusion.text = latestConclusion
        conclusion.font = UIFont.fdFont(ofSize: 20, weight: .bold)
        conclusion.textColor = .white

        // 心率
        let hr = UILabel()
        hr.text = "心率：\(latestHR) bpm"
        hr.font = .fdBody
        hr.textColor = UIColor.white.withAlphaComponent(0.85)

        // ECG 波形图
        configureECGChart()
        ecgChartView.layer.cornerRadius = 12
        ecgChartView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        card.addSubview(badge)
        card.addSubview(time)
        card.addSubview(conclusion)
        card.addSubview(hr)
        card.addSubview(ecgChartView)

        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(18) }
        time.snp.makeConstraints { $0.centerY.equalTo(badge); $0.trailing.equalToSuperview().offset(-18) }
        conclusion.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(18) }
        hr.snp.makeConstraints { $0.top.equalTo(conclusion.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(18) }
        ecgChartView.snp.makeConstraints { make in
            make.top.equalTo(hr.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(18)
            make.height.equalTo(150)
            make.bottom.equalToSuperview().offset(-18)
        }

        return card
    }

    private func configureECGChart() {
        // 网格 — 白色半透明，在蓝色渐变背景上可见
        ecgChartView.gridLineColor = UIColor.white.withAlphaComponent(0.14)
        ecgChartView.gridThinLineWidth = 0.3
        ecgChartView.gridBoldLineWidth = 0.6
        ecgChartView.smallSquareSize = 4
        ecgChartView.squaresPerLargeSquare = 5

        // 波形 — #7dd6a0 绿色，匹配 Vue 原型 SVG stroke
        ecgChartView.waveformColor = UIColor(hexString: "#7DD6A0")
        ecgChartView.waveformLineWidth = 1.2

        // 临床参数
        ecgChartView.paperSpeed = 25
        ecgChartView.verticalRange = -1.5...1.5
        ecgChartView.pointSpacing = 0.4
        ecgChartView.trailingMargin = 16
    }

    // MARK: - Region 3: Segment + Date Nav

    private func makeDateNav() -> UIView {
        let row = UIView()
        let left = UIButton(type: .system)
        left.setTitle("‹", for: .normal)
        left.titleLabel?.font = UIFont.fdFont(ofSize: 18, weight: .medium)
        left.setTitleColor(.fdSubtext, for: .normal)

        let range = UILabel()
        range.text = "04/01 – 05/17"
        range.font = .fdCaption
        range.textColor = .fdSubtext

        let right = UIButton(type: .system)
        right.setTitle("›", for: .normal)
        right.titleLabel?.font = UIFont.fdFont(ofSize: 18, weight: .medium)
        right.setTitleColor(.fdSubtext, for: .normal)

        row.addSubview(left)
        row.addSubview(range)
        row.addSubview(right)
        left.snp.makeConstraints { $0.left.centerY.equalToSuperview() }
        range.snp.makeConstraints { $0.center.equalToSuperview() }
        right.snp.makeConstraints { $0.right.centerY.equalToSuperview() }
        row.snp.makeConstraints { $0.height.equalTo(28) }
        return row
    }

    // MARK: - Region 4: HR Trend Bars

    private func makeTrendCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()

        let title = UILabel()
        title.text = "历次测量心率趋势"
        title.font = .fdCaptionSemibold
        title.textColor = .fdSubtext
        card.addSubview(title)
        title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }

        var prev: UIView = title
        for (i, item) in ecgHistory.enumerated() {
            let row = UIView()

            let dateLbl = UILabel()
            dateLbl.text = item.date
            dateLbl.font = .fdCaption
            dateLbl.textColor = .fdSubtext
            dateLbl.textAlignment = .right

            let barBg = UIView()
            barBg.backgroundColor = .fdBg2
            barBg.layer.cornerRadius = 4

            let barFill = UIView()
            barFill.backgroundColor = UIColor(hexString: "#2E86C1")
            barFill.layer.cornerRadius = 4
            barBg.addSubview(barFill)

            let valLbl = UILabel()
            valLbl.text = "\(item.hr) bpm"
            valLbl.font = .fdCaptionSemibold
            valLbl.textColor = .fdText

            let tagView = tag(item.conclusion, bg: UIColor(hexString: "#F0FAF4"), fg: UIColor(hexString: "#52B96A"))

            row.addSubview(dateLbl)
            row.addSubview(barBg)
            row.addSubview(valLbl)
            row.addSubview(tagView)

            dateLbl.snp.makeConstraints { $0.left.centerY.equalToSuperview(); $0.width.equalTo(44) }
            barBg.snp.makeConstraints { make in
                make.left.equalTo(dateLbl.snp.right).offset(8)
                make.centerY.equalToSuperview()
                make.height.equalTo(8)
            }
            barFill.snp.makeConstraints { make in
                make.left.top.bottom.equalToSuperview()
                make.width.equalTo(barBg).multipliedBy(min(Double(item.hr) / 120.0, 1.0))
            }
            valLbl.snp.makeConstraints { $0.left.equalTo(barBg.snp.right).offset(8); $0.centerY.equalToSuperview(); $0.width.equalTo(52) }
            tagView.snp.makeConstraints { $0.right.centerY.equalToSuperview() }

            if i < ecgHistory.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .fdBorder
                row.addSubview(divider)
                divider.snp.makeConstraints { $0.left.right.bottom.equalToSuperview(); $0.height.equalTo(1) }
            }

            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                make.top.equalTo(prev.snp.bottom).offset(i == 0 ? 12 : 10)
                make.height.equalTo(36)
            }
            prev = row
        }
        prev.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-16) }
        return card
    }

    // MARK: - Region 5: Stats Panel

    private func makeStatsPanel() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        func statItem(value: String, label: String, valueColor: UIColor = .fdText) -> UIView {
            let v = UIView()
            let vl = UILabel()
            vl.text = value
            vl.font = UIFont.fdFont(ofSize: 28, weight: .bold)
            vl.textColor = valueColor
            vl.textAlignment = .center
            let ll = UILabel()
            ll.text = label
            ll.font = .fdMicro
            ll.textColor = .fdSubtext
            ll.textAlignment = .center
            ll.numberOfLines = 2
            v.addSubview(vl)
            v.addSubview(ll)
            vl.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.height.equalTo(34) }
            ll.snp.makeConstraints { $0.top.equalTo(vl.snp.bottom).offset(2); $0.centerX.bottom.equalToSuperview() }
            return v
        }

        let historyCount = ecgHistory.count
        let allNormal = ecgHistory.allSatisfy { $0.conclusion == "正常" }
        let rhythmStatus = allNormal ? "正常" : "异常"
        let rhythmColor: UIColor = allNormal ? UIColor(hexString: "#52B96A") : UIColor(hexString: "#E74C3C")

        let s1 = statItem(value: "\(latestHR)", label: "最近心率\n(bpm)")
        let s2 = statItem(value: "\(historyCount)", label: "历史测量\n(次)")
        let s3 = statItem(value: rhythmStatus, label: "心律状态", valueColor: rhythmColor)

        // 分隔线
        let d1 = UIView(); d1.backgroundColor = .fdBorder
        let d2 = UIView(); d2.backgroundColor = .fdBorder
        [d1, d2].forEach {
            $0.snp.makeConstraints { $0.width.equalTo(1) }
        }

        stack.addArrangedSubview(s1)
        stack.addArrangedSubview(d1)
        stack.addArrangedSubview(s2)
        stack.addArrangedSubview(d2)
        stack.addArrangedSubview(s3)

        d1.snp.makeConstraints { $0.height.equalTo(40) }
        d2.snp.makeConstraints { $0.height.equalTo(40) }

        card.snp.makeConstraints { $0.height.equalTo(88) }
        return card
    }

    // MARK: - Region 6: Records List

    private func makeRecordsSection() -> UIView {
        let ctr = UIView()

        // Section header
        let bar = UIView()
        bar.backgroundColor = UIColor(hexString: "#2E86C1")
        bar.layer.cornerRadius = 2
        let header = UILabel()
        header.text = "心电记录"
        header.font = .fdBodySemibold
        header.textColor = .fdSubtext
        ctr.addSubview(bar)
        ctr.addSubview(header)
        bar.snp.makeConstraints { $0.left.centerY.equalTo(header); $0.width.equalTo(3); $0.height.equalTo(16) }
        header.snp.makeConstraints { $0.top.left.equalToSuperview().offset(4); $0.left.equalTo(bar.snp.right).offset(8) }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.addFundeShadow()
        ctr.addSubview(card)
        card.snp.makeConstraints { $0.top.equalTo(header.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview() }

        var prev: UIView?
        for (i, rec) in records.enumerated() {
            let row = UIView()

            let tl = UILabel()
            tl.text = rec.time
            tl.font = .fdCaption
            tl.textColor = .fdText

            let vl = UILabel()
            vl.text = rec.value
            vl.font = .fdBodySemibold
            vl.textColor = .fdText

            // 来源标签：蓝牙(蓝) / 手动(灰)
            let srcTag = UILabel()
            srcTag.text = rec.source == "bluetooth" ? "蓝牙记录" : "手动记录"
            srcTag.font = .fdMicro
            srcTag.textAlignment = .center
            srcTag.layer.cornerRadius = 999
            srcTag.clipsToBounds = true
            if rec.source == "bluetooth" {
                srcTag.backgroundColor = UIColor(hexString: "#E8F4FD")
                srcTag.textColor = UIColor(hexString: "#3D6FB8")
            } else {
                srcTag.backgroundColor = UIColor(hexString: "#F5F5F5")
                srcTag.textColor = UIColor(hexString: "#999999")
            }

            row.addSubview(tl)
            row.addSubview(vl)
            row.addSubview(srcTag)

            tl.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.left.equalToSuperview() }
            vl.snp.makeConstraints { $0.top.equalTo(tl.snp.bottom).offset(2); $0.left.equalToSuperview(); $0.bottom.equalToSuperview().offset(-12) }
            srcTag.snp.makeConstraints { $0.right.centerY.equalToSuperview(); $0.width.equalTo(64); $0.height.equalTo(20) }

            if i < records.count - 1 {
                let d = UIView()
                d.backgroundColor = .fdBorder
                row.addSubview(d)
                d.snp.makeConstraints { $0.left.right.bottom.equalToSuperview(); $0.height.equalTo(1) }
            }

            card.addSubview(row)
            row.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                if let p = prev {
                    make.top.equalTo(p.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(4)
                }
            }
            prev = row
        }
        prev?.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-4) }

        ctr.snp.makeConstraints { $0.bottom.equalTo(card) }
        return ctr
    }

    // MARK: - Region 7: Fixed Bottom Button

    private func makeFixedButton() -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("手动输入数据", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.fdFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = UIColor(hexString: "#FF7A50")
        btn.layer.cornerRadius = 14

        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(52)
        }

        btn.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        return btn
    }

    // MARK: - Demo Data

    private func startDemoIfNeeded() {
        let batchSize = 4
        let interval = Double(batchSize) / ecgSimulator.sampleRate
        demoDataTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.ecgChartView.append(contentsOf: self.ecgSimulator.nextSamples(batchSize))
        }
    }

    private func stopDemo() {
        demoDataTimer?.invalidate()
        demoDataTimer = nil
    }

    // MARK: - Actions

    @objc private func addRecord() {
        Router.shared.push("/health/metrics/ecg/add", params: ["key": "ecg"])
    }

    @objc private func tapBluetoothBanner() {
        Router.shared.push("/me/devices")
    }

    // MARK: - Helpers

    private func makeSeg(_ items: [String]) -> UISegmentedControl {
        let s = UISegmentedControl(items: items)
        s.selectedSegmentIndex = 2
        s.selectedSegmentTintColor = .fdPrimary
        s.backgroundColor = .fdBg2
        s.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        s.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        return s
    }

    private func tag(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .fdMicro
        l.textColor = fg
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
