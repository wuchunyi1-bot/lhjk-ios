import UIKit
import SnapKit

/// 身体风险卡片 Cell — 风险等级列 + 人形图 + 综合结论 + 健管师批注
/// 参考 funde-client: hp-body-card + hp-advisor-note
final class HealthRecordBodyCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthRecordBodyCardCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(riskItems: [RiskItem]) {
        contentView.subviews.forEach { $0.removeFromSuperview() }

        let card = UIView()
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Top row: risk bar + body figure + conclusion
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.distribution = .equalSpacing
        card.addSubview(topRow)
        topRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 12, bottom: 0, right: 12)) }

        // Left: Risk bar
        let riskBar = RiskBarView()
        riskBar.configure(items: riskItems)
        topRow.addArrangedSubview(riskBar)

        // Center: Body figure
        let bodyFigure = BodyFigureView()
        topRow.addArrangedSubview(bodyFigure)
        bodyFigure.snp.makeConstraints { $0.size.equalTo(CGSize(width: 88, height: 180)) }

        // Right: Conclusion
        let conclusionView = buildConclusion()
        topRow.addArrangedSubview(conclusionView)

        // Advisor note
        let advisorNote = buildAdvisorNote()
        card.addSubview(advisorNote)
        advisorNote.snp.makeConstraints { make in
            make.top.equalTo(topRow.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Conclusion

    private func buildConclusion() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6

        let checkIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkIcon.tintColor = UIColor(hexString: "#1F9A6B")
        checkIcon.contentMode = .scaleAspectFit
        stack.addArrangedSubview(checkIcon)
        checkIcon.snp.makeConstraints { $0.size.equalTo(26) }

        let label = UILabel()
        label.text = "无高风险\n疾病"
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = UIColor(hexString: "#1F9A6B")
        label.textAlignment = .center
        label.numberOfLines = 0
        stack.addArrangedSubview(label)

        return stack
    }

    // MARK: - Advisor Note

    private func buildAdvisorNote() -> UIView {
        let note = UIView()
        note.backgroundColor = .fdPrimarySoft
        note.layer.cornerRadius = 14

        let avatar = buildAdvisorAvatar(text: "王")
        note.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(28)
        }

        let bodyLabel = UILabel()
        let attributed = NSMutableAttributedString()

        let title = NSAttributedString(
            string: "王顾问 · 健管师批注",
            attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.fdText]
        )
        let content = NSAttributedString(
            string: "\n血压周均值连续 7 天 > 135，已为您预约下周三甲随访。",
            attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.fdText2]
        )

        attributed.append(title)
        attributed.append(content)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributed.length))

        bodyLabel.attributedText = attributed
        bodyLabel.numberOfLines = 0
        note.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        return note
    }

    private func buildAdvisorAvatar(text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 14
        container.clipsToBounds = true
        container.backgroundColor = UIColor.fdPrimary.withAlphaComponent(0.2)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .fdPrimary
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }

        return container
    }
}
