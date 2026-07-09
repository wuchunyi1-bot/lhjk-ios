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

/// 卡片组首尾圆角位置（趋势图、记录列表等复用 cell 时使用）
enum EcgCardPosition {
    case first, middle, last, single
}

// MARK: - EcgViewController

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
        tv.register(ECGBannerCell.self,     forCellReuseIdentifier: ECGBannerCell.reuseID)
        tv.register(ECGResultCardCell.self, forCellReuseIdentifier: ECGResultCardCell.reuseID)
        tv.register(ECGSegmentCell.self,    forCellReuseIdentifier: ECGSegmentCell.reuseID)
        tv.register(ECGTrendCell.self,      forCellReuseIdentifier: ECGTrendCell.reuseID)
        tv.register(ECGStatCell.self,       forCellReuseIdentifier: ECGStatCell.reuseID)
        tv.register(ECGRecordCell.self,     forCellReuseIdentifier: ECGRecordCell.reuseID)
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
            return tableView.dequeueReusableCell(withIdentifier: ECGBannerCell.reuseID, for: indexPath)

        case .resultCard:
            let cell = tableView.dequeueReusableCell(withIdentifier: ECGResultCardCell.reuseID, for: indexPath) as! ECGResultCardCell
            resultCardCell = cell
            return cell

        case .periodTabs:
            return tableView.dequeueReusableCell(withIdentifier: ECGSegmentCell.reuseID, for: indexPath)

        case .trendChart:
            let cell = tableView.dequeueReusableCell(withIdentifier: ECGTrendCell.reuseID, for: indexPath) as! ECGTrendCell
            let d = trendItems[indexPath.row]
            cell.configure(date: d.date, hr: d.hr, conclusion: d.conclusion, position: cardPosition(indexPath, total: trendItems.count))
            return cell

        case .statsPanel:
            return tableView.dequeueReusableCell(withIdentifier: ECGStatCell.reuseID, for: indexPath)

        case .recordsList:
            let cell = tableView.dequeueReusableCell(withIdentifier: ECGRecordCell.reuseID, for: indexPath) as! ECGRecordCell
            let r = recordItems[indexPath.row]
            cell.configure(time: r.time, value: r.value, source: r.source, position: cardPosition(indexPath, total: recordItems.count))
            return cell
        }
    }

    private func cardPosition(_ ip: IndexPath, total: Int) -> EcgCardPosition {
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
