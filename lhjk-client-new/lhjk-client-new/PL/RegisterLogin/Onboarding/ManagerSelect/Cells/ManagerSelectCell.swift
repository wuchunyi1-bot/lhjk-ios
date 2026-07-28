import UIKit
import SnapKit

/// 业务经理列表 Cell — 对齐 funde `.manager-item`
final class ManagerSelectCell: UITableViewCell {
    static let reuseID = "ManagerSelectCell"

    private let card = UIView()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBodyBold
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .fdPrimary
        l.layer.cornerRadius = 20
        l.clipsToBounds = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdBodyBold
        l.textColor = .fdText
        return l
    }()

    private let codeLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdMuted
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdCaption
        l.textColor = .fdSubtext
        return l
    }()

    private let checkView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .fdPrimary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(item: DoctorVo, isSelected: Bool) {
        let name = item.displayName
        avatarLabel.text = String(name.prefix(1))
        nameLabel.text = name
        codeLabel.text = item.displayCode
        codeLabel.isHidden = item.displayCode.isEmpty

        let title = item.displayTitle
        let phone = item.maskedMobile
        let parts = [title, phone].filter { !$0.isEmpty }
        metaLabel.text = parts.joined(separator: " · ")
        metaLabel.isHidden = parts.isEmpty

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

        let head = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        head.axis = .horizontal
        head.spacing = 8
        head.alignment = .center

        let body = UIStackView(arrangedSubviews: [head, metaLabel])
        body.axis = .vertical
        body.spacing = 4

        card.addSubview(avatarLabel)
        card.addSubview(body)
        card.addSubview(checkView)

        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        avatarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        body.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(12)
            make.trailing.equalTo(checkView.snp.leading).offset(-8)
            make.top.bottom.equalToSuperview().inset(14)
        }
        checkView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }
}
