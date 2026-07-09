import UIKit
import SnapKit

/// 三好卡兑换提示条 — 对应 funde page-spec `activate-banner` region
final class ActivateBannerCell: UITableViewCell {

    static let reuseID = "ActivateBannerCell"

    var onTap: (() -> Void)?

    private let card = UIView()
    private let iconLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        card.backgroundColor = .fdPrimarySoft
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)) }

        iconLabel.text = "🎫"
        iconLabel.font = .fdH3

        messageLabel.text = "已有三好卡？立即兑换健康管理服务"
        messageLabel.font = .fdCaption
        messageLabel.textColor = .fdText
        messageLabel.numberOfLines = 2

        actionLabel.text = "立即兑换 ›"
        actionLabel.font = .fdCaptionSemibold
        actionLabel.textColor = .fdPrimary
        actionLabel.setContentHuggingPriority(.required, for: .horizontal)
        actionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [messageLabel, actionLabel])
        textStack.axis = .horizontal
        textStack.spacing = 8
        textStack.alignment = .center

        let row = UIStackView(arrangedSubviews: [iconLabel, textStack])
        row.spacing = 10
        row.alignment = .center
        card.addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        onTap?()
    }
}
