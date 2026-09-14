import UIKit
import SnapKit
import Kingfisher

/// 业务经理列表 Cell — 对齐 Figma `5346:16364`
final class ManagerSelectCell: UITableViewCell {
    static let reuseID = "ManagerSelectCell"

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

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.backgroundColor = .fdPrimarySoft
        return iv
    }()

    private let avatarLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 18, weight: .medium)
        l.textColor = .white
        l.textAlignment = .center
        l.backgroundColor = .fdPrimary
        l.layer.cornerRadius = 20
        l.clipsToBounds = true
        return l
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 16, weight: .medium)
        l.textColor = .fdText
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = .fdSubtext
        return l
    }()

    private let codeBadgeWrap: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 4
        v.layer.borderWidth = 0.5
        v.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
        return v
    }()

    private let codeBadge: UILabel = {
        let l = UILabel()
        l.font = .fdFont(ofSize: 14, weight: .regular)
        l.textColor = .fdPrimary
        l.textAlignment = .right
        return l
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

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil
    }

    func configure(item: DoctorVo, isSelected: Bool) {
        let name = item.displayName
        avatarLabel.text = String(name.prefix(1))
        nameLabel.text = name

        let title = item.displayTitle.isEmpty ? "业务经理" : item.displayTitle
        let phone = item.maskedMobile
        if phone.isEmpty {
            metaLabel.text = title
        } else {
            metaLabel.text = "\(title)｜\(phone)"
        }

        let code = item.displayCode
        codeBadge.text = code
        codeBadgeWrap.isHidden = code.isEmpty

        let urlString = item.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let url = URL(string: urlString), !urlString.isEmpty {
            avatarLabel.isHidden = true
            avatarImageView.isHidden = false
            avatarImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        } else {
            avatarImageView.isHidden = true
            avatarLabel.isHidden = false
        }

        card.layer.borderWidth = isSelected ? 0.5 : 0
        card.layer.borderColor = UIColor.fdPrimary.withAlphaComponent(0.5).cgColor
    }

    private func setupUI() {
        card.backgroundColor = .fdSurface
        card.layer.cornerRadius = 12
        card.clipsToBounds = true
        card.layer.insertSublayer(gradientLayer, at: 0)
        contentView.addSubview(card)

        codeBadgeWrap.addSubview(codeBadge)
        card.addSubview(avatarLabel)
        card.addSubview(avatarImageView)
        card.addSubview(nameLabel)
        card.addSubview(metaLabel)
        card.addSubview(codeBadgeWrap)

        card.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(68)
        }
        avatarLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalTo(avatarLabel)
        }
        codeBadge.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(2)
            make.leading.trailing.equalToSuperview().inset(4)
        }
        codeBadgeWrap.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.top.equalToSuperview().offset(12)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarLabel.snp.trailing).offset(13)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(codeBadgeWrap.snp.leading).offset(-8)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.trailing.equalToSuperview().inset(12)
        }
        codeBadgeWrap.setContentHuggingPriority(.required, for: .horizontal)
        codeBadgeWrap.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
