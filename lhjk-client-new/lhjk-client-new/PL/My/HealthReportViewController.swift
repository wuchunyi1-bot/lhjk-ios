import UIKit
import SnapKit

/// 健康报告
/// 参考 funde-client: HealthReportView.vue
final class HealthReportViewController: BaseViewController {

    private var activeTab = 0
    private let scrollView = UIScrollView()
    private let tabContainer = UIView()

    private let weeklyReports = [
        ("第 21 周健康周报", "2026-05-20", "血压均值较上周下降 4mmHg，睡眠时长稳定在 7 小时左右。", "本周已读"),
        ("第 20 周健康周报", "2026-05-13", "运动完成率 82%，晚餐碳水摄入略高，建议继续记录饮食。", "已归档"),
    ]
    private let stageReports = [
        ("慢病逆转 8 周阶段小结", "2026-05-18", "体重下降 2.1kg，空腹血糖波动缩小，建议维持当前运动频率。", "健管师确认"),
        ("首次建档阶段小结", "2026-03-22", "完成六维评估与基础体征采集，已生成 12 周健康管理目标。", "基线报告"),
    ]

    override func setupUI() {
        title = "健康报告"
        view.backgroundColor = .fdBg

        // Segmented control
        let seg = UISegmentedControl(items: ["周报", "阶段小结"])
        seg.selectedSegmentIndex = 0
        seg.selectedSegmentTintColor = .fdPrimary
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.fdSubtext, .font: UIFont.systemFont(ofSize: 13)], for: .normal)
        seg.backgroundColor = .fdBg2
        seg.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        view.addSubview(seg)
        seg.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(seg.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        renderReports()
    }

    @objc private func segmentChanged(_ seg: UISegmentedControl) {
        activeTab = seg.selectedSegmentIndex
        renderReports()
    }

    private func renderReports() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }

        let reports = activeTab == 0 ? weeklyReports : stageReports
        for r in reports {
            let card = buildReportCard(title: r.0, date: r.1, summary: r.2, tag: r.3)
            stack.addArrangedSubview(card)
        }
    }

    private func buildReportCard(title: String, date: String, summary: String, tag: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .top

        let titleCol = UIStackView()
        titleCol.axis = .vertical
        titleCol.spacing = 4

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 16, weight: .bold)
        titleLbl.textColor = .fdText

        let dateLbl = UILabel()
        dateLbl.text = date
        dateLbl.font = .systemFont(ofSize: 12)
        dateLbl.textColor = .fdSubtext

        titleCol.addArrangedSubview(titleLbl)
        titleCol.addArrangedSubview(dateLbl)

        let tagView = buildTag(tag)
        headerRow.addArrangedSubview(titleCol)
        headerRow.addArrangedSubview(UIView())
        headerRow.addArrangedSubview(tagView)

        let summaryLbl = UILabel()
        summaryLbl.text = summary
        summaryLbl.font = .systemFont(ofSize: 14)
        summaryLbl.textColor = .fdText2
        summaryLbl.numberOfLines = 0
        summaryLbl.lineBreakMode = .byWordWrapping

        let btn = UIButton(type: .system)
        btn.setTitle("查看报告详情", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.setTitleColor(.fdPrimary, for: .normal)
        btn.backgroundColor = .fdPrimarySoft
        btn.layer.cornerRadius = 12

        card.addSubview(headerRow)
        card.addSubview(summaryLbl)
        card.addSubview(btn)

        headerRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        summaryLbl.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        btn.snp.makeConstraints { make in
            make.top.equalTo(summaryLbl.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-16)
        }

        return card
    }

    private func buildTag(_ text: String) -> UIView {
        let v = UIView()
        v.backgroundColor = .fdPrimarySoft
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = .fdPrimary
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
