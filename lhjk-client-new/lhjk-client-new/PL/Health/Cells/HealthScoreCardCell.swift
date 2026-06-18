import UIKit
import SnapKit

/// 综合健康评分卡片 Cell — 视图 init 创建，configure 仅赋值
final class HealthScoreCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthScoreCardCell"

    // MARK: - Views (created once)

    private let card = UIView()
    private let scoreCircle = UIView()
    private let scoreLabel = UILabel()
    private let scoreMicro = UILabel()
    private let trendLabel = UILabel()
    private let sublabel = UILabel()
    private let numLabel = UILabel()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()
    private let hintLabel = UILabel()

    // Advisor note
    private let noteView = UIView()
    private let noteAvatar = UIView()
    private let noteAvatarLbl = UILabel()
    private let noteTextLbl = UILabel()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        // Card
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        // Score circle
        scoreCircle.layer.borderWidth = 7
        scoreCircle.layer.cornerRadius = 39
        [scoreMicro, scoreLabel, trendLabel].forEach(scoreCircle.addSubview)
        scoreMicro.font = .fdMicro; scoreMicro.textColor = .fdMuted; scoreMicro.text = "SCORE"
        scoreLabel.font = .fdH2
        trendLabel.font = .fdMicro

        scoreMicro.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.bottom.equalTo(scoreLabel.snp.top).offset(-2) }
        scoreLabel.snp.makeConstraints { $0.centerX.centerY.equalToSuperview().offset(-8) }
        trendLabel.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalTo(scoreLabel.snp.bottom).offset(2) }

        // Right column
        sublabel.font = .fdCaption; sublabel.textColor = .fdSubtext; sublabel.text = "综合健康评分"
        numLabel.font = .fdFont(ofSize: 40, weight: .bold); numLabel.textColor = .fdText
        hintLabel.font = .fdCaption; hintLabel.textColor = .fdText2; hintLabel.numberOfLines = 0

        badgeView.layer.cornerRadius = 999
        badgeView.addSubview(badgeLabel)
        badgeLabel.font = .fdMicroSemibold
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)) }

        let numRow = UIStackView(arrangedSubviews: [numLabel, badgeView, UIView()])
        numRow.axis = .horizontal; numRow.spacing = 8; numRow.alignment = .center
        let rightCol = UIStackView(arrangedSubviews: [sublabel, numRow, hintLabel])
        rightCol.axis = .vertical; rightCol.spacing = 4

        let mainRow = UIStackView(arrangedSubviews: [scoreCircle, rightCol])
        mainRow.axis = .horizontal; mainRow.spacing = 16; mainRow.alignment = .center
        card.addSubview(mainRow)
        mainRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(18) }
        scoreCircle.snp.makeConstraints { $0.size.equalTo(78) }

        // Advisor note
        noteView.backgroundColor = .fdPrimarySoft
        noteView.layer.cornerRadius = 12

        noteAvatar.backgroundColor = UIColor(hexString: "#FFEFE6")
        noteAvatar.layer.cornerRadius = 14
        noteAvatarLbl.font = .fdCaptionSemibold; noteAvatarLbl.textColor = UIColor(hexString: "#D6602B")
        noteAvatarLbl.text = "王"
        noteAvatar.addSubview(noteAvatarLbl)
        noteAvatarLbl.snp.makeConstraints { $0.center.equalToSuperview() }

        noteTextLbl.numberOfLines = 0
        noteView.addSubview(noteAvatar)
        noteView.addSubview(noteTextLbl)
        noteAvatar.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(12); $0.size.equalTo(28) }
        noteTextLbl.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(noteAvatar.snp.trailing).offset(10)
            make.trailing.bottom.equalToSuperview().inset(12)
        }

        card.addSubview(noteView)
        noteView.snp.makeConstraints { make in
            make.top.equalTo(mainRow.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    // MARK: - Configure (赋值 only)

    func configure(riskScore: Int, riskLevel: String) {
        scoreLabel.text = "\(riskScore)"
        scoreLabel.textColor = .fdText

        numLabel.text = "\(riskScore)"
        numLabel.textColor = .fdText

        let isWarning = riskLevel.contains("高") || riskLevel.contains("中")
        scoreCircle.layer.borderColor = (isWarning ? UIColor.fdWarning : UIColor.fdPrimary).withAlphaComponent(0.3).cgColor
        trendLabel.textColor = isWarning ? .fdWarning : .fdSuccess
        trendLabel.text = isWarning ? "↓ 3 周前 65" : "↑ 持续改善"

        // Badge
        let badgeBg: UIColor = isWarning ? .fdWarningSoft : .fdSuccessSoft
        let badgeFg: UIColor = isWarning ? UIColor(hexString: "#B47300") : .fdSuccess
        badgeView.backgroundColor = badgeBg
        badgeLabel.text = riskLevel
        badgeLabel.textColor = badgeFg

        hintLabel.text = isWarning
            ? "血压偏高拉低了评分。改善晨起测量习惯可在 4 周内提升约 8 分。"
            : "各项指标良好，继续保持当前的健康管理节奏。"

        // Advisor note text
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(string: "王顾问 · 健管师批注：\n",
            attributes: [.font: UIFont.fdCaptionSemibold, .foregroundColor: UIColor.fdText]))
        attr.append(NSAttributedString(string: isWarning
            ? "您的血压周均值连续 7 天 > 135，需重点关注。我已为您预约下周一三甲随访。"
            : "您的各项指标保持稳定，建议继续维持现有运动和饮食方案。",
            attributes: [.font: UIFont.fdCaption, .foregroundColor: UIColor.fdText2]))
        noteTextLbl.attributedText = attr
    }
}
