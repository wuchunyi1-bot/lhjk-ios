import UIKit
import SnapKit
import Kingfisher

/// 购物车卡片 — 对齐 Figma 4380:47316
final class CartItemCell: UITableViewCell {

    static let reuseID = "CartItemCell"

    var onCheckout: (() -> Void)?
    var onDelete: (() -> Void)?

    private enum Design {
        static let priceColor = UIColor(hexString: "#F93838")
        static let productPanelValidBg = UIColor(hexString: "#FFF9F6")
        static let productPanelInvalidBg = UIColor(hexString: "#F9F9F9")
        static let buttonWidth: CGFloat = 77
        static let buttonHeight: CGFloat = 28
        static let imageSize: CGFloat = 84
    }

    private let card = UIView()
    private let institutionIcon = UIImageView()
    private let institutionLabel = UILabel()
    private let productPanel = UIView()
    private let coverView = UIView()
    private let coverImageView = UIImageView()
    private let coverPlaceholder = UILabel()
    private let invalidOverlay = UIView()
    private let invalidBadge = UILabel()
    private let nameLabel = UILabel()
    private let introLabel = UILabel()
    private let priceLabel = UILabel()
    private let deleteButton = UIButton(type: .system)
    private let settleButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16))
        }

        institutionIcon.image = UIImage(named: "order_institution_icon")
        institutionIcon.contentMode = .scaleAspectFit
        institutionIcon.setContentHuggingPriority(.required, for: .horizontal)
        institutionIcon.snp.makeConstraints { $0.size.equalTo(16) }

        institutionLabel.font = .fdFont(ofSize: 18, weight: .medium)
        institutionLabel.textColor = .fdText
        institutionLabel.lineBreakMode = .byTruncatingTail

        let institutionRow = UIStackView(arrangedSubviews: [institutionIcon, institutionLabel])
        institutionRow.axis = .horizontal
        institutionRow.spacing = 6
        institutionRow.alignment = .center
        card.addSubview(institutionRow)
        institutionRow.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualToSuperview().offset(-12)
        }

        productPanel.layer.cornerRadius = 12
        productPanel.clipsToBounds = true
        card.addSubview(productPanel)
        productPanel.snp.makeConstraints {
            $0.top.equalTo(institutionRow.snp.bottom).offset(11)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(108)
        }

        coverView.backgroundColor = .fdProductImageBg
        coverView.layer.cornerRadius = 12
        coverView.clipsToBounds = true
        productPanel.addSubview(coverView)
        coverView.snp.makeConstraints {
            $0.leading.top.equalToSuperview().offset(12)
            $0.size.equalTo(Design.imageSize)
        }

        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverView.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        coverPlaceholder.text = "套餐"
        coverPlaceholder.font = .fdFont(ofSize: 12, weight: .medium)
        coverPlaceholder.textColor = .fdMuted
        coverPlaceholder.textAlignment = .center
        coverView.addSubview(coverPlaceholder)
        coverPlaceholder.snp.makeConstraints { $0.center.equalToSuperview() }

        invalidOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        invalidOverlay.isHidden = true
        coverView.addSubview(invalidOverlay)
        invalidOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        let invalidPill = UIView()
        invalidPill.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        invalidPill.layer.cornerRadius = 14
        invalidPill.clipsToBounds = true
        invalidOverlay.addSubview(invalidPill)
        invalidPill.snp.makeConstraints { $0.center.equalToSuperview() }

        invalidBadge.text = "已失效"
        invalidBadge.font = .fdFont(ofSize: 12, weight: .regular)
        invalidBadge.textColor = .white
        invalidBadge.textAlignment = .center
        invalidPill.addSubview(invalidBadge)
        invalidBadge.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12))
        }

        nameLabel.font = .fdFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .fdText
        nameLabel.numberOfLines = 2

        introLabel.font = .fdFont(ofSize: 16, weight: .regular)
        introLabel.textColor = .fdTabInactive
        introLabel.numberOfLines = 1
        introLabel.lineBreakMode = .byTruncatingTail

        productPanel.addSubview(nameLabel)
        productPanel.addSubview(introLabel)
        productPanel.addSubview(priceLabel)

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalTo(coverView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-12)
        }
        introLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(nameLabel)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.bottom.equalToSuperview().offset(-12)
        }

        styleActionButton(
            deleteButton,
            title: "删除",
            filled: false,
            active: true
        )
        deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)

        styleActionButton(
            settleButton,
            title: "去结算",
            filled: true,
            active: true
        )
        settleButton.addTarget(self, action: #selector(tapSettle), for: .touchUpInside)

        settleButton.snp.makeConstraints {
            $0.width.equalTo(Design.buttonWidth)
            $0.height.equalTo(Design.buttonHeight)
        }
        deleteButton.snp.makeConstraints {
            $0.width.equalTo(Design.buttonWidth)
            $0.height.equalTo(Design.buttonHeight)
        }

        let spacer = UIView()
        let actions = UIStackView(arrangedSubviews: [spacer, deleteButton, settleButton])
        actions.axis = .horizontal
        actions.spacing = 12
        actions.alignment = .center
        card.addSubview(actions)
        actions.snp.makeConstraints {
            $0.top.equalTo(productPanel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    private func styleActionButton(
        _ button: UIButton,
        title: String,
        filled: Bool,
        active: Bool
    ) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        button.layer.cornerRadius = Design.buttonHeight / 2
        button.clipsToBounds = true
        button.contentEdgeInsets = .zero

        if filled {
            button.backgroundColor = active ? .fdPrimary : .fdMuted
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
            button.layer.borderColor = nil
        } else if active {
            button.backgroundColor = .clear
            button.setTitleColor(.fdPrimary, for: .normal)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor.fdPrimary.cgColor
        } else {
            button.backgroundColor = .clear
            button.setTitleColor(.fdMuted, for: .normal)
            button.layer.borderWidth = 0.5
            button.layer.borderColor = UIColor.fdMuted.cgColor
        }
    }

    func configure(_ line: CartLineDisplay) {
        institutionLabel.text = line.displayInstitutionName
        nameLabel.text = line.name
        introLabel.text = line.subtitle
        introLabel.isHidden = line.subtitle.isEmpty

        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        if let urlString = line.imageUrl, let url = URL(string: urlString) {
            coverPlaceholder.isHidden = true
            coverImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            coverPlaceholder.isHidden = false
        }

        let invalid = line.isInvalid
        productPanel.backgroundColor = invalid
            ? Design.productPanelInvalidBg
            : Design.productPanelValidBg
        invalidOverlay.isHidden = !invalid
        settleButton.isHidden = invalid

        priceLabel.attributedText = Self.priceAttributed(
            from: line.linePriceText,
            active: !invalid
        )

        nameLabel.textColor = .fdText
        introLabel.textColor = .fdTabInactive
        styleActionButton(deleteButton, title: "删除", filled: false, active: !invalid)
    }

    private static func priceAttributed(from raw: String, active: Bool) -> NSAttributedString {
        let digits = raw
            .replacingOccurrences(of: "¥", with: "")
            .trimmingCharacters(in: .whitespaces)
        let number = digits.filter { $0.isNumber || $0 == "," || $0 == "." }
        let color: UIColor = active ? Design.priceColor : .fdText
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥ ",
            attributes: [
                .font: UIFont.fdFont(ofSize: 14, weight: .medium),
                .foregroundColor: color,
            ]
        ))
        result.append(NSAttributedString(
            string: number.isEmpty ? digits : number,
            attributes: [
                .font: UIFont.fdFont(ofSize: 18, weight: .medium),
                .foregroundColor: color,
            ]
        ))
        return result
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        onCheckout = nil
        onDelete = nil
        invalidOverlay.isHidden = true
        settleButton.isHidden = false
        productPanel.backgroundColor = Design.productPanelValidBg
    }

    @objc private func tapSettle() { onCheckout?() }
    @objc private func tapDelete() { onDelete?() }
}
