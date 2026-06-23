import UIKit
import SnapKit

/// 健康报告 — 双 TableView 架构（周报 / 阶段小结）
/// 参考 funde-client: HealthReportView.vue
///
/// 两个独立 UITableView 通过 isHidden 切换，避免大型列表一次性创建所有 View 导致内存膨胀。
/// Cell 复用：WeeklyReportCell / StageReportCell
final class HealthReportViewController: BaseViewController {

    // MARK: - Data Models

    private struct WeeklyReport {
        let id: String; let title: String; let date: String; let tag: String; let summary: String
    }

    private struct StageReport {
        let id: String; let title: String; let date: String; let tag: String
        let summary: String; let metrics: [StageMetric]
    }

    // MARK: - Mock Data

    private lazy var weeklyReports: [WeeklyReport] = [
        WeeklyReport(id: "w21", title: "第 21 周健康周报", date: "2026-05-20", tag: "本周已读",
                     summary: "血压均值较上周下降 4mmHg，睡眠时长稳定在 7 小时左右。"),
        WeeklyReport(id: "w20", title: "第 20 周健康周报", date: "2026-05-13", tag: "已归档",
                     summary: "运动完成率 82%，晚餐碳水摄入略高，建议继续记录饮食。"),
    ]

    private lazy var stageReports: [StageReport] = [
        StageReport(id: "stage-2", title: "慢病逆转 8 周阶段小结", date: "2026-05-18", tag: "健管师确认",
                    summary: "体重下降 2.1kg，空腹血糖波动缩小，建议维持当前运动频率。",
                    metrics: [
                        StageMetric(label: "血压达标率", before: "52%", after: "85%", unit: "", isGood: true),
                        StageMetric(label: "睡眠质量", before: "58分", after: "82分", unit: "", isGood: true),
                        StageMetric(label: "亚健康风险等级", before: "中风险", after: "低风险", unit: "", isGood: true),
                        StageMetric(label: "健康综合评分", before: "72", after: "88", unit: "分", isGood: true),
                    ]),
        StageReport(id: "stage-1", title: "首次建档阶段小结", date: "2026-03-22", tag: "基线报告",
                    summary: "完成六维评估与基础体征采集，已生成 12 周健康管理目标。",
                    metrics: []),
    ]

    // MARK: - State

    private var activeTab = 0

    // MARK: - Segmented Control

    private lazy var segmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: ["周报", "阶段小结"])
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.fdCaptionSemibold], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.fdCaption], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return seg
    }()

    // MARK: - TableViews

    private lazy var weeklyTableView: UITableView = {
        let tv = buildTableView()
        tv.register(WeeklyReportCell.self, forCellReuseIdentifier: WeeklyReportCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 0
        return tv
    }()

    private lazy var stageTableView: UITableView = {
        let tv = buildTableView()
        tv.register(StageReportCell.self, forCellReuseIdentifier: StageReportCell.reuseIdentifier)
        tv.dataSource = self
        tv.delegate = self
        tv.tag = 1
        tv.isHidden = true
        return tv
    }()

    private func buildTableView() -> UITableView {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .fdBg
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        return tv
    }

    // MARK: - Lifecycle

    override func setupUI() {
        title = "健康报告"
        view.backgroundColor = .fdBg

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        // Both tableViews share the same frame constraints
        view.addSubview(weeklyTableView)
        view.addSubview(stageTableView)

        weeklyTableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
        stageTableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ seg: UISegmentedControl) {
        activeTab = seg.selectedSegmentIndex
        weeklyTableView.isHidden = (activeTab != 0)
        stageTableView.isHidden = (activeTab == 0)
    }
}

// MARK: - UITableViewDataSource

extension HealthReportViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView.tag == 0 ? weeklyReports.count : stageReports.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: WeeklyReportCell.reuseIdentifier, for: indexPath) as? WeeklyReportCell else {
                return UITableViewCell()
            }
            let r = weeklyReports[indexPath.row]
            cell.configure(title: r.title, date: r.date, tag: r.tag, summary: r.summary)
            cell.onDetailTap = { [weak self] in self?.showDetailAlert() }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: StageReportCell.reuseIdentifier, for: indexPath) as? StageReportCell else {
                return UITableViewCell()
            }
            let r = stageReports[indexPath.row]
            cell.configure(title: r.title, date: r.date, tag: r.tag, summary: r.summary,
                           metrics: r.metrics.isEmpty ? nil : r.metrics)
            cell.onDetailTap = { [weak self] in self?.showDetailAlert() }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension HealthReportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - Alert

extension HealthReportViewController {

    private func showDetailAlert() {
        let alert = UIAlertController(title: nil, message: "报告详情功能即将上线", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
