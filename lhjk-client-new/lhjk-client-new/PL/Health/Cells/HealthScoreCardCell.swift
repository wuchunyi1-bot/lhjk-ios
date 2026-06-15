import UIKit
import SnapKit

/// 综合健康评分卡片 Cell
final class HealthScoreCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthScoreCardCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(riskScore: Int, riskLevel: String) {
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

        let scoreCircle = UIView()
        scoreCircle.layer.borderWidth = 7
        scoreCircle.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.3).cgColor
        scoreCircle.layer.cornerRadius = 39

        let scoreLabel = makeLabel("\(riskScore)", size: 22, weight: .bold, color: .fdText)
        let scoreMicro = makeLabel("SCORE", size: 10, weight: .regular, color: .fdMuted)
        let trendLabel = makeLabel("↓ 3 周前 65", size: 10, weight: .regular, color: .fdWarning)
        scoreCircle.addSubview(scoreLabel)
        scoreCircle.addSubview(scoreMicro)
        scoreCircle.addSubview(trendLabel)
        scoreLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalToSuperview().offset(-8) }
        scoreMicro.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.bottom.equalTo(scoreLabel.snp.top).offset(-2) }
        trendLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(scoreLabel.snp.bottom).offset(2) }

        let sublabel = makeLabel("综合健康评分", size: 12, weight: .regular, color: .fdSubtext)
        let numLabel = makeLabel("\(riskScore)", size: 40, weight: .bold, color: .fdText)
        let badge = buildBadge(riskLevel, bg: .fdWarningSoft, fg: UIColor(hexString: "#B47300"))
        let hintLabel = makeLabel("血压偏高拉低了评分。改善晨起测量习惯可在 4 周内提升约 8 分。", size: 12, weight: .regular, color: .fdText2)
        hintLabel.numberOfLines = 0

        let numRow = UIStackView(arrangedSubviews: [numLabel, badge, UIView()])
        numRow.axis = .horizontal; numRow.spacing = 8; numRow.alignment = .center
        let rightCol = UIStackView(arrangedSubviews: [sublabel, numRow, hintLabel])
        rightCol.axis = .vertical; rightCol.spacing = 4

        let mainRow = UIStackView(arrangedSubviews: [scoreCircle, rightCol])
        mainRow.axis = .horizontal; mainRow.spacing = 16; mainRow.alignment = .center
        card.addSubview(mainRow)
        mainRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(18) }
        scoreCircle.snp.makeConstraints { $0.size.equalTo(78) }

        let note = buildAdvisorNote()
        card.addSubview(note)
        note.snp.makeConstraints { make in
            make.top.equalTo(mainRow.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    private func buildAdvisorNote() -> UIView {
        let note = UIView()
        note.backgroundColor = .fdPrimarySoft
        note.layer.cornerRadius = 12
        let avatar = UIView()
        avatar.backgroundColor = UIColor(hexString: "#FFEFE6")
        avatar.layer.cornerRadius = 14
        let avatarLbl = makeLabel("王", size: 12, weight: .semibold, color: UIColor(hexString: "#D6602B"))
        avatar.addSubview(avatarLbl)
        avatarLbl.snp.makeConstraints { $0.center.equalToSuperview() }
        let textLbl = UILabel(); textLbl.numberOfLines = 0
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "王顾问 · 健管师批注：\n", attributes: [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.fdText]))
        attr.append(NSAttributedString(string: "您的血压周均值连续 7 天 > 135，需重点关注。我已为您预约下周一三甲随访。", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.fdText2]))
        textLbl.attributedText = attr
        note.addSubview(avatar)
        note.addSubview(textLbl)
        avatar.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(12); $0.size.equalTo(28) }
        textLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.trailing.bottom.equalToSuperview().inset(12)
        }
        return note
    }

    private func buildBadge(_ text: String, bg: UIColor, fg: UIColor) -> UIView {
        let v = UIView(); v.backgroundColor = bg; v.layer.cornerRadius = 999
        let l = makeLabel(text, size: 10, weight: .semibold, color: fg)
        v.addSubview(l)
        l.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }
        return v
    }

    private func makeLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: size, weight: weight); l.textColor = color
        return l
    }
}
