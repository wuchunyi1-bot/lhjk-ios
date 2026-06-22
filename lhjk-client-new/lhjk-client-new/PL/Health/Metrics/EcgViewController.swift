import UIKit
import SnapKit

// MARK: - Section

private enum ECGSection: Int, CaseIterable {
    case bluetoothBanner
    case resultCard
    case periodTabs
    case trendChart
    case statsPanel
    case recordsList
}

// MARK: - Card Position (用于卡片组首尾圆角)

private enum CardPosition {
    case first, middle, last, single
}

// MARK: - Reuse IDs

private let kBanCell = "banner", kResCell = "result", kSegCell = "segment"
private let kTrdCell = "trend",  kStaCell = "stat",   kRecCell = "record"

// ============================================================================
// MARK: - Cells
// ============================================================================

// MARK: Bluetooth Banner

private final class ECGBannerCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        let wrap = UIView()
        wrap.backgroundColor = UIColor(hexString: "#EBF5FB")
        wrap.layer.cornerRadius = 10
        contentView.addSubview(wrap)
        wrap.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        let icon = UIImageView(image: UIImage(systemName: "bluetooth"))
        icon.tintColor = UIColor(hexString: "#3d6fb8")
        wrap.addSubview(icon)
        icon.snp.makeConstraints { $0.left.equalToSuperview().offset(12); $0.centerY.equalToSuperview(); $0.size.equalTo(18) }

        let lbl = UILabel(); lbl.text = "ECG 设备未连接"
        lbl.font = .fdCaption; lbl.textColor = UIColor(hexString: "#3d6fb8")
        wrap.addSubview(lbl)
        lbl.snp.makeConstraints { $0.left.equalTo(icon.snp.right).offset(8); $0.centerY.equalToSuperview() }

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(hexString: "#3d6fb8").withAlphaComponent(0.5)
        wrap.addSubview(arrow)
        arrow.snp.makeConstraints { $0.right.equalToSuperview().offset(-12); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Result Card

private final class ECGResultCardCell: UITableViewCell {
    let waveView = ECGChartView()
    private let gradient = CAGradientLayer()
    private weak var cardContainer: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        // 卡片容器（16pt 水平边距）
        let card = UIView()
        cardContainer = card
        card.layer.cornerRadius = 20; card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        gradient.colors = [UIColor(hexString: "#1a5276").cgColor, UIColor(hexString: "#2e86c1").cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0); gradient.endPoint = CGPoint(x: 1, y: 1)
        card.layer.insertSublayer(gradient, at: 0)

        let edge = 18.0
        let badge = tag("最新报告", bg: UIColor.white.withAlphaComponent(0.2), fg: .white)
        let time = UILabel(); time.text = "本月 12 日"
        time.font = .fdCaption; time.textColor = UIColor.white.withAlphaComponent(0.75)

        let c = UILabel(); c.text = "窦性心律 · 正常心电图"
        c.font = UIFont.fdFont(ofSize: 20, weight: .bold); c.textColor = .white

        let h = UILabel(); h.text = "心率：76 bpm"
        h.font = .fdBody; h.textColor = UIColor.white.withAlphaComponent(0.85)

        // 波形
        waveView.gridLineColor = UIColor.white.withAlphaComponent(0.14)
        waveView.gridThinLineWidth = 0.3; waveView.gridBoldLineWidth = 0.6
        waveView.smallSquareSize = 4; waveView.squaresPerLargeSquare = 5
        waveView.waveformColor = UIColor(hexString: "#7DD6A0")
        waveView.waveformLineWidth = 1.2; waveView.paperSpeed = 25
        waveView.verticalRange = -1.5...1.5; waveView.pointSpacing = 0.4
        waveView.trailingMargin = 16
        waveView.layer.cornerRadius = 12
        waveView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        [badge, time, c, h, waveView].forEach { card.addSubview($0) }
        badge.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(edge) }
        time.snp.makeConstraints { $0.centerY.equalTo(badge); $0.trailing.equalToSuperview().offset(-edge) }
        c.snp.makeConstraints { $0.top.equalTo(badge.snp.bottom).offset(8); $0.leading.equalToSuperview().inset(edge) }
        h.snp.makeConstraints { $0.top.equalTo(c.snp.bottom).offset(4); $0.leading.equalToSuperview().inset(edge) }
        waveView.snp.makeConstraints { make in
            make.top.equalTo(h.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(edge)
            make.height.equalTo(150)
            make.bottom.equalToSuperview().offset(-edge)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() {
        super.layoutSubviews()
        if let card = cardContainer { gradient.frame = card.bounds }
    }

    private func tag(_ t: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = t; l.font = .fdMicro; l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}

// MARK: Segment

private final class ECGSegmentCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        let seg = UISegmentedControl(items: ["日", "周", "月"]); seg.selectedSegmentIndex = 2
        seg.selectedSegmentTintColor = .fdPrimary; seg.backgroundColor = .fdBg2
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        contentView.addSubview(seg)
        seg.snp.makeConstraints { $0.top.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(36) }

        let (l, rng, r) = (UIButton(type: .system), UILabel(), UIButton(type: .system))
        [l, r].forEach { b in b.setTitleColor(.fdSubtext, for: .normal); b.titleLabel?.font = UIFont.fdFont(ofSize: 18, weight: .medium) }
        l.setTitle("‹", for: .normal); r.setTitle("›", for: .normal)
        rng.text = "04/01 – 05/17"; rng.font = .fdCaption; rng.textColor = .fdSubtext

        [l, rng, r].forEach { contentView.addSubview($0) }
        l.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.top.equalTo(seg.snp.bottom).offset(10); $0.bottom.equalToSuperview().offset(-4) }
        rng.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalTo(l) }
        r.snp.makeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalTo(l) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Trend Bar

private final class ECGTrendCell: UITableViewCell {
    private let cardBg = UIView()
    private let titleLbl = UILabel()
    private let dateLbl = UILabel(), barBg = UIView(), barFill = UIView(), valLbl = UILabel()
    private let tagWrap = UIView(), divider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        titleLbl.font = .fdCaptionSemibold; titleLbl.textColor = .fdSubtext
        titleLbl.text = "历次测量心率趋势"

        dateLbl.font = .fdCaption; dateLbl.textColor = .fdSubtext; dateLbl.textAlignment = .right
        barBg.backgroundColor = .fdBg2; barBg.layer.cornerRadius = 4
        barFill.backgroundColor = UIColor(hexString: "#2E86C1"); barFill.layer.cornerRadius = 4
        valLbl.font = .fdCaptionSemibold; valLbl.textColor = .fdText
        divider.backgroundColor = .fdBorder

        barBg.addSubview(barFill)
        [titleLbl, dateLbl, barBg, valLbl, tagWrap, divider].forEach { cardBg.addSubview($0) }

        titleLbl.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.left.equalToSuperview().offset(16) }
        dateLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.width.equalTo(44) }
        barBg.snp.makeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.height.equalTo(8) }
        barFill.snp.makeConstraints { $0.left.top.bottom.equalToSuperview() }
        valLbl.snp.makeConstraints { $0.left.equalTo(barBg.snp.right).offset(8); $0.width.equalTo(52) }
        tagWrap.snp.makeConstraints { $0.right.equalToSuperview().offset(-16) }
        divider.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.right.equalToSuperview().offset(-16); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(date: String, hr: Int, conclusion: String, position: CardPosition) {
        let isFirst = (position == .first || position == .single)
        titleLbl.isHidden = !isFirst

        dateLbl.text = date; valLbl.text = "\(hr) bpm"
        barFill.snp.remakeConstraints { $0.left.top.bottom.equalToSuperview(); $0.width.equalTo(barBg).multipliedBy(min(Double(hr) / 120.0, 1.0)) }

        tagWrap.subviews.forEach { $0.removeFromSuperview() }
        let t = _tag(conclusion, bg: UIColor(hexString: "#F0FAF4"), fg: UIColor(hexString: "#52B96A"))
        tagWrap.addSubview(t); t.snp.makeConstraints { $0.edges.equalToSuperview() }

        // 动态约束：第一行 bar 在 title 下方，其他行 bar 居中
        if isFirst {
            dateLbl.snp.remakeConstraints { $0.left.equalToSuperview().offset(16); $0.top.equalTo(titleLbl.snp.bottom).offset(10); $0.width.equalTo(44); $0.bottom.equalToSuperview().offset(-10) }
            barBg.snp.remakeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.centerY.equalTo(dateLbl); $0.height.equalTo(8) }
        } else {
            dateLbl.snp.remakeConstraints { $0.left.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.width.equalTo(44) }
            barBg.snp.remakeConstraints { $0.left.equalTo(dateLbl.snp.right).offset(8); $0.centerY.equalToSuperview(); $0.height.equalTo(8) }
        }
        valLbl.snp.remakeConstraints { $0.left.equalTo(barBg.snp.right).offset(8); $0.centerY.equalTo(dateLbl); $0.width.equalTo(52) }
        tagWrap.snp.remakeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalTo(dateLbl) }

        switch position {
        case .first:  cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; divider.isHidden = false
        case .middle: cardBg.layer.maskedCorners = []; divider.isHidden = false
        case .last:   cardBg.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        case .single: cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        }
    }

    private func _tag(_ t: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = UILabel(); l.text = t; l.font = .fdMicro; l.textColor = fg
        v.addSubview(l); l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}

// MARK: Stat Panel

private final class ECGStatCell: UITableViewCell {
    private let cardBg = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        let stack = UIStackView(); stack.axis = .horizontal; stack.alignment = .center; stack.distribution = .fillEqually
        cardBg.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        func item(_ val: String, _ lbl: String, _ c: UIColor = .fdText) -> UIView {
            let v = UIView()
            let vl = UILabel(); vl.text = val; vl.font = UIFont.fdFont(ofSize: 28, weight: .bold); vl.textColor = c; vl.textAlignment = .center
            let ll = UILabel(); ll.text = lbl; ll.font = .fdMicro; ll.textColor = .fdSubtext; ll.textAlignment = .center; ll.numberOfLines = 2
            v.addSubview(vl); v.addSubview(ll)
            vl.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.height.equalTo(34) }
            ll.snp.makeConstraints { $0.top.equalTo(vl.snp.bottom).offset(2); $0.centerX.bottom.equalToSuperview() }
            return v
        }
        func div() -> UIView { let d = UIView(); d.backgroundColor = .fdBorder; d.snp.makeConstraints { $0.width.equalTo(1); $0.height.equalTo(40) }; return d }

        stack.addArrangedSubview(item("76", "最近心率\n(bpm)"))
        stack.addArrangedSubview(div())
        stack.addArrangedSubview(item("5", "历史测量\n(次)"))
        stack.addArrangedSubview(div())
        stack.addArrangedSubview(item("正常", "心律状态", UIColor(hexString: "#52B96A")))
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: Record Row

private final class ECGRecordCell: UITableViewCell {
    private let cardBg = UIView()
    private let headerBar = UIView(), headerLbl = UILabel()
    private let timeLbl = UILabel(), valueLbl = UILabel(), srcTag = UILabel(), divider = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear; contentView.backgroundColor = .clear

        cardBg.backgroundColor = .fdSurface; cardBg.layer.cornerRadius = 18
        contentView.addSubview(cardBg)
        cardBg.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.top.bottom.equalToSuperview() }

        headerBar.backgroundColor = UIColor(hexString: "#2E86C1"); headerBar.layer.cornerRadius = 2
        headerLbl.text = "心电记录"; headerLbl.font = .fdBodySemibold; headerLbl.textColor = .fdSubtext

        timeLbl.font = .fdCaption; timeLbl.textColor = .fdText
        valueLbl.font = .fdBodySemibold; valueLbl.textColor = .fdText
        srcTag.font = .fdMicro; srcTag.textAlignment = .center; srcTag.layer.cornerRadius = 999; srcTag.clipsToBounds = true
        divider.backgroundColor = .fdBorder

        [headerBar, headerLbl, timeLbl, valueLbl, srcTag, divider].forEach { cardBg.addSubview($0) }
        headerBar.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.width.equalTo(3); $0.height.equalTo(16) }
        headerLbl.snp.makeConstraints { $0.left.equalTo(headerBar.snp.right).offset(8); $0.centerY.equalTo(headerBar) }
        timeLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16) }
        valueLbl.snp.makeConstraints { $0.left.equalToSuperview().offset(16) }
        srcTag.snp.makeConstraints { $0.right.equalToSuperview().offset(-16); $0.width.equalTo(64); $0.height.equalTo(20) }
        divider.snp.makeConstraints { $0.left.equalToSuperview().offset(16); $0.right.equalToSuperview().offset(-16); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(time: String, value: String, source: String, position: CardPosition) {
        let isFirst = (position == .first || position == .single)
        headerBar.isHidden = !isFirst; headerLbl.isHidden = !isFirst

        timeLbl.text = time; valueLbl.text = value
        if source == "bluetooth" {
            srcTag.text = "蓝牙记录"; srcTag.backgroundColor = UIColor(hexString: "#E8F4FD"); srcTag.textColor = UIColor(hexString: "#3D6FB8")
        } else {
            srcTag.text = "手动记录"; srcTag.backgroundColor = UIColor(hexString: "#F5F5F5"); srcTag.textColor = UIColor(hexString: "#999999")
        }

        // 动态布局：第一行 header 在上方，其他行 header 隐藏
        if isFirst {
            headerBar.snp.remakeConstraints { $0.top.equalToSuperview().offset(14); $0.left.equalToSuperview().offset(16); $0.width.equalTo(3); $0.height.equalTo(16) }
            headerLbl.snp.remakeConstraints { $0.left.equalTo(headerBar.snp.right).offset(8); $0.centerY.equalTo(headerBar) }
            timeLbl.snp.remakeConstraints { $0.top.equalTo(headerBar.snp.bottom).offset(8); $0.left.equalToSuperview().offset(16) }
        } else {
            timeLbl.snp.remakeConstraints { $0.top.equalToSuperview().offset(12); $0.left.equalToSuperview().offset(16) }
        }
        valueLbl.snp.remakeConstraints { $0.top.equalTo(timeLbl.snp.bottom).offset(2); $0.left.equalToSuperview().offset(16); $0.bottom.equalToSuperview().offset(-12) }
        srcTag.snp.remakeConstraints { $0.right.equalToSuperview().offset(-16); $0.centerY.equalToSuperview(); $0.width.equalTo(64); $0.height.equalTo(20) }

        switch position {
        case .first:  cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; divider.isHidden = false
        case .middle: cardBg.layer.maskedCorners = []; divider.isHidden = false
        case .last:   cardBg.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        case .single: cardBg.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]; divider.isHidden = true
        }
    }
}

// ============================================================================
// MARK: - EcgViewController
// ============================================================================

/// 心电监测 — UITableView 架构，卡片式 section 布局。
///
/// 6 个 Section：
/// 0. bluetooth-banner  — 1 row,  独立卡片（圆角 10）
/// 1. ecg-result-card   — 1 row,  独立卡片（圆角 20，蓝色渐变，含 ECG 波形）
/// 2. period-tabs       — 1 row,  segment + 日期导航
/// 3. ecg-hr-chart      — N rows, 卡片组（trend cell 复用，首尾圆角）
/// 4. stats-panel       — 1 row,  卡片组（单 cell 全圆角）
/// 5. records-list      — M rows, 卡片组（record cell 复用，首尾圆角）
///
/// 底部"手动输入数据"按钮固定在 tableView 下方。
final class EcgViewController: BaseViewController {

    // MARK: Data

    private let trendItems: [(date: String, hr: Int, conclusion: String)] = [
        ("05-17", 76, "正常"), ("05-12", 78, "正常"), ("05-07", 81, "正常"),
        ("05-02", 77, "正常"), ("04-27", 79, "正常"),
    ]
    private let recordItems: [(time: String, value: String, source: String)] = [
        ("本月 12 日 09:15", "正常窦性心律 76bpm", "bluetooth"),
        ("05-02 09:00",     "正常窦性心律 78bpm", "bluetooth"),
        ("04-27 08:45",     "正常窦性心律 81bpm", "manual"),
    ]

    // MARK: ECG Simulator

    private let ecgSim = ECGSimulator(heartRate: 75, sampleRate: 250)
    private var demoTimer: Timer?
    private weak var resultCardCell: ECGResultCardCell?

    // MARK: Views

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.alwaysBounceVertical = true
        tv.contentInsetAdjustmentBehavior = .automatic
        tv.register(ECGBannerCell.self,    forCellReuseIdentifier: kBanCell)
        tv.register(ECGResultCardCell.self, forCellReuseIdentifier: kResCell)
        tv.register(ECGSegmentCell.self,   forCellReuseIdentifier: kSegCell)
        tv.register(ECGTrendCell.self,     forCellReuseIdentifier: kTrdCell)
        tv.register(ECGStatCell.self,      forCellReuseIdentifier: kStaCell)
        tv.register(ECGRecordCell.self,    forCellReuseIdentifier: kRecCell)
        tv.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "hdr")
        tv.dataSource = self; tv.delegate = self
        return tv
    }()

    // MARK: Lifecycle

    override func viewDidLoad() { super.viewDidLoad(); startDemo() }
    deinit { stopDemo() }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resultCardCell?.waveView.stopRendering()
    }

    override func setupUI() {
        title = "心电监测"; view.backgroundColor = .fdBg
        let btn = makeFixedButton()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.left.right.equalToSuperview(); $0.bottom.equalTo(btn.snp.top) }
    }

    // MARK: Fixed Button

    private func makeFixedButton() -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle("手动输入数据", for: .normal); b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.fdFont(ofSize: 16, weight: .bold)
        b.backgroundColor = UIColor(hexString: "#FF7A50"); b.layer.cornerRadius = 14
        view.addSubview(b)
        b.snp.makeConstraints { $0.left.right.equalToSuperview().inset(16); $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10); $0.height.equalTo(52) }
        b.addTarget(self, action: #selector(addRecord), for: .touchUpInside)
        return b
    }

    // MARK: Demo

    private func startDemo() {
        let batch = 4
        demoTimer = Timer.scheduledTimer(withTimeInterval: Double(batch) / ecgSim.sampleRate, repeats: true) { [weak self] _ in
            guard let self, let cell = self.resultCardCell else { return }
            cell.waveView.append(contentsOf: self.ecgSim.nextSamples(batch))
        }
    }
    private func stopDemo() { demoTimer?.invalidate(); demoTimer = nil }

    // MARK: Actions

    @objc private func addRecord() { Router.shared.push("/health/metrics/add", params: ["key": "ecg"]) }
}

// MARK: - UITableViewDataSource

extension EcgViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { ECGSection.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch ECGSection(rawValue: section)! {
        case .bluetoothBanner: return 1
        case .resultCard:      return 1
        case .periodTabs:      return 1
        case .trendChart:      return trendItems.count
        case .statsPanel:      return 1
        case .recordsList:     return recordItems.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch ECGSection(rawValue: indexPath.section)! {
        case .bluetoothBanner:
            return tableView.dequeueReusableCell(withIdentifier: kBanCell, for: indexPath)

        case .resultCard:
            let cell = tableView.dequeueReusableCell(withIdentifier: kResCell, for: indexPath) as! ECGResultCardCell
            resultCardCell = cell
            return cell

        case .periodTabs:
            return tableView.dequeueReusableCell(withIdentifier: kSegCell, for: indexPath)

        case .trendChart:
            let cell = tableView.dequeueReusableCell(withIdentifier: kTrdCell, for: indexPath) as! ECGTrendCell
            let d = trendItems[indexPath.row]
            cell.configure(date: d.date, hr: d.hr, conclusion: d.conclusion, position: cardPosition(indexPath, total: trendItems.count))
            return cell

        case .statsPanel:
            return tableView.dequeueReusableCell(withIdentifier: kStaCell, for: indexPath)

        case .recordsList:
            let cell = tableView.dequeueReusableCell(withIdentifier: kRecCell, for: indexPath) as! ECGRecordCell
            let r = recordItems[indexPath.row]
            cell.configure(time: r.time, value: r.value, source: r.source, position: cardPosition(indexPath, total: recordItems.count))
            return cell
        }
    }

    private func cardPosition(_ ip: IndexPath, total: Int) -> CardPosition {
        if total == 1 { return .single }
        if ip.row == 0 { return .first }
        if ip.row == total - 1 { return .last }
        return .middle
    }
}

// MARK: - UITableViewDelegate

extension EcgViewController: UITableViewDelegate {

    // ---- 行高 ----

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch ECGSection(rawValue: indexPath.section)! {
        case .bluetoothBanner: return 42 + 10  // 内容 42 + 底部间距 10
        case .resultCard:      return UITableView.automaticDimension
        case .periodTabs:      return 74        // seg 36 + gap 10 + dateNav ~24 + bottom 4
        case .trendChart:
            return indexPath.row == 0 ? 60 : 36   // 首行含标题，略高
        case .statsPanel:      return 88
        case .recordsList:
            return indexPath.row == 0 ? 88 : UITableView.automaticDimension  // 首行含 header
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch ECGSection(rawValue: indexPath.section)! {
        case .resultCard:  return 295
        case .trendChart:  return indexPath.row == 0 ? 60 : 36
        case .recordsList: return indexPath.row == 0 ? 88 : 58
        default:           return 60
        }
    }

    // ---- Section Header（标题已嵌入首行 cell 的 cardBg 内，无需单独的 header）----

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }

    // ---- Section Footer (区隔) ----

    /// 各 section 之间间距（匹配原 UIScrollView 布局）
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch ECGSection(rawValue: section)! {
        case .bluetoothBanner: return 10   // → resultCard
        case .resultCard:      return 14   // → periodTabs
        case .periodTabs:      return 12   // → trendChart
        case .trendChart:      return 16   // → statsPanel
        case .statsPanel:      return 16   // → recordsList
        case .recordsList:     return 20   // → 底部留白
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }

    // ---- Cell 显示 / 隐藏 ----

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let card = cell as? ECGResultCardCell { card.waveView.startRendering() }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let card = cell as? ECGResultCardCell { card.waveView.stopRendering() }
    }

    // ---- 点击 ----

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if ECGSection(rawValue: indexPath.section) == .bluetoothBanner { Router.shared.push("/me/devices") }
    }

}
