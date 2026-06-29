import UIKit
import SnapKit

/// AI 小德健康周报卡片 Cell
final class AIWeeklyReportCell: UITableViewCell {
    static let reuseID = "AIWeeklyReportCell"

    private let cardView = UIView()
    private let avatarView = UILabel()
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let scoreRow = UIView()
    private let highlightsStack = UIStackView()
    private let medalView = UIView()
    private let nextGoalView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = UIColor(hexString: "#FFF8F5")
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor(hexString: "#FCE0D4").cgColor

        avatarView.text = "德"
        avatarView.font = .fdFont(ofSize: 15, weight: .bold)
        avatarView.textColor = .white
        avatarView.backgroundColor = .fdPrimary
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.textAlignment = .center

        titleLabel.font = .fdFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .fdText

        timeLabel.font = .fdFont(ofSize: 11)
        timeLabel.textColor = .fdSubtext

        scoreRow.backgroundColor = .white
        scoreRow.layer.cornerRadius = 10

        highlightsStack.axis = .vertical
        highlightsStack.spacing = 6

        medalView.backgroundColor = UIColor(hexString: "#FFFBE6")
        medalView.layer.cornerRadius = 8

        nextGoalView.backgroundColor = .white
        nextGoalView.layer.cornerRadius = 8
        nextGoalView.layer.borderWidth = 3
        nextGoalView.layer.borderColor = UIColor.fdPrimary.cgColor

        contentView.addSubview(cardView)
        [avatarView, titleLabel, timeLabel, scoreRow, highlightsStack, medalView, nextGoalView].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(50)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-6)
        }

        avatarView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(36)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
        }

        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalTo(titleLabel)
        }

        // Score row — built dynamically in configure
        highlightsStack.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        medalView.snp.makeConstraints { make in
            make.top.equalTo(highlightsStack.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        nextGoalView.snp.makeConstraints { make in
            make.top.equalTo(medalView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ msg: ChatMessage) {
        guard let report = msg.report else { return }
        titleLabel.text = "第 \(report.weekNo) 周健康周报"
        timeLabel.text = msg.time

        buildScoreRow(report)
        buildHighlights(report.highlights)
        buildMedal(report.medal)
        buildNextGoal(report.nextGoal)
    }

    private func buildScoreRow(_ report: AIWeeklyReport) {
        scoreRow.subviews.forEach { $0.removeFromSuperview() }
        scoreRow.snp.removeConstraints()

        let beforeBlock = scoreBlock(label: "上周评分", score: report.scoreBefore, color: UIColor(hexString: "#BBB"))
        let arrow = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrow.tintColor = .fdPrimary
        arrow.contentMode = .scaleAspectFit
        let afterBlock = scoreBlock(label: "本周评分", score: report.scoreAfter, color: .fdPrimary)
        let delta = UILabel()
        delta.text = "+\(report.scoreAfter - report.scoreBefore)"
        delta.font = .fdFont(ofSize: 13, weight: .bold)
        delta.textColor = UIColor(hexString: "#1F9A6B")
        delta.backgroundColor = UIColor(hexString: "#F0FAF4")
        delta.layer.cornerRadius = 6
        delta.clipsToBounds = true
        delta.textAlignment = .center

        [beforeBlock, arrow, afterBlock, delta].forEach(scoreRow.addSubview)
        beforeBlock.snp.makeConstraints { make in make.leading.top.bottom.equalToSuperview().inset(10) }
        arrow.snp.makeConstraints { make in make.leading.equalTo(beforeBlock.snp.trailing).offset(10); make.centerY.equalToSuperview(); make.size.equalTo(20) }
        afterBlock.snp.makeConstraints { make in make.leading.equalTo(arrow.snp.trailing).offset(10); make.centerY.equalToSuperview() }
        delta.snp.makeConstraints { make in
            make.leading.equalTo(afterBlock.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(40)
        }

        scoreRow.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }
    }

    private func scoreBlock(label: String, score: Int, color: UIColor) -> UIView {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .center
        v.spacing = 2

        let l = UILabel()
        l.text = label
        l.font = .fdFont(ofSize: 11)
        l.textColor = .fdSubtext

        let s = UILabel()
        s.text = "\(score)"
        s.font = .fdFont(ofSize: 26, weight: .bold)
        s.textColor = color

        v.addArrangedSubview(l)
        v.addArrangedSubview(s)
        return v
    }

    private func buildHighlights(_ highlights: [AIHighlight]) {
        highlightsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for h in highlights {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 7
            row.alignment = .center

            let icon = UIImageView(image: UIImage(systemName: h.icon))
            icon.tintColor = .fdPrimary
            icon.contentMode = .scaleAspectFit
            icon.snp.makeConstraints { $0.size.equalTo(14) }

            let text = UILabel()
            text.text = h.text
            text.font = .fdFont(ofSize: 13)
            text.textColor = .fdText

            row.addArrangedSubview(icon)
            row.addArrangedSubview(text)
            highlightsStack.addArrangedSubview(row)
        }
    }

    private func buildMedal(_ medal: AIMedal?) {
        medalView.subviews.forEach { $0.removeFromSuperview() }
        guard let medal = medal else {
            medalView.isHidden = true
            medalView.snp.remakeConstraints { $0.height.equalTo(0) }
            return
        }
        medalView.isHidden = false
        medalView.snp.remakeConstraints { _ in }

        let icon = UIImageView(image: UIImage(systemName: medal.icon))
        icon.tintColor = UIColor(hexString: "#B47300")
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "🎉 获得勋章：\(medal.name)"
        label.font = .fdFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(hexString: "#B47300")

        [icon, label].forEach(medalView.addSubview)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(6)
            make.top.bottom.equalToSuperview().inset(7)
            make.trailing.equalToSuperview().offset(-10)
        }
    }

    private func buildNextGoal(_ goal: String) {
        nextGoalView.subviews.forEach { $0.removeFromSuperview() }

        let tagLabel = UILabel()
        tagLabel.text = "下周目标"
        tagLabel.font = .fdFont(ofSize: 12, weight: .bold)
        tagLabel.textColor = .fdPrimary

        let textLabel = UILabel()
        textLabel.text = goal
        textLabel.font = .fdFont(ofSize: 12)
        textLabel.textColor = .fdSubtext
        textLabel.numberOfLines = 0

        [tagLabel, textLabel].forEach(nextGoalView.addSubview)
        tagLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(10)
            make.width.equalTo(64)
        }
        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(tagLabel.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-10)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }
}
