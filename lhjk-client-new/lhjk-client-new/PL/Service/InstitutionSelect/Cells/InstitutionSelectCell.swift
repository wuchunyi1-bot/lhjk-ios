import UIKit
import SnapKit

/// 机构列表 Cell — 对齐 funde `.institution-item`
final class InstitutionSelectCell: UITableViewCell {
    static let reuseID = "InstitutionSelectCell"

    private let iconBox: UIView = {
        let v = UIView()
        v.backgroundColor = .fdPrimarySoft
        v.layer.cornerRadius = 10
        return v
    }()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cross.case.fill"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .fdBodyBold
        label.textColor = .fdText
        label.numberOfLines = 2
        return label
    }()

    private let typeBadge: UILabel = {
        let label = UILabel()
        label.font = .fdMicroSemibold
        label.textColor = .fdPrimary
        label.backgroundColor = .fdPrimarySoft
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .fdCaption
        label.textColor = .fdSubtext
        label.numberOfLines = 2
        return label
    }()

    private let checkView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let card = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: HospitalSearchVO, isSelected: Bool) {
        nameLabel.text = item.name ?? "服务机构"
        typeBadge.text = " \(HospitalTypeLabel.display(for: item.hospitalType)) "
        addressLabel.text = item.fullAddress?.nilIfEmpty ?? "地址待补充"
        checkView.isHidden = !isSelected
        card.layer.borderWidth = isSelected ? 1.5 : 1
        card.layer.borderColor = (isSelected ? UIColor.fdPrimary : UIColor.fdBorder).cgColor
        card.backgroundColor = isSelected ? UIColor.fdPrimarySoft.withAlphaComponent(0.35) : .fdSurface
    }

    private func setupUI() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.fdBorder.cgColor
        contentView.addSubview(card)

        iconBox.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, typeBadge])
        titleRow.axis = .horizontal
        titleRow.spacing = 8
        titleRow.alignment = .center
        typeBadge.setContentHuggingPriority(.required, for: .horizontal)
        typeBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleRow, addressLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        card.addSubview(iconBox)
        card.addSubview(textStack)
        card.addSubview(checkView)

        card.snp.makeConstraints {
            $0.top.equalToSuperview().offset(6)
            $0.bottom.equalToSuperview().offset(-6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        iconBox.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(14)
            $0.top.equalToSuperview().inset(14)
            $0.size.equalTo(36)
        }
        textStack.snp.makeConstraints {
            $0.leading.equalTo(iconBox.snp.trailing).offset(12)
            $0.top.equalToSuperview().inset(14)
            $0.bottom.equalToSuperview().inset(14)
            $0.trailing.equalTo(checkView.snp.leading).offset(-8)
        }
        checkView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(14)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(22)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
