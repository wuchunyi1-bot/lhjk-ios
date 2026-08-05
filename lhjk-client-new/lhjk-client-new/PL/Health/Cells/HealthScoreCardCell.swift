import UIKit
import SnapKit

/// 综合健康评分卡 — 对齐 Figma 3021:1318（环形分 + 风险文案 + 健管师批注）
final class HealthScoreCardCell: UITableViewCell {

    static let reuseIdentifier = "HealthScoreCardCell"

    private let card = UIView()
    private let ringTrack = UIImageView()
    private let ringProgress = UIImageView()
    private let ringScoreLabel = UILabel()
    private let trendLabel = UILabel()
    private let trendArrow = UIImageView()

    private let numLabel = UILabel()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()
    private let hintLabel = UILabel()

    private let noteView = UIView()
    private let noteAvatar = UIImageView()
    private let noteTitle = UILabel()
    private let noteBody = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.clipsToBounds = true
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupViews() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview()
        }

        ringTrack.image = UIImage(named: "score_ring_track")
        ringTrack.contentMode = .scaleAspectFit
        ringProgress.image = UIImage(named: "score_ring_progress")
        ringProgress.contentMode = .scaleAspectFit

        ringScoreLabel.font = .fdFont(ofSize: 24, weight: .medium)
        ringScoreLabel.textColor = .fdPrimary
        ringScoreLabel.textAlignment = .center

        trendLabel.font = .fdFont(ofSize: 10, weight: .regular)
        trendLabel.textColor = UIColor(hexString: "#2EBA83")

        trendArrow.image = UIImage(systemName: "arrow.down")
        trendArrow.tintColor = UIColor(hexString: "#2EBA83")
        trendArrow.contentMode = .scaleAspectFit

        let trendRow = UIStackView(arrangedSubviews: [trendLabel, trendArrow])
        trendRow.axis = .horizontal
        trendRow.spacing = 2
        trendRow.alignment = .center

        let ringWrap = UIView()
        card.addSubview(ringWrap)
        ringWrap.addSubview(ringTrack)
        ringWrap.addSubview(ringProgress)
        ringWrap.addSubview(ringScoreLabel)
        card.addSubview(trendRow)

        ringWrap.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(16)
            $0.size.equalTo(92)
        }
        ringTrack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(84)
        }
        // Figma 进度弧 viewBox 略偏，对齐底环右上
        ringProgress.snp.makeConstraints {
            $0.centerX.equalTo(ringTrack).offset(5)
            $0.centerY.equalTo(ringTrack).offset(-1)
            $0.width.equalTo(74)
            $0.height.equalTo(84)
        }
        ringScoreLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-8)
        }
        trendRow.snp.makeConstraints {
            $0.centerX.equalTo(ringWrap)
            $0.top.equalTo(ringScoreLabel.snp.bottom).offset(0)
        }
        trendArrow.snp.makeConstraints { $0.size.equalTo(10) }

        numLabel.font = .fdFont(ofSize: 34, weight: .medium)
        numLabel.textColor = UIColor(hexString: "#592F10")
        numLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        badgeView.backgroundColor = UIColor(hexString: "#FFF8EB")
        badgeView.layer.cornerRadius = 12
        badgeLabel.font = .fdFont(ofSize: 10, weight: .medium)
        badgeLabel.textColor = UIColor(hexString: "#862804")
        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }

        hintLabel.font = .fdFont(ofSize: 12, weight: .regular)
        hintLabel.textColor = .fdSubtext
        hintLabel.numberOfLines = 2
        hintLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        card.addSubview(numLabel)
        card.addSubview(badgeView)
        card.addSubview(hintLabel)

        numLabel.snp.makeConstraints {
            $0.leading.equalTo(ringWrap.snp.trailing).offset(14)
            $0.top.equalToSuperview().offset(20)
        }
        badgeView.snp.makeConstraints {
            $0.leading.equalTo(numLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(numLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(12)
        }
        hintLabel.snp.makeConstraints {
            $0.leading.equalTo(numLabel)
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalTo(numLabel.snp.bottom).offset(8)
        }

        noteView.layer.cornerRadius = 12
        noteView.clipsToBounds = true
        let noteGradient = CAGradientLayer()
        noteGradient.colors = [
            UIColor(hexString: "#FFF1E5").cgColor,
            UIColor(hexString: "#FFF8F2").cgColor,
        ]
        noteGradient.startPoint = CGPoint(x: 0, y: 0.5)
        noteGradient.endPoint = CGPoint(x: 1, y: 0.5)
        noteView.layer.insertSublayer(noteGradient, at: 0)

        noteAvatar.contentMode = .scaleAspectFill
        noteAvatar.clipsToBounds = true
        noteAvatar.layer.cornerRadius = 24
        noteAvatar.layer.borderWidth = 1
        noteAvatar.layer.borderColor = UIColor(hexString: "#FFE5D0").cgColor
        noteAvatar.image = UIImage(named: "health_advisor")
        noteAvatar.backgroundColor = UIColor(hexString: "#FFD5AE")

        noteTitle.font = .fdFont(ofSize: 14, weight: .medium)
        noteTitle.textColor = UIColor(hexString: "#592F10")
        noteTitle.text = "王顾问·健管师批注"

        noteBody.font = .fdFont(ofSize: 10, weight: .regular)
        noteBody.textColor = UIColor(hexString: "#592F10")
        noteBody.numberOfLines = 2

        card.addSubview(noteView)
        noteView.addSubview(noteAvatar)
        noteView.addSubview(noteTitle)
        noteView.addSubview(noteBody)

        noteView.snp.makeConstraints {
            $0.top.equalTo(ringWrap.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().inset(12)
            $0.height.equalTo(77)
        }
        noteAvatar.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(9)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }
        noteTitle.snp.makeConstraints {
            $0.leading.equalTo(noteAvatar.snp.trailing).offset(14)
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
        }
        noteBody.snp.makeConstraints {
            $0.leading.equalTo(noteTitle)
            $0.trailing.equalToSuperview().inset(14)
            $0.top.equalTo(noteTitle.snp.bottom).offset(6)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let g = noteView.layer.sublayers?.first as? CAGradientLayer {
            g.frame = noteView.bounds
        }
    }

    func configure(riskScore: Int, riskLevel: String) {
        ringScoreLabel.text = "\(riskScore)"
        numLabel.text = "\(riskScore)"
        badgeLabel.text = riskLevel

        let isWarning = riskLevel.contains("高") || riskLevel.contains("中")
        trendLabel.text = "3周前65"
        trendArrow.image = UIImage(systemName: isWarning ? "arrow.down" : "arrow.up")
        trendArrow.tintColor = UIColor(hexString: "#2EBA83")
        trendLabel.textColor = UIColor(hexString: "#2EBA83")

        hintLabel.text = isWarning
            ? "血压偏高拉低了评分。改善 晨起测量习惯 可在4周内提升约 8 分"
            : "各项指标良好，继续保持当前的健康管理节奏。"

        noteBody.text = isWarning
            ? "您的血压周均值连续 7 天 > 135，需重点关注。我已为您预约下周一三甲随访。"
            : "您的各项指标保持稳定，建议继续维持现有运动和饮食方案。"
    }
}
