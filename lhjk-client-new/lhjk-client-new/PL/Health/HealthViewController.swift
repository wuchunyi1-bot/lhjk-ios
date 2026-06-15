import UIKit
import SnapKit

/// 健康模块 Hub 页
/// 参考 funde-client: HealthView.vue
final class HealthViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Mock Data

    private let riskScore = 62
    private let riskLevel = "中风险"
    private let archiveProgress = 72

    private let metrics: [(key: String, label: String, value: String, unit: String, status: String, statusType: String, icon: String, time: String, trend: String)] = [
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

    private let quickEntries: [(key: String, label: String, icon: String, bgColor: UIColor, fgColor: UIColor, route: String)] = [
        ("record", "健康档案", "doc.text", UIColor(hexString: "#FFF3DC"), UIColor(hexString: "#B47300"), "/health/record"),
        ("metrics", "体征监测", "heart.text.square", UIColor(hexString: "#FFE9DF"), UIColor.fdPrimary, "/health/metrics"),
        ("assess", "六维评测", "clipboard", UIColor(hexString: "#E6F7EF"), UIColor(hexString: "#1F9A6B"), "/health/assessment/six-dim"),
        ("report", "我的报告", "chart.bar", UIColor(hexString: "#F3EFFC"), UIColor(hexString: "#7B5E9F"), "/health/assessment/report"),
    ]

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func setupUI() {
        view.backgroundColor = .fdBg
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }

        let sectionPad: CGFloat = 16

        // 1. Topbar
        let topbar = buildTopbar()
        contentView.addSubview(topbar)
        topbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        // 2. Score card
        let scoreCard = buildScoreCard()
        contentView.addSubview(scoreCard)
        scoreCard.snp.makeConstraints { make in
            make.top.equalTo(topbar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(sectionPad)
        }

        // 3. Archive card
        let archiveCard = buildArchiveCard()
        contentView.addSubview(archiveCard)
        archiveCard.snp.makeConstraints { make in
            make.top.equalTo(scoreCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(sectionPad)
        }

        // 4. Metrics grid
        let metricsSection = buildMetricsSection()
        contentView.addSubview(metricsSection)
        metricsSection.snp.makeConstraints { make in
            make.top.equalTo(archiveCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(sectionPad)
        }

        // 5. Quick entries
        let quickSection = buildQuickSection()
        contentView.addSubview(quickSection)
        quickSection.snp.makeConstraints { make in
            make.top.equalTo(metricsSection.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(sectionPad)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    // MARK: - Topbar

    private func buildTopbar() -> UIView {
        let bar = UIView()

        let titleLbl = UILabel()
        titleLbl.text = "我的健康"
        titleLbl.font = .systemFont(ofSize: 22, weight: .bold)
        titleLbl.textColor = .fdText

        let subtitleLbl = UILabel()
        subtitleLbl.text = "档案完整度 \(archiveProgress)% · \(riskLevel)"
        subtitleLbl.font = .systemFont(ofSize: 12)
        subtitleLbl.textColor = .fdSubtext

        bar.addSubview(titleLbl)
        bar.addSubview(subtitleLbl)

        titleLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(54)
            make.leading.equalToSuperview().offset(18)
        }
        subtitleLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(18)
            make.bottom.equalToSuperview().offset(-8)
        }

        return bar
    }

    // MARK: - Score Card

    private func buildScoreCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        // Score circle (simplified from SVG radial gauge)
        let scoreCircle = UIView()
        scoreCircle.layer.borderWidth = 7
        scoreCircle.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.3).cgColor
        scoreCircle.layer.cornerRadius = 39

        let scoreLabel = UILabel()
        scoreLabel.text = "\(riskScore)"
        scoreLabel.font = .systemFont(ofSize: 22, weight: .bold)
        scoreLabel.textColor = .fdText

        let scoreMicro = UILabel()
        scoreMicro.text = "SCORE"
        scoreMicro.font = .systemFont(ofSize: 10)
        scoreMicro.textColor = .fdMuted

        let trendLabel = UILabel()
        trendLabel.text = "↓ 3 周前 65"
        trendLabel.font = .systemFont(ofSize: 10)
        trendLabel.textColor = .fdWarning

        scoreCircle.addSubview(scoreLabel)
        scoreCircle.addSubview(scoreMicro)
        scoreCircle.addSubview(trendLabel)
        scoreLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalToSuperview().offset(-8) }
        scoreMicro.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.bottom.equalTo(scoreLabel.snp.top).offset(-2) }
        trendLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(scoreLabel.snp.bottom).offset(2) }

        // Right side
        let sublabel = UILabel()
        sublabel.text = "综合健康评分"
        sublabel.font = .systemFont(ofSize: 12)
        sublabel.textColor = .fdSubtext

        let numLabel = UILabel()
        numLabel.text = "\(riskScore)"
        numLabel.font = .systemFont(ofSize: 40, weight: .bold)
        numLabel.textColor = .fdText

        let badge = buildBadge(riskLevel, bg: .fdWarningSoft, fg: UIColor(hexString: "#B47300"))

        let hintLabel = UILabel()
        hintLabel.text = "血压偏高拉低了评分。改善晨起测量习惯可在 4 周内提升约 8 分。"
        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .fdText2
        hintLabel.numberOfLines = 0

        let rightCol = UIStackView(arrangedSubviews: [sublabel, numLabel])
        rightCol.axis = .vertical
        rightCol.spacing = 2

        let numRow = UIStackView(arrangedSubviews: [numLabel, badge, UIView()])
        numRow.axis = .horizontal
        numRow.spacing = 8
        numRow.alignment = .center

        let mainRow = UIStackView(arrangedSubviews: [scoreCircle, rightCol])
        mainRow.axis = .horizontal
        mainRow.spacing = 16
        mainRow.alignment = .center

        card.addSubview(mainRow)
        mainRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(18)
        }
        scoreCircle.snp.makeConstraints { $0.size.equalTo(78) }

        // Fix right col: replace
        rightCol.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rightCol.addArrangedSubview(sublabel)
        rightCol.addArrangedSubview(numRow)
        rightCol.addArrangedSubview(hintLabel)

        // Advisor note
        let note = buildAdvisorNote()
        card.addSubview(note)
        note.snp.makeConstraints { make in
            make.top.equalTo(mainRow.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }

        return card
    }

    private func buildAdvisorNote() -> UIView {
        let note = UIView()
        note.backgroundColor = .fdPrimarySoft
        note.layer.cornerRadius = 12

        let avatar = UIView()
        avatar.backgroundColor = UIColor(hexString: "#FFEFE6")
        avatar.layer.cornerRadius = 14
        let avatarLbl = UILabel()
        avatarLbl.text = "王"
        avatarLbl.font = .systemFont(ofSize: 12, weight: .semibold)
        avatarLbl.textColor = UIColor(hexString: "#D6602B")
        avatar.addSubview(avatarLbl)
        avatarLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        let textLbl = UILabel()
        textLbl.numberOfLines = 0
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "王顾问 · 健管师批注：\n", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.fdText]))
        attr.append(NSAttributedString(string: "您的血压周均值连续 7 天 > 135，需重点关注。我已为您预约下周一三甲随访。", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.fdText2]))
        textLbl.attributedText = attr

        note.addSubview(avatar)
        note.addSubview(textLbl)
        avatar.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.size.equalTo(28)
        }
        textLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.trailing.bottom.equalToSuperview().inset(12)
        }
        return note
    }

    // MARK: - Archive Card

    private func buildArchiveCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03

        let titleLbl = UILabel()
        titleLbl.text = "健康档案完整度"
        titleLbl.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLbl.textColor = .fdText

        let hintLbl = UILabel()
        hintLbl.text = "缺：心电图 / 家族病史"
        hintLbl.font = .systemFont(ofSize: 11)
        hintLbl.textColor = .fdSubtext

        let pctLabel = UILabel()
        pctLabel.text = "\(archiveProgress)"
        pctLabel.font = .systemFont(ofSize: 22, weight: .bold)
        pctLabel.textColor = .fdPrimary

        let pctUnit = UILabel()
        pctUnit.text = "%"
        pctUnit.font = .systemFont(ofSize: 12)
        pctUnit.textColor = .fdSubtext

        let progressBg = UIView()
        progressBg.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.14)
        progressBg.layer.cornerRadius = 4
        let progressFill = UIView()
        progressFill.backgroundColor = .fdPrimary
        progressFill.layer.cornerRadius = 4
        progressBg.addSubview(progressFill)

        let footerLbl = UILabel()
        footerLbl.text = "补全后 +20 健康分 · 解锁家族风险图谱"
        footerLbl.font = .systemFont(ofSize: 11)
        footerLbl.textColor = .fdMuted

        let completeBtn = UIButton(type: .system)
        completeBtn.setTitle("去补全", for: .normal)
        completeBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        completeBtn.setTitleColor(.fdPrimary, for: .normal)
        completeBtn.backgroundColor = .fdPrimarySoft
        completeBtn.layer.cornerRadius = 999
        completeBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        completeBtn.addTarget(self, action: #selector(goToRecord), for: .touchUpInside)

        card.addSubview(titleLbl)
        card.addSubview(hintLbl)
        card.addSubview(pctLabel)
        card.addSubview(pctUnit)
        card.addSubview(progressBg)
        card.addSubview(footerLbl)
        card.addSubview(completeBtn)

        titleLbl.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        hintLbl.snp.makeConstraints { make in
            make.top.equalTo(titleLbl.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(16)
        }
        pctLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalTo(pctUnit.snp.leading).offset(-2)
        }
        pctUnit.snp.makeConstraints { make in
            make.lastBaseline.equalTo(pctLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        progressBg.snp.makeConstraints { make in
            make.top.equalTo(hintLbl.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(CGFloat(archiveProgress) / 100.0)
        }
        footerLbl.snp.makeConstraints { make in
            make.top.equalTo(progressBg.snp.bottom).offset(12)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        completeBtn.snp.makeConstraints { make in
            make.centerY.equalTo(footerLbl)
            make.trailing.equalToSuperview().offset(-16)
        }

        return card
    }

    @objc private func goToRecord() {
        Router.shared.push("/health/record")
    }

    // MARK: - Metrics Grid

    /// 懒加载 collectionView（在 buildMetricsSection 中配置 layout）
    private lazy var metricsCollectionView: UICollectionView = {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(140))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(140))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10

        let layout = UICollectionViewCompositionalLayout(section: section)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(MetricCardCell.self, forCellWithReuseIdentifier: MetricCardCell.reuseIdentifier)
        return cv
    }()

    private func buildMetricsSection() -> UIView {
        let section = UIView()

        let titleRow = SectionTitleView(title: "体征监测", more: "编辑卡片 ›")
        titleRow.onMoreTapped = { Router.shared.push("/health/metrics") }
        section.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        section.addSubview(metricsCollectionView)
        metricsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(metricsCollectionViewHeight)
            make.bottom.equalToSuperview()
        }

        return section
    }

    /// 动态计算 CollectionView 高度（每行 2 个，向上取整）
    private var metricsCollectionViewHeight: CGFloat {
        let rows = (metrics.count + 1) / 2
        return CGFloat(rows) * 140 + CGFloat(rows - 1) * 10
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metrics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MetricCardCell.reuseIdentifier, for: indexPath) as? MetricCardCell else {
            return UICollectionViewCell()
        }
        let m = metrics[indexPath.item]
        cell.configure(metricKey: m.key, icon: m.icon, status: m.status, statusType: m.statusType, label: m.label, value: m.value, unit: m.unit, trend: m.trend, time: m.time)
        return cell
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = metrics[indexPath.item].key
        Router.shared.push("/health/metrics/\(key)")
    }

    // MARK: - Quick Entries

    private func buildQuickSection() -> UIView {
        let section = UIView()

        let titleRow = SectionTitleView(title: "快速入口")
        section.addSubview(titleRow)
        titleRow.snp.makeConstraints { make in make.top.leading.trailing.equalToSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        section.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(titleRow.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let row = UIStackView()
        row.distribution = .fillEqually
        card.addSubview(row)
        row.snp.makeConstraints { make in make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 8, bottom: 18, right: 8)) }

        for entry in quickEntries {
            let item = buildQuickEntry(entry)
            row.addArrangedSubview(item)
        }

        return section
    }

    private func buildQuickEntry(_ e: (key: String, label: String, icon: String, bgColor: UIColor, fgColor: UIColor, route: String)) -> UIView {
        let item = UIView()

        let iconBg = UIView()
        iconBg.backgroundColor = e.bgColor
        iconBg.layer.cornerRadius = 16
        let icon = UIImageView(image: UIImage(systemName: e.icon))
        icon.tintColor = e.fgColor
        icon.contentMode = .scaleAspectFit
        iconBg.addSubview(icon)

        let label = UILabel()
        label.text = e.label
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .fdText2
        label.textAlignment = .center

        item.addSubview(iconBg)
        item.addSubview(label)
        iconBg.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(48)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(iconBg.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(quickEntryTapped(_:)))
        item.addGestureRecognizer(tap)
        item.accessibilityIdentifier = e.route

        return item
    }

    @objc private func quickEntryTapped(_ gesture: UITapGestureRecognizer) {
        guard let route = gesture.view?.accessibilityIdentifier else { return }
        Router.shared.push(route)
    }

    // MARK: - Helpers

    private func buildBadge(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView()
        v.backgroundColor = bg
        v.layer.cornerRadius = 999
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10, weight: .semibold)
        l.textColor = fg
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }
}
