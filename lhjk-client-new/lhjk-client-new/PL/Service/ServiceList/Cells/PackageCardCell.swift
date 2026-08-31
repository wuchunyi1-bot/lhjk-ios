import UIKit
import SnapKit
import Kingfisher

/// 套餐列表卡片 — Figma 3760:10476（249×107 基准 + `mall_item_bg` 等比缩放）
final class PackageCardCell: UITableViewCell {
    static let reuseID = "PackageCardCell"

    private enum Design {
        static let cardWidth: CGFloat = 249
        static let cardHeight: CGFloat = 107
        static let rowSpacing: CGFloat = 14
        static let cardLeading: CGFloat = 10
        static let cardTrailing: CGFloat = 16

        static let coverSize: CGFloat = 83
        static let coverInset: CGFloat = 11.5
        static let coverCornerRadius: CGFloat = 10
        static let cardCornerRadius: CGFloat = 12

        static let textLeadingFromCover: CGFloat = 10
        static let nameTop: CGFloat = 11.5
        static let nameToSubtitle: CGFloat = 6
        static let priceBottom: CGFloat = 11

        static let nameFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 12
        static let badgeFontSize: CGFloat = 10
        static let priceSymbolFontSize: CGFloat = 12
        static let priceValueFontSize: CGFloat = 14
        static let priceSuffixFontSize: CGFloat = 10
    }

    static var cardHorizontalInsets: CGFloat { Design.cardLeading + Design.cardTrailing }
    static var cardHeight: CGFloat { Design.cardHeight }

    static func scaledCardHeight(forCardWidth width: CGFloat) -> CGFloat {
        guard width > 0 else { return Design.cardHeight }
        return width * Design.cardHeight / Design.cardWidth
    }

    static func rowHeight(forCardWidth width: CGFloat) -> CGFloat {
        scaledCardHeight(forCardWidth: width) + Design.rowSpacing
    }

    private var packageId: String?
    private var hospitalId: String?
    private var categoryServiceId: String?
    private var lastPriceText: String?
    private var lastBadge: String?
    private var lastLayoutScale: CGFloat = 0
    private var lastAppliedShowsBadge = false

    private let cardView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let bgImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "mall_item_bg"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.image = UIImage(named: "pkg_card_placeholder")
        return iv
    }()

    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let badgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let badgeLabel = UILabel()
    private let priceLabel = UILabel()

    private var cardHeightConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .white
        contentView.backgroundColor = .white
        contentView.clipsToBounds = true
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyProportionalLayoutIfNeeded()
    }

    private func setupUI() {
        nameLabel.textColor = UIColor(hexString: "#1F2430")
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.textColor = UIColor(hexString: "#6D7381")
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail

        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center

        contentView.addSubview(cardView)
        cardView.addSubview(bgImageView)
        cardView.addSubview(coverImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        cardView.addSubview(priceLabel)

        bgImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        cardView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(Design.cardLeading)
            make.trailing.equalToSuperview().offset(-Design.cardTrailing)
            cardHeightConstraint = make.height.equalTo(Design.cardHeight).constraint
        }

        coverImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(Design.coverInset)
            make.size.equalTo(Design.coverSize)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(Design.nameToSubtitle)
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-8)
        }

        priceLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-Design.priceBottom)
            make.trailing.lessThanOrEqualToSuperview().offset(-8)
        }
    }

    private func applyProportionalLayoutIfNeeded() {
        let cardWidth = contentView.bounds.width - Self.cardHorizontalInsets
        guard cardWidth > 0 else { return }
        let scale = cardWidth / Design.cardWidth
        let scaleChanged = abs(scale - lastLayoutScale) > 0.01
        if scaleChanged {
            lastLayoutScale = scale
            cardHeightConstraint?.update(offset: Design.cardHeight * scale)
            cardView.layer.cornerRadius = Design.cardCornerRadius * scale
            bgImageView.layer.cornerRadius = Design.cardCornerRadius * scale
            coverImageView.layer.cornerRadius = Design.coverCornerRadius * scale

            nameLabel.font = .fdFont(ofSize: Design.nameFontSize * scale, weight: .medium)
            subtitleLabel.font = .fdFont(ofSize: Design.subtitleFontSize * scale, weight: .regular)
            badgeLabel.font = .fdFont(ofSize: Design.badgeFontSize * scale, weight: .bold)

            if let price = lastPriceText {
                priceLabel.attributedText = Self.priceAttributed(from: price, scale: scale)
            }
        }

        let showsBadge = !badgeView.isHidden
        if scaleChanged || showsBadge != lastAppliedShowsBadge {
            lastAppliedShowsBadge = showsBadge
            applyContentConstraints(scale: scale, showsBadge: showsBadge)
        }
    }

    private func applyContentConstraints(scale: CGFloat, showsBadge: Bool) {

        coverImageView.snp.remakeConstraints { make in
            make.top.leading.equalToSuperview().offset(Design.coverInset * scale)
            make.size.equalTo(Design.coverSize * scale)
        }

        badgeView.snp.remakeConstraints { make in
            if showsBadge {
                make.top.equalToSuperview().offset(Design.coverInset * scale)
                make.trailing.equalToSuperview().offset(-8 * scale)
                make.height.equalTo(15 * scale)
                make.width.greaterThanOrEqualTo(26 * scale)
            } else {
                make.top.trailing.equalToSuperview()
                make.width.height.equalTo(0)
            }
        }

        badgeLabel.isHidden = !showsBadge
        if showsBadge {
            badgeLabel.snp.remakeConstraints {
                $0.edges.equalToSuperview().inset(
                    UIEdgeInsets(top: 0, left: 3 * scale, bottom: 0, right: 3 * scale)
                )
            }
        } else {
            badgeLabel.snp.remakeConstraints { $0.edges.equalToSuperview() }
        }

        nameLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Design.nameTop * scale)
            make.leading.equalTo(coverImageView.snp.trailing).offset(Design.textLeadingFromCover * scale)
            if showsBadge {
                make.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-4 * scale)
            } else {
                make.trailing.lessThanOrEqualToSuperview().offset(-8 * scale)
            }
        }

        subtitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(Design.nameToSubtitle * scale)
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-8 * scale)
        }

        priceLabel.snp.remakeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.bottom.equalToSuperview().offset(-Design.priceBottom * scale)
            make.trailing.lessThanOrEqualToSuperview().offset(-8 * scale)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        packageId = nil
        hospitalId = nil
        categoryServiceId = nil
        lastPriceText = nil
        lastBadge = nil
        lastLayoutScale = 0
        lastAppliedShowsBadge = false
        badgeView.isHidden = true
        badgeLabel.isHidden = true
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = UIImage(named: "pkg_card_placeholder")
    }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        packageId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
        nameLabel.text = item.name
        subtitleLabel.text = item.subtitle.isEmpty ? "健康管理服务套餐" : item.subtitle
        lastPriceText = item.price
        priceLabel.attributedText = Self.priceAttributed(from: item.price, scale: lastLayoutScale > 0 ? lastLayoutScale : 1)
        applyBadge(item.badge)

        if let rawUrl = item.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawUrl.isEmpty, let url = URL(string: rawUrl) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "pkg_card_placeholder"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            coverImageView.image = UIImage(named: "pkg_card_placeholder")
        }

        setNeedsLayout()
    }

    func configure(_ p: SvcPkg, accent: UIColor) {
        packageId = p.id
        hospitalId = nil
        categoryServiceId = nil
        nameLabel.text = p.name
        subtitleLabel.text = p.subtitle
        lastPriceText = p.price
        priceLabel.attributedText = Self.priceAttributed(from: p.price, scale: lastLayoutScale > 0 ? lastLayoutScale : 1)
        applyBadge(p.tag.isEmpty ? nil : p.tag)
        coverImageView.image = UIImage(named: "pkg_card_placeholder")
        setNeedsLayout()
    }

    private func applyBadge(_ raw: String?) {
        guard let badge = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !badge.isEmpty, badge != "无" else {
            lastBadge = nil
            badgeView.isHidden = true
            badgeLabel.isHidden = true
            return
        }
        lastBadge = badge
        badgeView.isHidden = false
        badgeLabel.isHidden = false
        badgeLabel.text = badge

        switch badge {
        case "热销":
            badgeView.backgroundColor = UIColor(hexString: "#DF0340")
        case "推荐":
            badgeView.backgroundColor = UIColor(hexString: "#FF7A50")
        default:
            badgeView.backgroundColor = UIColor(hexString: "#FF7A50")
        }
    }

    private static func priceAttributed(from raw: String, scale: CGFloat) -> NSAttributedString {
        let digits = raw.filter { $0.isNumber || $0 == "," || $0 == "." }
        let number = digits.isEmpty ? raw : digits
        let priceColor = UIColor(hexString: "#F93838")
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: Design.priceSymbolFontSize * scale, weight: .medium),
                .foregroundColor: priceColor,
            ]
        ))
        result.append(NSAttributedString(
            string: "\(number)",
            attributes: [
                .font: UIFont.fdFont(ofSize: Design.priceValueFontSize * scale, weight: .medium),
                .foregroundColor: priceColor,
            ]
        ))
        result.append(NSAttributedString(
            string: " 元起",
            attributes: [
                .font: UIFont.fdFont(ofSize: Design.priceSuffixFontSize * scale, weight: .regular),
                .foregroundColor: priceColor,
            ]
        ))
        return result
    }
}
