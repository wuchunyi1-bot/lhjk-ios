import UIKit
import SnapKit
import Kingfisher

/// 套餐列表卡片 — 对齐 Figma 3760:10430 / 3760:10476（249×107 / 左侧83×83产品图 / 暖粉底+描边）
final class PackageCardCell: UITableViewCell {
    static let reuseID = "PackageCardCell"
    static let cardHeight: CGFloat = 107

    private var packageId: String?
    private var hospitalId: String?
    private var categoryServiceId: String?

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hexString: "#FFF9F8")
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(hexString: "#FFEAE5").cgColor
        view.clipsToBounds = true
        return view
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 10
        iv.clipsToBounds = true
        iv.backgroundColor = .white
        iv.image = UIImage(named: "pkg_card_placeholder")
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hexString: "#1F2430")
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hexString: "#6D7381")
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let footerGradientView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let footerGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hexString: "#FFF1EE").cgColor,
            UIColor(hexString: "#FFF1EE").withAlphaComponent(0).cgColor
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdSurface
        contentView.clipsToBounds = true
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        footerGradientLayer.frame = footerGradientView.bounds
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(footerGradientView)
        footerGradientView.layer.addSublayer(footerGradientLayer)
        cardView.addSubview(coverImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        cardView.addSubview(priceLabel)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-14)
            $0.height.equalTo(Self.cardHeight)
        }

        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(11.5)
            $0.leading.equalToSuperview().offset(11.5)
            $0.size.equalTo(83)
        }

        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(11.5)
            $0.trailing.equalToSuperview().offset(-8)
            $0.height.equalTo(15)
            $0.width.greaterThanOrEqualTo(26)
        }

        badgeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 3))
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(11.5)
            $0.leading.equalTo(coverImageView.snp.trailing).offset(10)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-4)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().offset(-8)
        }

        footerGradientView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(43)
        }

        priceLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.bottom.equalToSuperview().offset(-11)
            $0.trailing.lessThanOrEqualToSuperview().offset(-8)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        packageId = nil
        hospitalId = nil
        categoryServiceId = nil
        badgeView.isHidden = true
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = UIImage(named: "pkg_card_placeholder")
    }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        packageId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
        nameLabel.text = item.name
        subtitleLabel.text = item.subtitle.isEmpty ? "健康管理服务套餐" : item.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: item.price)
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
    }

    func configure(_ p: SvcPkg, accent: UIColor) {
        packageId = p.id
        hospitalId = nil
        categoryServiceId = nil
        nameLabel.text = p.name
        subtitleLabel.text = p.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: p.price)
        applyBadge(p.tag.isEmpty ? nil : p.tag)
        coverImageView.image = UIImage(named: "pkg_card_placeholder")
    }

    private func applyBadge(_ raw: String?) {
        guard let badge = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !badge.isEmpty, badge != "无" else {
            badgeView.isHidden = true
            nameLabel.snp.remakeConstraints {
                $0.top.equalToSuperview().offset(11.5)
                $0.leading.equalTo(coverImageView.snp.trailing).offset(10)
                $0.trailing.lessThanOrEqualToSuperview().offset(-8)
            }
            return
        }
        badgeView.isHidden = false
        badgeLabel.text = badge

        switch badge {
        case "热销":
            badgeView.backgroundColor = UIColor(hexString: "#DF0340")
        case "推荐":
            badgeView.backgroundColor = UIColor(hexString: "#FF7A50")
        default:
            badgeView.backgroundColor = UIColor(hexString: "#FF7A50")
        }

        nameLabel.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(11.5)
            $0.leading.equalTo(coverImageView.snp.trailing).offset(10)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-4)
        }
    }

    private static func priceAttributed(from raw: String) -> NSAttributedString {
        let digits = raw.filter { $0.isNumber || $0 == "," || $0 == "." }
        let number = digits.isEmpty ? raw : digits
        let priceColor = UIColor(hexString: "#F93838")
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: 14, weight: .medium),
                .foregroundColor: priceColor,
            ]
        ))
        result.append(NSAttributedString(
            string: "\(number)",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .medium),
                .foregroundColor: priceColor,
            ]
        ))
        result.append(NSAttributedString(
            string: " 元起",
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .regular),
                .foregroundColor: priceColor,
            ]
        ))
        return result
    }
}
