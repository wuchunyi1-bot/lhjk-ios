import UIKit
import SnapKit

/// 套餐列表卡片 — 对齐 Figma 3021:2175（228×106 / 暖粉底+描边）
final class PackageCardCell: UITableViewCell {
    static let reuseID = "PackageCardCell"
    static let cardHeight: CGFloat = 106

    private var packageId: String?
    private var hospitalId: String?
    private var categoryServiceId: String?

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .fdBg
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.fdPrimaryEdge.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 14, weight: .medium)
        label.textColor = .fdText
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 12, weight: .regular)
        label.textColor = .fdSubtext
        label.numberOfLines = 1
        return label
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let badgeIcon: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 10, weight: .medium)
        return label
    }()

    private let priceLabel = UILabel()

    private lazy var detailButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("查看详情", for: .normal)
        btn.titleLabel?.font = .fdFont(ofSize: 12, weight: .medium)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .fdPrimary
        btn.layer.cornerRadius = 13
        btn.addTarget(self, action: #selector(tap), for: .touchUpInside)
        return btn
    }()

    private let footerGradient: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.fdPrimarySoft.withAlphaComponent(0.7)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .fdSurface
        contentView.clipsToBounds = true
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(footerGradient)
        cardView.addSubview(nameLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(badgeView)
        badgeView.addSubview(badgeIcon)
        badgeView.addSubview(badgeLabel)
        cardView.addSubview(priceLabel)
        cardView.addSubview(detailButton)

        cardView.snp.makeConstraints {
            $0.top.equalToSuperview()
            // 右侧列表卡片必须完整留在右栏内，避免越过左侧类目栏
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-14)
            $0.height.equalTo(Self.cardHeight)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.equalToSuperview().offset(12)
            $0.trailing.lessThanOrEqualTo(badgeView.snp.leading).offset(-6)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(12)
        }
        badgeView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(20)
        }
        badgeIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(10)
        }
        badgeLabel.snp.makeConstraints {
            $0.leading.equalTo(badgeIcon.snp.trailing).offset(2)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalToSuperview()
        }
        footerGradient.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(42)
        }
        priceLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.bottom.equalToSuperview().offset(-14)
            $0.trailing.lessThanOrEqualTo(detailButton.snp.leading).offset(-8)
        }
        detailButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-12)
            $0.width.equalTo(72)
            $0.height.equalTo(26)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        packageId = nil
        hospitalId = nil
        categoryServiceId = nil
        badgeView.isHidden = true
    }

    func configure(_ item: HealthPackageItem, categoryServiceId: String? = nil) {
        packageId = item.id
        hospitalId = item.hospitalId
        self.categoryServiceId = categoryServiceId
        nameLabel.text = item.name
        subtitleLabel.text = item.subtitle.isEmpty ? "健康管理服务套餐" : item.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: item.price)
        applyBadge(item.badge)
    }

    func configure(_ p: SvcPkg, accent: UIColor) {
        packageId = p.id
        hospitalId = nil
        categoryServiceId = nil
        nameLabel.text = p.name
        subtitleLabel.text = p.subtitle
        priceLabel.attributedText = Self.priceAttributed(from: p.price)
        applyBadge(p.tag.isEmpty ? nil : p.tag)
    }

    private func applyBadge(_ raw: String?) {
        guard let badge = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !badge.isEmpty, badge != "无" else {
            badgeView.isHidden = true
            return
        }
        badgeView.isHidden = false
        badgeLabel.text = badge

        switch badge {
        case "热销":
            badgeView.backgroundColor = .fdDangerSoft
            badgeLabel.textColor = .fdDanger
            badgeIcon.image = UIImage(systemName: "flame.fill")
            badgeIcon.tintColor = .fdDanger
        case "推荐":
            badgeView.backgroundColor = .fdWarningSoft
            badgeLabel.textColor = .fdPrimary
            badgeIcon.image = UIImage(systemName: "hand.thumbsup.fill")
            badgeIcon.tintColor = .fdPrimary
        default:
            badgeView.backgroundColor = .fdPrimarySoft
            badgeLabel.textColor = .fdPrimary
            badgeIcon.image = UIImage(systemName: "star.fill")
            badgeIcon.tintColor = .fdPrimary
        }
    }

    private static func priceAttributed(from raw: String) -> NSAttributedString {
        let digits = raw.filter { $0.isNumber || $0 == "," || $0 == "." }
        let number = digits.isEmpty ? raw : digits
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "¥",
            attributes: [
                .font: UIFont.fdFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.fdDanger,
            ]
        ))
        result.append(NSAttributedString(
            string: " \(number)",
            attributes: [
                .font: UIFont.fdFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.fdDanger,
            ]
        ))
        result.append(NSAttributedString(
            string: " 元起",
            attributes: [
                .font: UIFont.fdFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.fdDanger,
            ]
        ))
        return result
    }

    @objc private func tap() {
        guard let id = packageId else { return }
        Router.shared.push(
            "/services/pkg",
            params: ServiceRoutes.packageDetailParams(
                packageId: id,
                hospitalId: hospitalId,
                categoryServiceId: categoryServiceId
            )
        )
    }
}
