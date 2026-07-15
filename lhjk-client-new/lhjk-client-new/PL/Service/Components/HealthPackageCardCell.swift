import UIKit
import SnapKit

/// 推荐服务健康包卡片 — 对齐 `ServicesView.vue` → `health-package-card`
final class HealthPackageCardCell: UITableViewCell {

    static let reuseID = "HealthPackageCardCell"

    var onDetailTap: (() -> Void)?

    private let card = UIView()
    private let coverView = UIView()
    private let coverLabel = UILabel()
    private let badgeLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let tagRow = UIStackView()
    private let divider = UIView()
    private let priceLabel = UILabel()
    private let unitLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.layer.shadowRadius = 6
        card.layer.shadowOpacity = 0.03
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16)) }

        coverView.backgroundColor = .fdBg2
        coverView.layer.cornerRadius = 12
        coverLabel.font = .fdBodyBold
        coverLabel.textAlignment = .center
        coverView.addSubview(coverLabel)
        coverLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        coverView.snp.makeConstraints { $0.size.equalTo(88) }

        badgeLabel.font = .fdMicroSemibold
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = .fdPrimary
        badgeLabel.layer.cornerRadius = 6
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.isHidden = true
        coverView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(6); $0.height.equalTo(18) }

        nameLabel.font = .fdBodyBold
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2
        descLabel.font = .fdCaption
        descLabel.textColor = .fdSubtext
        descLabel.numberOfLines = 1

        tagRow.spacing = 6
        tagRow.alignment = .leading

        let body = UIStackView(arrangedSubviews: [nameLabel, descLabel, tagRow])
        body.axis = .vertical
        body.spacing = 6
        body.alignment = .leading

        let main = UIStackView(arrangedSubviews: [coverView, body])
        main.spacing = 12
        main.alignment = .top
        card.addSubview(main)
        main.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(12) }

        divider.backgroundColor = .fdBorder
        card.addSubview(divider)
        divider.snp.makeConstraints { $0.top.equalTo(main.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(12); $0.height.equalTo(0.5) }

        priceLabel.font = .fdNumM
        priceLabel.textColor = .fdPrimary
        unitLabel.font = .fdCaption
        unitLabel.textColor = .fdSubtext
        unitLabel.text = " 元起"

        actionButton.setTitle("了解详情", for: .normal)
        actionButton.titleLabel?.font = .fdCaptionSemibold
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = .fdPrimary
        actionButton.layer.cornerRadius = 19
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
        actionButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)

        let footer = UIStackView(arrangedSubviews: [priceLabel, unitLabel, UIView(), actionButton])
        footer.alignment = .center
        card.addSubview(footer)
        footer.snp.makeConstraints { $0.top.equalTo(divider.snp.bottom).offset(12); $0.leading.trailing.bottom.equalToSuperview().inset(12) }
    }

    func configure(_ item: HealthPackageItem, actionTitle: String = "了解详情") {
        coverLabel.text = item.productCode
        coverLabel.textColor = item.accent

        if let badge = item.badge, !badge.isEmpty {
            badgeLabel.isHidden = false
            badgeLabel.text = " \(badge) "
        } else {
            badgeLabel.isHidden = true
        }

        nameLabel.text = item.displayTitle
        descLabel.text = item.subtitle
        priceLabel.text = item.price

        actionButton.setTitle(actionTitle, for: .normal)

        tagRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for tag in item.audienceTags.prefix(4) {
            let pill = PaddingLabel()
            pill.text = tag
            pill.font = .fdMicroSemibold
            pill.textColor = .fdPrimary
            pill.backgroundColor = .fdPrimarySoft
            pill.layer.cornerRadius = 11
            pill.clipsToBounds = true
            pill.textAlignment = .center
            pill.contentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
            tagRow.addArrangedSubview(pill)
        }
    }

    @objc private func detailTapped() { onDetailTap?() }
}

// MARK: - Padding Label

private final class PaddingLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
