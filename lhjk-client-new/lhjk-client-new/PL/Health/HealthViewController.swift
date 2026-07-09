import UIKit
import SnapKit

/// 健康模块 Hub 页
/// 参考 funde-client: HealthView.vue
///
/// 布局: UITableView 4 sections
///   Section 0: HealthScoreCardCell
///   Section 1: HealthArchiveCardCell
///   Section 2: HealthVitalMetricsCell (内嵌 UICollectionView)
///   Section 3: HealthQuickEntriesCell
///   tableHeaderView: 自定义 Topbar
final class HealthViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Mock Data

    private let riskScore = 62
    private let riskLevel = "中风险"
    private let archiveProgress = 72

    typealias MetricItem = (key: String, label: String, value: String, unit: String, status: String, statusType: String, icon: String, time: String, trend: String)

    private let metrics: [MetricItem] = [
        ("blood-pressure", "血压", "138/88", "mmHg", "偏高", "warning", "drop", "今天 07:32", "up"),
        ("blood-sugar", "血糖", "5.8", "mmol/L", "正常", "success", "capsule", "昨天 08:10", "flat"),
        ("weight", "体重", "68.5", "kg", "正常", "success", "scalemass", "3 天前", "down"),
        ("heart-rate", "心率", "76", "bpm", "正常", "success", "heart", "今天 07:32", "flat"),
        ("sleep", "睡眠", "7.2", "小时", "良好", "success", "moon", "昨晚", "flat"),
        ("ecg", "心电", "正常", "", "无异常", "success", "waveform.path.ecg", "本月 12 日", "flat"),
        ("fundus", "鹰瞳眼底", "无异常", "", "无异常", "success", "eye", "2 个月前", "flat"),
        ("exercise", "饮食运动", "6,230", "步", "达标", "success", "figure.walk", "今天", "up"),
        ("spo2", "血氧", "98", "%", "正常", "success", "lungs", "今天 07:32", "flat"),
        ("digestive", "消化道", "无异常", "", "无异常", "success", "stethoscope", "3 个月前", "flat"),
    ]

    struct QuickEntry {
        let key: String; let label: String; let icon: String
        let bgColor: UIColor; let fgColor: UIColor; let route: String
    }

    private let quickEntries: [QuickEntry] = [
        QuickEntry(key: "record", label: "健康档案", icon: "doc.text", bgColor: UIColor(hexString: "#FFF3DC"), fgColor: UIColor(hexString: "#B47300"), route: "/health/record"),
        QuickEntry(key: "metrics", label: "体征监测", icon: "heart.text.square", bgColor: UIColor(hexString: "#FFE9DF"), fgColor: UIColor.fdPrimary, route: "/health/metrics"),
        QuickEntry(key: "assess", label: "六维评测", icon: "clipboard", bgColor: UIColor(hexString: "#E6F7EF"), fgColor: UIColor(hexString: "#1F9A6B"), route: "/health/assessment/six-dim"),
        QuickEntry(key: "report", label: "我的报告", icon: "chart.bar", bgColor: UIColor(hexString: "#F3EFFC"), fgColor: UIColor(hexString: "#7B5E9F"), route: "/health/assessment/report"),
    ]

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(HealthScoreCardCell.self, forCellReuseIdentifier: HealthScoreCardCell.reuseIdentifier)
        tv.register(HealthArchiveCardCell.self, forCellReuseIdentifier: HealthArchiveCardCell.reuseIdentifier)
        tv.register(HealthVitalMetricsCell.self, forCellReuseIdentifier: HealthVitalMetricsCell.reuseIdentifier)
        tv.register(HealthQuickEntriesCell.self, forCellReuseIdentifier: HealthQuickEntriesCell.reuseIdentifier)
        tv.contentInsetAdjustmentBehavior = .never
        return tv
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = buildTableHeader().sizedForTableHeader(in: view)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    // MARK: - Table Header (Topbar)

    private func buildTableHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = .fdBg

        let titleLbl = UILabel()
        titleLbl.text = "我的健康"
        titleLbl.font = .fdH2
        titleLbl.textColor = .fdText

        let subtitleLbl = UILabel()
        subtitleLbl.text = "档案完整度 \(archiveProgress)% · \(riskLevel)"
        subtitleLbl.font = .fdCaption
        subtitleLbl.textColor = .fdSubtext

        header.addSubview(titleLbl)
        header.addSubview(subtitleLbl)
        titleLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(54)
            make.leading.equalToSuperview().offset(18)
        }
        subtitleLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().offset(-8)
        }

        let size = header.systemLayoutSizeFitting(
            CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        header.frame.size = size
        return header
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthScoreCardCell.reuseIdentifier, for: indexPath) as? HealthScoreCardCell else {
                return UITableViewCell()
            }
            cell.configure(riskScore: riskScore, riskLevel: riskLevel)
            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthArchiveCardCell.reuseIdentifier, for: indexPath) as? HealthArchiveCardCell else {
                return UITableViewCell()
            }
            cell.configure(archiveProgress: archiveProgress)
            cell.onCompleteTap = { [weak self] in self?.goToRecord() }
            return cell

        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthVitalMetricsCell.reuseIdentifier, for: indexPath) as? HealthVitalMetricsCell else {
                return UITableViewCell()
            }
            cell.configure(metrics: metrics)
            cell.onMetricTap = { key in Router.shared.push("/health/metrics/\(key)") }
            return cell

        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HealthQuickEntriesCell.reuseIdentifier, for: indexPath) as? HealthQuickEntriesCell else {
                return UITableViewCell()
            }
            cell.configure(entries: quickEntries.map {
                HealthQuickEntriesCell.Entry(key: $0.key, label: $0.label, icon: $0.icon, bgColor: $0.bgColor, fgColor: $0.fgColor, route: $0.route)
            })
            cell.onEntryTap = { route in Router.shared.push(route) }
            return cell

        default:
            return UITableViewCell()
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2: return HealthVitalMetricsCell.height(for: metrics.count)
        default: return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 2 else { return nil }
        let header = SectionTitleView(title: "体征监测", more: "编辑卡片 ›")
        header.onMoreTapped = { Router.shared.push("/health/metrics") }
        let container = UIView()
        container.backgroundColor = .fdBg
        container.addSubview(header)
        header.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview() }
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 2 ? 36 : 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // MARK: - Actions

    @objc private func goToRecord() {
        Router.shared.push("/health/record")
    }
}
