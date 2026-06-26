import UIKit
import SnapKit

/// 结构化服务卡片 Cell — 指标/报告/饮食/预约/个案/计划卡
final class ServiceCardCell: UITableViewCell {
    static let reuseID = "ServiceCardCell"

    private let cardView = UIView()
    private let iconView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let rowsStack = UIStackView()
    private let footnoteLabel = UILabel()
    private let actionBtn = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        cardView.backgroundColor = .fdSurface
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.04

        iconView.layer.cornerRadius = 15
        iconView.clipsToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(24) }

        titleLabel.font = .fdFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .fdText

        summaryLabel.font = .fdFont(ofSize: 12)
        summaryLabel.textColor = .fdSubtext
        summaryLabel.numberOfLines = 0

        rowsStack.axis = .vertical
        rowsStack.spacing = 4

        footnoteLabel.font = .fdFont(ofSize: 12)
        footnoteLabel.textColor = .fdSubtext
        footnoteLabel.numberOfLines = 0
        footnoteLabel.backgroundColor = .fdBg2
        footnoteLabel.layer.cornerRadius = 12
        footnoteLabel.clipsToBounds = true

        actionBtn.titleLabel?.font = .fdFont(ofSize: 13, weight: .bold)
        actionBtn.layer.cornerRadius = 12

        contentView.addSubview(cardView)
        [iconView, titleLabel, summaryLabel, rowsStack, footnoteLabel, actionBtn].forEach(cardView.addSubview)

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalToSuperview().offset(50)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-6)
        }

        iconView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(14)
            make.size.equalTo(46)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
        }

        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-14)
        }

        rowsStack.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        footnoteLabel.snp.makeConstraints { make in
            make.top.equalTo(rowsStack.snp.bottom).offset(9)
            make.leading.trailing.equalToSuperview().inset(10)
        }

        actionBtn.snp.makeConstraints { make in
            make.top.equalTo(footnoteLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(14)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(_ msg: ChatMessage, tone: String) {
        guard let card = msg.card else { return }
        let accent = UIColor(hexString: card.accent ?? tone)

        cardView.layer.borderColor = accent.withAlphaComponent(0.2).cgColor
        iconView.backgroundColor = accent.withAlphaComponent(0.08)
        iconImageView.image = UIImage(systemName: card.icon)
        iconImageView.tintColor = accent

        titleLabel.text = card.title
        summaryLabel.text = card.summary

        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for row in card.rows {
            let rowView = makeRow(row, accent: accent)
            rowsStack.addArrangedSubview(rowView)
        }

        if let fn = card.footnote, !fn.isEmpty {
            footnoteLabel.isHidden = false
            footnoteLabel.text = "  \(fn)  "
        } else {
            footnoteLabel.isHidden = true
        }

        if let action = card.action, !action.isEmpty {
            actionBtn.isHidden = false
            actionBtn.setTitle(action, for: .normal)
            actionBtn.setTitleColor(accent, for: .normal)
            actionBtn.backgroundColor = accent.withAlphaComponent(0.08)
        } else {
            actionBtn.isHidden = true
        }
    }

    private func makeRow(_ row: CardRow, accent: UIColor) -> UIView {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 8
        v.alignment = .center

        let label = UILabel()
        label.text = row.label
        label.font = .fdFont(ofSize: 12)
        label.textColor = .fdMuted
        label.setContentHuggingPriority(.required, for: .horizontal)

        let value = UILabel()
        value.text = row.value
        value.font = .fdFont(ofSize: 12)
        value.textColor = .fdText
        value.numberOfLines = 0

        v.addArrangedSubview(label)
        v.addArrangedSubview(value)

        if let status = row.status {
            let badge = UILabel()
            badge.text = status
            badge.font = .fdFont(ofSize: 10, weight: .bold)
            badge.textColor = accent
            badge.backgroundColor = accent.withAlphaComponent(0.08)
            badge.layer.cornerRadius = 8
            badge.clipsToBounds = true
            badge.textAlignment = .center
            v.addArrangedSubview(badge)
        }

        return v
    }
}
