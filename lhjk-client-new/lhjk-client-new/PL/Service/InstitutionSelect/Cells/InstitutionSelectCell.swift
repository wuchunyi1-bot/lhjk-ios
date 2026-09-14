import UIKit
import SnapKit

/// 机构列表 Cell — 对齐 Figma `5346:15928`
final class InstitutionSelectCell: UITableViewCell {
    static let reuseID = "InstitutionSelectCell"

    private let card = UIView()
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.fdBg.cgColor,
            UIColor.fdBg.withAlphaComponent(0).cgColor,
        ]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "onboarding_hospital_icon"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .medium)
        label.textColor = .fdText
        label.numberOfLines = 1
        return label
    }()

    private let typeBadgeWrap: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
        return v
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 14, weight: .regular)
        label.textColor = .fdPrimary
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .fdFont(ofSize: 16, weight: .regular)
        label.textColor = .fdTabInactive
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = card.bounds
        gradientLayer.cornerRadius = card.layer.cornerRadius
    }

    func configure(item: HospitalSearchVO, isSelected: Bool) {
        nameLabel.text = item.name ?? "服务机构"
        typeBadge.text = HospitalTypeLabel.display(for: item.hospitalType)
        addressLabel.text = item.fullAddress?.nilIfEmpty ?? "地址待补充"
        card.layer.borderWidth = isSelected ? 0.5 : 0
        card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
    }

    private func setupUI() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.layer.insertSublayer(gradientLayer, at: 0)
        contentView.addSubview(card)

        typeBadgeWrap.addSubview(typeBadge)
        card.addSubview(iconView)
        card.addSubview(nameLabel)
        card.addSubview(typeBadgeWrap)
        card.addSubview(addressLabel)

        card.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(14)
            $0.size.equalTo(42)
            $0.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
        typeBadge.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(2)
            $0.leading.trailing.equalToSuperview().inset(4)
        }
        typeBadgeWrap.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.top.equalToSuperview().offset(12)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.top.equalToSuperview().offset(13)
            $0.trailing.lessThanOrEqualTo(typeBadgeWrap.snp.leading).offset(-8)
        }
        addressLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.equalToSuperview().offset(-14)
        }
        typeBadgeWrap.setContentHuggingPriority(.required, for: .horizontal)
        typeBadgeWrap.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
